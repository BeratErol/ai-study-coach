import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/gelisimim_service.dart';
import '../../services/token_service.dart';
import '../../models/study_plan.dart';
import '../../providers/gelisimim_provider.dart';

class GunlukRaporSheet extends ConsumerStatefulWidget {
  final String date; // "yyyy-MM-dd"

  const GunlukRaporSheet({super.key, required this.date});

  @override
  ConsumerState<GunlukRaporSheet> createState() => _GunlukRaporSheetState();
}

class _GunlukRaporSheetState extends ConsumerState<GunlukRaporSheet> {
  final _service = GelisimimService();
  late Future<_DayData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadDayData();
  }

  Future<_DayData> _loadDayData() async {
    // Backend raporu
    DailyReport? report;
    try {
      report = await _service.getDailyReport(widget.date);
    } catch (_) {}

    // Local oturum verileri
    final userId = await TokenService.getUserId() ?? 'anonymous';
    final prefs = await SharedPreferences.getInstance();

    // Tamamlanan görev ID'leri (web ile ortak key formatı; legacy fallback).
    final newKey = 'user_${userId}_completed_tasks_${widget.date}';
    final legacyKey = 'completed_tasks_${userId}_${widget.date}';
    Set<String> completedIds = <String>{};
    // Yeni format: JSON list olarak String'te tutulur.
    final rawNew = prefs.getString(newKey);
    if (rawNew != null) {
      try {
        completedIds = (jsonDecode(rawNew) as List).cast<String>().toSet();
      } catch (_) {}
    }
    if (completedIds.isEmpty) {
      completedIds = prefs.getStringList(legacyKey)?.toSet() ?? <String>{};
    }

    // Haftalık planı oku, bu güne ait blokları bul (web ile aynı key formatı).
    final planKey = 'user_${userId}_weekly_plan';
    final planRaw = prefs.getString(planKey);
    List<StudyBlock> dayBlocks = [];
    if (planRaw != null) {
      try {
        final list = jsonDecode(planRaw) as List;
        final plan = list.map((e) => StudyDay.fromJson(e as Map<String, dynamic>)).toList();
        final targetDate = DateTime.tryParse(widget.date);
        if (targetDate != null) {
          final match = plan.where((d) =>
              d.date.year == targetDate.year &&
              d.date.month == targetDate.month &&
              d.date.day == targetDate.day).firstOrNull;
          dayBlocks = match?.blocks.where((b) => !b.isMola).toList() ?? [];
        }
      } catch (_) {}
    }

    // Tamamlanan ders detayları (web getCompletedLessons karşılığı).
    // Yeni program oluştuktan sonra eski plan günleri artık plan'da olmadığı
    // için dayBlocks boş kalır; bu detay kaydı sayesinde o günün tamamlanmış
    // dersleri yine gösterilebilir.
    final lessonsKey = 'user_${userId}_completed_lessons_${widget.date}';
    List<CompletedLessonRecord> completedLessons = [];
    final lessonsRaw = prefs.getString(lessonsKey);
    if (lessonsRaw != null) {
      try {
        completedLessons = (jsonDecode(lessonsRaw) as List)
            .map((e) => CompletedLessonRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    return _DayData(
      report: report,
      completedIds: completedIds,
      dayBlocks: dayBlocks,
      completedLessons: completedLessons,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.70,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_formatDate(widget.date)} — Günlük Rapor',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close_rounded, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Body
            Expanded(
              child: FutureBuilder<_DayData>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snap.data;
                  final report = data?.report;
                  final completedIds = data?.completedIds ?? {};
                  final dayBlocks = data?.dayBlocks ?? [];
                  final completedLessons = data?.completedLessons ?? [];

                  final hasQuestions = report != null && report.questions.isNotEmpty;
                  final hasSessions = dayBlocks.isNotEmpty;
                  // Plan bloğu yoksa (yeni program → eski gün) ama tamamlanan
                  // ders detayı varsa onları göster.
                  final hasLessonsOnly = !hasSessions && completedLessons.isNotEmpty;
                  final hasAnything = hasQuestions || hasSessions || hasLessonsOnly;

                  if (!hasAnything) {
                    return const _EmptyState(
                      message: 'Bu güne ait kayıt bulunamadı.',
                    );
                  }

                  return ListView(
                    controller: controller,
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (hasSessions) ...[
                        _SessionSection(
                          blocks: dayBlocks,
                          completedIds: completedIds,
                        ),
                        if (hasQuestions || hasLessonsOnly) const SizedBox(height: 20),
                      ] else if (hasLessonsOnly) ...[
                        _CompletedLessonsSection(lessons: completedLessons),
                        if (hasQuestions) const SizedBox(height: 20),
                      ],
                      if (hasQuestions)
                        _QuestionSection(questions: report.questions),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    const months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}

class _DayData {
  final DailyReport? report;
  final Set<String> completedIds;
  final List<StudyBlock> dayBlocks;
  final List<CompletedLessonRecord> completedLessons;

  const _DayData({
    required this.report,
    required this.completedIds,
    required this.dayBlocks,
    required this.completedLessons,
  });
}

// ─── Session Section ──────────────────────────────────────────────────────────

class _SessionSection extends StatelessWidget {
  final List<StudyBlock> blocks;
  final Set<String> completedIds;

  const _SessionSection({required this.blocks, required this.completedIds});

  @override
  Widget build(BuildContext context) {
    final completed = blocks.where((b) => completedIds.contains(b.id)).toList();
    final missed = blocks.where((b) => !completedIds.contains(b.id)).toList();
    final totalMins = completed.fold(0, (s, b) => s + b.durationMinutes);
    final pct = blocks.isNotEmpty
        ? (completed.length / blocks.length * 100).round()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('📋', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Text('Çalışma Oturumları',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '%$pct Tamamlandı',
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Özet satırı
        Builder(builder: (context) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SessionStat(
                  icon: '✅',
                  label: 'Tamamlanan',
                  value: '${completed.length}/${blocks.length}'),
              _SessionStat(
                  icon: '⏱️',
                  label: 'Çalışma Süresi',
                  value: _fmtMin(totalMins)),
              _SessionStat(
                  icon: '❌',
                  label: 'Eksik',
                  value: '${missed.length}'),
            ],
          ),
        )),
        const SizedBox(height: 12),
        // Tamamlananlar
        if (completed.isNotEmpty) ...[
          _subsectionLabel('Tamamlanan Oturumlar', const Color(0xFF16A34A)),
          ...completed.map((b) => _BlockRow(block: b, done: true)),
          const SizedBox(height: 8),
        ],
        // Eksikler
        if (missed.isNotEmpty) ...[
          _subsectionLabel('Tamamlanmayan Oturumlar', const Color(0xFFEF4444)),
          ...missed.map((b) => _BlockRow(block: b, done: false)),
        ],
      ],
    );
  }

  Widget _subsectionLabel(String text, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color)),
      );

  String _fmtMin(int m) {
    if (m < 60) return '${m}dk';
    return '${m ~/ 60}s ${m % 60}dk';
  }
}

