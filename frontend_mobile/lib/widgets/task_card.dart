import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/study_task.dart';
import '../providers/study_plan_provider.dart';

class TaskCard extends ConsumerWidget {
  final StudyTask task;
  final bool isLocked;
  final bool readOnly;

  const TaskCard({super.key, required this.task, this.isLocked = false, this.readOnly = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedIds = ref.watch(completedTaskIdsProvider);
    final topicMap = ref.watch(topicAssignmentsProvider);
    final isCompleted = completedIds.contains(task.id);
    final isMola = task.isMola;
    final topicName = task.topicName ?? topicMap[task.id];

    final cardBg = isLocked
        ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
        : isMola
            ? const Color(0xFF10B981).withValues(alpha: 0.08)
            : Theme.of(context).cardColor;
    final borderColor = isCompleted
        ? Colors.green.shade200
        : isLocked
            ? Theme.of(context).dividerColor
            : isMola
                ? Colors.green.shade100
                : Theme.of(context).dividerColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    final subTextColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    return GestureDetector(
      onTap: () {
        if (readOnly || isMola) return;
        if (isLocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Text('🎯 '),
                const Expanded(
                  child: Text(
                    'Önce öncelikli (zayıf) görevlerini bitirmelisin! Kaçış yok 🎯',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
              backgroundColor: const Color(0xFFFBBF24),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }
        _showStartTaskDialog(context, ref, task.copyWith(topicName: topicName));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left icon circle
            Opacity(
              opacity: isLocked ? 0.45 : 1.0,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _subjectColor(task.subjectName).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(task.emoji,
                      style: const TextStyle(fontSize: 22)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Middle info
            Expanded(
              child: Opacity(
                opacity: isLocked ? 0.55 : 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMola
                          ? 'Mola ☕'
                          : '${task.subjectName} — ${_taskTypeLabel(task.taskType)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: isCompleted
                            ? subTextColor
                            : isLocked
                                ? subTextColor
                                : textColor,
                      ),
                    ),
                    if (topicName != null && !isMola) ...[
                      const SizedBox(height: 2),
                      Text(
                        topicName,
                        style: TextStyle(
                            fontSize: 12, color: Colors.indigo.shade400),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isMola
                              ? Icons.coffee_outlined
                              : Icons.menu_book_outlined,
                          size: 13,
                          color: subTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${task.startTime} – ${task.endTime}',
                          style: TextStyle(fontSize: 13, color: subTextColor),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${task.durationMinutes} dk',
                          style: TextStyle(fontSize: 12, color: subTextColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Lock icon or checkbox — readOnly modda ve mola görevlerinde
            // hiçbiri gösterilmez (mola tamamlama gerektirmez).
            if (!readOnly && !isMola)
              if (isLocked)
                Icon(Icons.lock_outline, size: 20, color: subTextColor)
              else
                GestureDetector(
                  onTap: () {
                    final notifier = ref.read(completedTaskIdsProvider.notifier);
                    if (isCompleted) {
                      notifier.unmark(task.id);
                    } else {
                      // Ders detayını da yaz — Gelişimim günlük gruplama bunu okur.
                      notifier.mark(task.id,
                          task: task.copyWith(topicName: topicName));
                    }
                  },
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? Colors.green : Colors.transparent,
                      border: Border.all(
                        color: isCompleted ? Colors.green : subTextColor.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
          ],
        ),
      ),
    );
  }

  void _showStartTaskDialog(BuildContext context, WidgetRef ref, StudyTask task) {
    final router = GoRouter.of(context);
    final isManual = !task.id.startsWith('s_') &&
        !task.id.startsWith('w_') &&
        !task.id.startsWith('m_');
    final completedIds = ref.read(completedTaskIdsProvider);
    final isCompleted = completedIds.contains(task.id);

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCompleted
                      ? [const Color(0xFF059669), const Color(0xFF10B981)]
                      : [const Color(0xFF4338CA), const Color(0xFF6D28D9)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Text(task.emoji,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    task.subjectName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16),
                  ),
                ),
                if (isCompleted)
                  const Icon(Icons.check_circle, color: Colors.white, size: 18)
                else
                  Text('${task.durationMinutes} dk',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 16),
            // Tekrar çalış butonu — her zaman göster
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(dialogCtx).pop();
                  Future.delayed(const Duration(milliseconds: 250), () {
                    router.push('/study-session', extra: task);
                  });
                },
                icon: Icon(isCompleted
                    ? Icons.replay_rounded
                    : Icons.play_arrow_rounded),
                label: Text(
                  isCompleted ? 'Tekrar Çalış' : 'Dersi Başlat',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted
                      ? const Color(0xFF059669)
                      : const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Tamamlamayı kaldır — sadece tamamlanmış görevlerde
            if (isCompleted)
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(dialogCtx).pop();
                    ref.read(completedTaskIdsProvider.notifier).unmark(task.id);
                  },
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.orange),
                  label: const Text('Tamamlamayı Kaldır',
                      style: TextStyle(color: Colors.orange)),
                ),
              ),
            if (isManual && !isCompleted)
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(dialogCtx).pop();
                    ref.read(manualTasksProvider.notifier).remove(task.id);
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Görevi Kaldır',
                      style: TextStyle(color: Colors.red)),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Kapat',
                  style: TextStyle(color: Colors.grey))),
          ]),
        ),
      ),
    );
  }

  static String _taskTypeLabel(String type) {
    switch (type) {
      case 'konu_anlatimi':
        return 'Konu Anlatımı';
      case 'soru_cozumu':
        return 'Soru Çözümü';
      case 'deneme':
        return 'Deneme Sınavı';
      case 'tekrar':
        return 'Tekrar';
      case 'mola':
        return 'Mola';
      default:
        return type;
    }
  }

  static Color _subjectColor(String name) {
    if (name.contains('Matematik') || name.contains('Geometri')) {
      return const Color(0xFFF59E0B);
    }
    if (name.contains('Fizik')) { return const Color(0xFFEF4444); }
    if (name.contains('Kimya')) { return const Color(0xFF10B981); }
    if (name.contains('Biyoloji')) { return const Color(0xFF8B5CF6); }
    if (name.contains('Türkçe') || name.contains('Edebiyat')) {
      return const Color(0xFF3B82F6);
    }
    if (name.contains('Tarih') || name.contains('İnkılap')) {
      return const Color(0xFFF97316);
    }
    if (name.contains('Mola')) { return const Color(0xFF6EE7B7); }
    return const Color(0xFF4F46E5);
  }
}
