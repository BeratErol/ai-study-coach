import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';
import '../services/api_service.dart';
import 'lessons_screen.dart' show lessonsListProvider;

class LessonDetailScreen extends ConsumerStatefulWidget {
  final dynamic lesson;

  const LessonDetailScreen({super.key, required this.lesson});

  @override
  ConsumerState<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends ConsumerState<LessonDetailScreen> {
  late List<dynamic> _topics;
  final _topicCtrl = TextEditingController();
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _topics = List.from(widget.lesson['topics'] ?? []);
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    super.dispose();
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.primary;
    try { return Color(int.parse(hex.replaceAll('#', '0xFF'))); }
    catch (_) { return AppColors.primary; }
  }

  Future<void> _addTopic() async {
    final name = _topicCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _adding = true);
    try {
      final res = await ApiService().dio.post('/Topic', data: {
        'lessonId': widget.lesson['id'],
        'name': name,
      });
      if (res.statusCode == 201) {
        setState(() {
          _topics.add(res.data);
          _topicCtrl.clear();
        });
        ref.invalidate(lessonsListProvider);
      }
    } catch (_) {
      if (mounted) _showSnack('Konu eklenirken hata oluştu.');
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _toggleTopic(int index) async {
    final topic = _topics[index];
    final prev  = topic['isCompleted'] as bool? ?? false;
    setState(() => _topics[index]['isCompleted'] = !prev);
    try {
      await ApiService().dio.put('/Topic/${topic['id']}/toggle');
      ref.invalidate(lessonsListProvider);
    } catch (_) {
      setState(() => _topics[index]['isCompleted'] = prev);
      if (mounted) _showSnack('Güncellenemedi.');
    }
  }

  Future<void> _deleteTopic(int index) async {
    final topic   = _topics[index];
    final removed = _topics.removeAt(index);
    setState(() {});
    try {
      await ApiService().dio.delete('/Topic/${topic['id']}');
      ref.invalidate(lessonsListProvider);
    } catch (_) {
      setState(() => _topics.insert(index, removed));
      if (mounted) _showSnack('Konu silinemedi.');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
      ),
    );
  }

  void _showAddTopicSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight, borderRadius: AppRadius.full),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Konu Ekle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _topicCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Konu adı gir...',
                  prefixIcon: Icon(Icons.bookmark_border_rounded),
                ),
                onFieldSubmitted: (_) {
                  Navigator.pop(context);
                  _addTopic();
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _addTopic();
                  },
                  child: _adding
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Ekle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name  = widget.lesson['name'] as String? ?? 'Ders Detayı';
    final color = _parseColor(widget.lesson['colorCode'] as String?);
    final total = _topics.length;
    final done  = _topics.where((t) => t['isCompleted'] == true).length;
    final progress = total > 0 ? done / total : 0.0;

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Progress header ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.lg,
              ),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: AppRadius.md,
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('$done / $total konu tamamlandı',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: AppRadius.full,
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: Colors.white.withValues(alpha: 0.3),
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Topics section ────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Konular',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                TextButton.icon(
                  onPressed: _showAddTopicSheet,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Konu Ekle'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _topics.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.05),
                      borderRadius: AppRadius.lg,
                      border: Border.all(color: color.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.bookmark_border_rounded,
                            size: 40, color: color.withValues(alpha: 0.5)),
                        const SizedBox(height: 10),
                        const Text('Henüz konu eklenmedi',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        const Text(
                          '"Konu Ekle" butonuyla alt konuları girebilirsin.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _topics.length,
                    itemBuilder: (ctx, i) {
                      final topic     = _topics[i];
                      final completed = topic['isCompleted'] as bool? ?? false;
                      return Dismissible(
                        key: ValueKey(topic['id'] ?? i),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: AppRadius.md,
                          ),
                          child: const Icon(Icons.delete_rounded,
                              color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteTopic(i),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(ctx).cardColor,
                            borderRadius: AppRadius.md,
                            border: Border.all(
                              color: completed
                                  ? AppColors.success.withValues(alpha: 0.3)
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: CheckboxListTile(
                            value: completed,
                            onChanged: (_) => _toggleTopic(i),
                            activeColor: color,
                            checkColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                                borderRadius: AppRadius.md),
                            title: Text(
                              topic['name'] as String? ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                decoration: completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: completed
                                    ? AppColors.textSecondary
                                    : null,
                              ),
                            ),
                            secondary: Icon(
                              completed
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: completed ? AppColors.success : AppColors.textHint,
                              size: 20,
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: AppSpacing.lg),

            // ── Stats ─────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Tamamlanan',
                    value: '$done Konu',
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Kalan',
                    value: '${total - done} Konu',
                    icon: Icons.pending_rounded,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'İlerleme',
                    value: '${(progress * 100).toInt()}%',
                    icon: Icons.trending_up_rounded,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTopicSheet,
        backgroundColor: color,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.md,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: color)),
          Text(title,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