// Plan bloğu kalmamış eski günler için: tamamlanan ders detaylarını listeler.
class _CompletedLessonsSection extends StatelessWidget {
  final List<CompletedLessonRecord> lessons;
  const _CompletedLessonsSection({required this.lessons});

  String _taskLabel(String type) {
    switch (type) {
      case 'konu_anlatimi': return 'Konu Anlatımı';
      case 'soru_cozumu': return 'Soru Çözümü';
      case 'deneme': return 'Deneme Sınavı';
      case 'tekrar': return 'Tekrar';
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalMins = lessons.fold<int>(0, (s, l) => s + l.durationMinutes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('✅', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Text('Tamamlanan Dersler',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${lessons.length} ders · ${totalMins ~/ 60}s ${totalMins % 60}dk',
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...lessons.map((l) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.topicName != null
                              ? '${l.subjectName} — ${l.topicName}'
                              : l.subjectName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Text(_taskLabel(l.taskType),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${l.durationMinutes} dk',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(height: 2),
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.green, size: 18),
                    ],
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _SessionStat extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _SessionStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }
}

class _BlockRow extends StatelessWidget {
  final StudyBlock block;
  final bool done;
  const _BlockRow({required this.block, required this.done});

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _taskLabel(String type) {
    switch (type) {
      case 'konu_anlatimi': return 'Konu Anlatımı';
      case 'soru_cozumu': return 'Soru Çözümü';
      case 'tekrar': return 'Tekrar';
      case 'deneme': return 'Deneme';
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = done ? const Color(0xFF16A34A) : const Color(0xFFEF4444);
    final bg = done
        ? color.withValues(alpha: 0.12)
        : color.withValues(alpha: 0.10);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(block.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(block.subjectName,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color)),
                Text(_taskLabel(block.taskType),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text(
            '${_fmtTime(block.startTime)} – ${_fmtTime(block.endTime)}',
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Question Section ─────────────────────────────────────────────────────────

class _QuestionSection extends StatelessWidget {
  final List<DailyQuestion> questions;

  const _QuestionSection({required this.questions});

  @override
  Widget build(BuildContext context) {
    final total = questions.fold<int>(0, (s, q) => s + q.count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('📝', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Text('Çözülen Sorular',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Toplam: $total soru',
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...questions.map((q) => _QuestionRow(q: q)),
      ],
    );
  }
}

class _QuestionRow extends StatelessWidget {
  final DailyQuestion q;

  const _QuestionRow({required this.q});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(q.subjectName,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Text(
            '${q.count} soru',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.indigo.shade500),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
