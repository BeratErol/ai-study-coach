import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/study_plan.dart';
import '../../providers/study_plan_provider.dart';
import '../../services/gelisimim_service.dart';
import 'gunluk_rapor_sheet.dart';

class GecmisiGorCalendar extends ConsumerStatefulWidget {
  const GecmisiGorCalendar({super.key});

  @override
  ConsumerState<GecmisiGorCalendar> createState() => _GecmisiGorCalendarState();
}

class _GecmisiGorCalendarState extends ConsumerState<GecmisiGorCalendar> {
  final _service = GelisimimService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<String> _activeDays = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMonth(_focusedDay);
  }

  Future<void> _loadMonth(DateTime month) async {
    setState(() => _loading = true);
    try {
      final days =
          await _service.getCalendarActiveDays(month.year, month.month);
      if (mounted) {
        setState(() {
          _activeDays = days.toSet();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isActive(DateTime day) {
    final key =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return _activeDays.contains(key);
  }

  String _toDateStr(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  const Text('📅',
                      style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Çalışma Takviminiz',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close_rounded,
                        color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const Divider(height: 16),
            // Calendar
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                child: Column(
                  children: [
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: LinearProgressIndicator(
                            color: Color(0xFF4F46E5)),
                      ),
                    TableCalendar(
                      locale: 'tr_TR',
                      firstDay: DateTime(2024),
                      lastDay: DateTime(2030),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                        _openDailyReport(selectedDay);
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                        _loadMonth(focusedDay);
                      },
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: const Color(0xFF4F46E5)
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: const TextStyle(
                            color: Color(0xFF4F46E5),
                            fontWeight: FontWeight.w700),
                        selectedDecoration: const BoxDecoration(
                          color: Color(0xFF4F46E5),
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                        markerDecoration: const BoxDecoration(
                          color: Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                        markersMaxCount: 1,
                        outsideDaysVisible: false,
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (ctx, day, _) {
                          if (_isActive(day)) {
                            return Positioned(
                              bottom: 4,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF59E0B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Bir güne tıklayarak detayları görüntüleyin',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDailyReport(DateTime day) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final selectedDate = DateTime(day.year, day.month, day.day);
    final isPast = selectedDate.isBefore(todayDate);

    // For today and future days: try to show the study plan
    if (!isPast) {
      final plan = ref.read(studyPlanProvider).value;
      if (plan != null) {
        StudyDay? studyDay;
        for (final d in plan) {
          if (d.date.year == day.year &&
              d.date.month == day.month &&
              d.date.day == day.day) {
            studyDay = d;
            break;
          }
        }
        if (studyDay != null && studyDay.isOffDay) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useRootNavigator: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _OffDaySheet(day: studyDay!.date),
          );
          return;
        }
        if (studyDay != null && studyDay.blocks.isNotEmpty) {
          final questionsDate =
              selectedDate == todayDate ? _toDateStr(day) : null;
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useRootNavigator: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _GunlukPlanSheet(
              day: studyDay!,
              questionsDate: questionsDate,
            ),
          );
          return;
        }
      }
    }

    // For past days in the current weekly plan: show plan + session summary
    if (isPast) {
      final plan = ref.read(studyPlanProvider).value;
      if (plan != null) {
        StudyDay? studyDay;
        for (final d in plan) {
          if (d.date.year == day.year &&
              d.date.month == day.month &&
              d.date.day == day.day) {
            studyDay = d;
            break;
          }
        }
        if (studyDay != null && studyDay.isOffDay) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useRootNavigator: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _OffDaySheet(day: studyDay!.date),
          );
          return;
        }
        if (studyDay != null && studyDay.blocks.isNotEmpty) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useRootNavigator: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _GunlukPlanSheet(
              day: studyDay!,
              questionsDate: _toDateStr(day),
              isPastDay: true,
            ),
          );
          return;
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GunlukRaporSheet(date: _toDateStr(day)),
    );
  }
}

// ─── Planned day sheet (future days) ─────────────────────────────────────────

class _GunlukPlanSheet extends StatelessWidget {
  final StudyDay day;
  // questionsDate: fetches question data below the plan (today or past day)
  final String? questionsDate;
  // isPastDay: shows completed/missed session summary instead of just questions
  final bool isPastDay;

  const _GunlukPlanSheet({
    required this.day,
    this.questionsDate,
    this.isPastDay = false,
  });

  @override
  Widget build(BuildContext context) {
    final dt = day.date;
    const months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final dateLabel = '${dt.day} ${months[dt.month]} ${dt.year}';
    final isToday = questionsDate != null && !isPastDay;

    return DraggableScrollableSheet(
      initialChildSize: (isToday || isPastDay) ? 0.80 : 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$dateLabel — ${isToday ? 'Bugünün Planı' : isPastDay ? 'Geçmiş Gün' : 'Çalışma Planı'}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close_rounded,
                        color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  // Plan blocks
                  ...List.generate(day.blocks.length, (i) {
                    final block = day.blocks[i];
                    return Column(
                      children: [
                        _PlanBlockRow(block: block),
                        if (i < day.blocks.length - 1)
                          const Divider(height: 20, indent: 56),
                      ],
                    );
                  }),
                  // Today's question data
                  if (isToday) ...[
                    const SizedBox(height: 24),
                    _TodayQuestionsSection(date: questionsDate!),
                  ],
                  // Past day: plan comparison + questions
                  if (isPastDay && questionsDate != null) ...[
                    const SizedBox(height: 24),
                    _PastDayReportSection(
                      date: questionsDate!,
                      blocks: day.blocks,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Shows today's saved question counts fetched from backend
class _TodayQuestionsSection extends StatefulWidget {
  final String date;
  const _TodayQuestionsSection({required this.date});

  @override
  State<_TodayQuestionsSection> createState() => _TodayQuestionsSectionState();
}

class _TodayQuestionsSectionState extends State<_TodayQuestionsSection> {
  final _service = GelisimimService();
  late Future<DailyReport> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getDailyReport(widget.date);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DailyReport>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final report = snap.data;
        if (report == null || report.questions.isEmpty) {
          return const SizedBox.shrink();
        }
        final total =
            report.questions.fold<int>(0, (s, q) => s + q.count);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('📝', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                const Text(
                  'Bugün Çözülen Sorular',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
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
            ...report.questions.map(
              (q) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        q.subjectName,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
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
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PlanBlockRow extends StatelessWidget {
  final StudyBlock block;
  const _PlanBlockRow({required this.block});

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _typeLabel(String type) {
    switch (type) {
      case 'konu_anlatimi': return 'Konu Anlatımı';
      case 'soru_cozumu':   return 'Soru Çözümü';
      case 'deneme':        return 'Deneme Sınavı';
      case 'tekrar':        return 'Tekrar';
      case 'mola':          return 'Mola';
      default:              return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: block.isMola
                ? const Color(0xFFECFDF5)
                : const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(block.emoji,
                style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                block.isMola ? 'Mola ☕' : block.subjectName,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                '${_fmt(block.startTime)} – ${_fmt(block.endTime)}  •  ${block.durationMinutes} dk',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        if (!block.isMola)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _typeLabel(block.taskType),
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF4F46E5),
                  fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

// ─── Past-day report section ─────────────────────────────────────────────────

class _PastDayReportSection extends StatefulWidget {
  final String date;
  final List<StudyBlock> blocks;

  const _PastDayReportSection({required this.date, required this.blocks});

  @override
  State<_PastDayReportSection> createState() => _PastDayReportSectionState();
}

class _PastDayReportSectionState extends State<_PastDayReportSection> {
  final _service = GelisimimService();
  late Future<DailyReport> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getDailyReport(widget.date);
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final studyBlocks = widget.blocks.where((b) => !b.isMola).toList();

    return FutureBuilder<DailyReport>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final report = snap.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),

            // ── Planlanan oturumlar ──
            const Row(
              children: [
                Text('📋', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text(
                  'Planlanan Oturumlar',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (studyBlocks.isEmpty)
              Text('Bu gün için planlanan ders yok.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500))
            else
              ...studyBlocks.map((b) {
                final completed = report != null &&
                    report.tasks.completed > studyBlocks.indexOf(b);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: completed
                              ? Colors.green
                              : Colors.grey.shade200,
                          border: Border.all(
                            color: completed
                                ? Colors.green
                                : Colors.grey.shade400,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          completed ? Icons.check : Icons.close,
                          size: 14,
                          color: completed
                              ? Colors.white
                              : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          b.subjectName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : null,
                            color: completed
                                ? Colors.grey.shade500
                                : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      Text(
                        '${_fmt(b.startTime)} – ${_fmt(b.endTime)}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                );
              }),

            // ── Soru çözümü ──
            if (report != null && report.questions.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('📝', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  const Text(
                    'Çözülen Sorular',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Toplam: ${report.questions.fold(0, (s, q) => s + q.count)} soru',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4F46E5),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...report.questions.map(
                (q) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
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
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ─── Off-day sheet ────────────────────────────────────────────────────────────

class _OffDaySheet extends StatelessWidget {
  final DateTime day;
  const _OffDaySheet({required this.day});

  @override
  Widget build(BuildContext context) {
    const months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final dateLabel = '${day.day} ${months[day.month]} ${day.year}';

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.6,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$dateLabel — Tatil Günü',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close_rounded,
                        color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(32),
                children: [
                  const Text('🌴', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 52)),
                  const SizedBox(height: 16),
                  Text(
                    'Bu gün için tatil planlandı.\nDinlen, enerjini topla!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
