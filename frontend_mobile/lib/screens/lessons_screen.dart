import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_theme.dart';
import '../services/api_service.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final lessonsListProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiService().dio.get('/Lesson');
  return List<Map<String, dynamic>>.from(res.data as List);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class LessonsScreen extends ConsumerWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Derslerim')),
      body: lessonsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              const Text('Dersler yüklenemedi',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(lessonsListProvider),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
        data: (lessons) => lessons.isEmpty
            ? _EmptyLessons(onAdd: () => _showAddSheet(context, ref))
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.invalidate(lessonsListProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md, AppSpacing.md, 100),
                  itemCount: lessons.length,
                  itemBuilder: (ctx, i) {
                    final lesson = lessons[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _LessonCard(
                        lesson: lesson,
                        onTap: () =>
                            ctx.go('/lessons/${lesson['id']}', extra: lesson),
                        onDelete: () async {
                          final ok = await _confirmDelete(ctx, lesson['name']);
                          if (!ok || !ctx.mounted) return;
                          try {
                            await ApiService()
                                .dio
                                .delete('/Lesson/${lesson['id']}');
                            ref.invalidate(lessonsListProvider);
                          } catch (_) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                    content: Text('Ders silinemedi.')),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ders Ekle',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  static Future<bool> _confirmDelete(BuildContext ctx, String name) async {
    return await showDialog<bool>(
          context: ctx,
          builder: (_) => AlertDialog(
            title: const Text('Dersi Sil'),
            content: Text('"$name" dersini silmek istediğinden emin misin?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Vazgeç'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Sil'),
              ),
            ],
          ),
        ) ??
        false;
  }

  static void _showAddSheet(BuildContext ctx, WidgetRef ref) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddLessonSheet(onSaved: () => ref.invalidate(lessonsListProvider)),
    );
  }
}

// ── Lesson Card ───────────────────────────────────────────────────────────────

class _LessonCard extends StatelessWidget {
  final Map<String, dynamic> lesson;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _LessonCard({
    required this.lesson,
    required this.onTap,
    required this.onDelete,
  });

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.primary;
    try { return Color(int.parse(hex.replaceAll('#', '0xFF'))); }
    catch (_) { return AppColors.primary; }
  }

  @override
  Widget build(BuildContext context) {
    final color    = _parseColor(lesson['colorCode'] as String?);
    final topics   = (lesson['topics'] as List?) ?? [];
    final total    = topics.length;
    final done     = topics.where((t) => t['isCompleted'] == true).length;
    final progress = total > 0 ? done / total : 0.0;
    final planned  = lesson['plannedDate'] != null
        ? DateTime.tryParse(lesson['plannedDate'] as String)
        : null;

    return Dismissible(
      key: ValueKey(lesson['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: AppRadius.lg,
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // actual deletion handled in onDelete
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: AppRadius.lg,
            border: Border.all(
              color: color.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: AppRadius.md,
                    ),
                    child: Icon(Icons.menu_book_rounded, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson['name'] as String? ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        Text(
                          '$done / $total konu',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (planned != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 12, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          '${planned.day}.${planned.month}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textHint),
                ],
              ),
              if (total > 0) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: AppRadius.full,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: color.withValues(alpha: 0.12),
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyLessons extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyLessons({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book_outlined,
                size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('Henüz ders eklenmedi',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            'Derslerini ekleyerek konu takibine başla',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Ders Ekle'),
          ),
        ],
      ),
    );
  }
}

// ── Add Lesson Bottom Sheet ───────────────────────────────────────────────────

class _AddLessonSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddLessonSheet({required this.onSaved});

  @override
  State<_AddLessonSheet> createState() => _AddLessonSheetState();
}

class _AddLessonSheetState extends State<_AddLessonSheet> {
  final _nameCtrl = TextEditingController();
  int   _selectedColorIdx = 0;
  DateTime? _plannedDate;
  bool  _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) setState(() => _plannedDate = picked);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ders adı boş olamaz.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final color = AppColors.lessonColors[_selectedColorIdx];
      final hex   = '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
      await ApiService().dio.post('/Lesson', data: {
        'name':        name,
        'colorCode':   hex,
        'plannedDate': _plannedDate?.toUtc().toIso8601String(),
      });
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ders eklenirken hata oluştu.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
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
          const Text('Yeni Ders Ekle',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),

          // Name field
          TextFormField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Ders Adı',
              hintText: 'Örn: Matematik, Türkçe...',
              prefixIcon: Icon(Icons.menu_book_rounded),
            ),
          ),
          const SizedBox(height: 20),

          // Color picker
          const Text('Renk',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: List.generate(AppColors.lessonColors.length, (i) {
              final c = AppColors.lessonColors[i];
              final sel = _selectedColorIdx == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedColorIdx = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: sel
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: sel
                        ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8)]
                        : null,
                  ),
                  child: sel
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 16)
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Planned date
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: Theme.of(context).inputDecorationTheme.fillColor,
                borderRadius: AppRadius.md,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _plannedDate == null
                        ? 'Hedef tarih seç (opsiyonel)'
                        : '${_plannedDate!.day}.${_plannedDate!.month}.${_plannedDate!.year}',
                    style: TextStyle(
                      color: _plannedDate == null
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (_plannedDate != null) ...[
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _plannedDate = null),
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: AppColors.textHint),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Kaydet'),
            ),
          ),
        ],
      ),
    );
  }
}
