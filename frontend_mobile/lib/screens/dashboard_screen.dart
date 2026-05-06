import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/quick_note.dart';
import '../models/study_task.dart';
import '../providers/study_plan_provider.dart';
import '../data/subject_topics.dart';
import '../models/subject_data.dart';
import '../widgets/task_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(examCountdownProvider);
      ref.invalidate(studyPlanProvider);
      ref.invalidate(todayTasksProvider);
      ref.invalidate(manualTasksProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(todayTasksProvider);
    final examAsync = ref.watch(examCountdownProvider);

    final dayName = DateFormat('EEEE', 'tr_TR').format(DateTime.now());
    final taskCount =
        todayAsync.value?.where((t) => !t.isMola).length ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      body: Stack(
        children: [
          // ── Scrollable content with collapsible header ───────────────
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 160,
                floating: false,
                pinned: false,
                snap: false,
                elevation: 0,
                backgroundColor: const Color(0xFF4338CA),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Gradient fill
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF4338CA),
                              Color(0xFF6D28D9),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                                20, 16, 60, 16),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Row(children: [
                                  Expanded(
                                    child: Text(
                                      'Bugünün Görevleri ($dayName)',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.info_outline_rounded,
                                        color: Colors.white70),
                                    onPressed: () =>
                                        _showInfoSheet(context),
                                  ),
                                ]),
                                const SizedBox(height: 4),
                                Text(
                                  taskCount == 0
                                      ? 'Bugün için planlanmış bir görev yok.'
                                      : '$taskCount görev planlandı',
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Countdown ball
                      examAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (days) => days == null
                            ? const SizedBox.shrink()
                            : Positioned(
                                right: 16,
                                bottom: 0,
                                child: _CountdownBall(days: days),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: todayAsync.when(
                    loading: () => const _LoadingSkeleton(),
                    error: (_, _) => const _ErrorState(),
                    data: (tasks) => _ContentArea(
                      tasks: tasks,
                      onWeeklyPlan: () =>
                          _showWeeklyPlanSheet(context, ref),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // ── FAB: Note (bottom-left) ──────────────────────────────────
          Positioned(
            bottom: 24,
            left: 16,
            child: _FABNote(
                onTap: () => _showQuickNoteSheet(context, ref)),
          ),

          // ── FAB: Add task (bottom-right) ─────────────────────────────
          Positioned(
            bottom: 24,
            right: 16,
            child: _FABAddTask(
              onTap: () => _showAddTaskSheet(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom sheets ──────────────────────────────────────────────────────────

  void _showInfoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Çalışacağın saatleri biz senin biyoritmine göre seçtik, '
                'fakat zorunlu durumlarda bu saatlere tam uymayabilirsin. '
                'Esnek ol!',
                style: TextStyle(
                    color: Colors.white, fontSize: 16, height: 1.6),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showWeeklyPlanSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, sc) => _WeeklyPlanSheet(scrollController: sc),
      ),
    );
  }

  void _showQuickNoteSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _QuickNoteSheet(),
    );
  }

  void _showAddTaskSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _AddTaskMenu(
        onTopicEditor: () {
          Navigator.pop(ctx);
          _showTopicEditorSheet(context, ref);
        },
        onManualTask: () {
          Navigator.pop(ctx);
          _showManualTaskSheet(context, ref);
        },
        onRestMode: () {
          Navigator.pop(ctx);
          _showRestModeDialog(context, ref);
        },
      ),
    );
  }

  void _showTopicEditorSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, sc) => _TopicEditorSheet(scrollController: sc),
      ),
    );
  }

  void _showManualTaskSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _ManualTaskSheet(),
    );
  }

  void _showRestModeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: _RestModeDialog(
          onConfirm: () {
            final tasks = ref.read(todayTasksProvider).value ?? [];
            ref.read(completedTaskIdsProvider.notifier).state =
                tasks.map((t) => t.id).toSet();
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('Dinlenme modu aktif. İyi dinlenmeler! 🌙'),
              backgroundColor: Color(0xFF10B981),
            ));
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COUNTDOWN BALL
// ─────────────────────────────────────────────────────────────────────────────

class _CountdownBall extends StatelessWidget {
  final int days;
  const _CountdownBall({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$days',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'GÜN',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTENT AREA
// ─────────────────────────────────────────────────────────────────────────────

class _ContentArea extends StatelessWidget {
  final List<StudyTask> tasks;
  final VoidCallback onWeeklyPlan;

  const _ContentArea({required this.tasks, required this.onWeeklyPlan});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _WeeklyPlanButton(onTap: onWeeklyPlan),
        const SizedBox(height: 16),
        if (tasks.isEmpty) _EmptyState() else _TaskList(tasks: tasks),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Bugün için planlanmış görev yok.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            'Aşağıdaki butona basarak görev ekle\nya da haftalık planını incele.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

class _TaskList extends ConsumerWidget {
  final List<StudyTask> tasks;
  const _TaskList({required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedIds = ref.watch(completedTaskIdsProvider);

    final weakTasks =
        tasks.where((t) => !t.isStrong && !t.isMola).toList();
    final generatedStrongTasks =
        tasks.where((t) => t.isStrong && !t.isMola && t.id.startsWith('s_')).toList();
    final manualStrongTasks =
        tasks.where((t) => t.isStrong && !t.isMola && !t.id.startsWith('s_')).toList();
    final molaTasks = tasks.where((t) => t.isMola).toList();

    final priorityTasks = [...weakTasks, ...molaTasks]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final weakDone = weakTasks.isEmpty ||
        weakTasks.every((t) => completedIds.contains(t.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (weakTasks.isNotEmpty || molaTasks.isNotEmpty) ...[
          _SectionHeader(
            icon: '🔥',
            text: 'Öncelikli: Zorlandığım Dersler',
            color: const Color(0xFFEF4444),
          ),
          const SizedBox(height: 8),
          ...priorityTasks.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TaskCard(task: t, isLocked: false),
              )),
        ],
        if (generatedStrongTasks.isNotEmpty || manualStrongTasks.isNotEmpty) ...[
          const SizedBox(height: 8),
          _SectionHeader(
            icon: '⚡',
            text: weakDone
                ? 'Pekiştirme: Güçlü Dersler'
                : 'Pekiştirme: Güçlü Dersler 🔒',
            color: const Color(0xFFF59E0B),
            isLocked: !weakDone,
          ),
          const SizedBox(height: 8),
          ...generatedStrongTasks.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TaskCard(task: t, isLocked: !weakDone),
              )),
          ...manualStrongTasks.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TaskCard(task: t, isLocked: false),
              )),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String icon;
  final String text;
  final Color color;
  final bool isLocked;

  const _SectionHeader({
    required this.icon,
    required this.text,
    required this.color,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14),
          ),
        ),
        if (isLocked) Icon(Icons.lock, size: 14, color: color),
      ]),
    );
  }
}

class _WeeklyPlanButton extends StatelessWidget {
  final VoidCallback onTap;
  const _WeeklyPlanButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBFBFFF)),
        ),
        child: Row(
          children: [
            const Text('📅', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            const Text(
              'Haftalık Planımı İncele',
              style: TextStyle(
                color: Color(0xFF4F46E5),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.indigo.shade300),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FABs
// ─────────────────────────────────────────────────────────────────────────────

class _FABNote extends StatelessWidget {
  final VoidCallback onTap;
  const _FABNote({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: Color(0xFFF97316),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: const Icon(Icons.edit_note_rounded,
            color: Colors.white, size: 28),
      ),
    );
  }
}

class _FABAddTask extends StatelessWidget {
  final VoidCallback onTap;
  const _FABAddTask({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF4F46E5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white, size: 22),
            SizedBox(width: 6),
            Text('Görev',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WEEKLY PLAN SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _WeeklyPlanSheet extends ConsumerWidget {
  final ScrollController scrollController;
  const _WeeklyPlanSheet({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(studyPlanProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Icon(Icons.calendar_month,
                    color: Color(0xFF4F46E5)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Haftalık Planım',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('PDF İndir',
                      style: TextStyle(
                          color: Color(0xFF4F46E5),
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Expanded(
            child: planAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  const Center(child: Text('Plan yüklenemedi.')),
              data: (days) => ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: days.length,
                itemBuilder: (_, i) {
                  final day = days[i];
                  final dateStr = DateFormat('d MMM – EEEE', 'tr_TR')
                      .format(day.date);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          dateStr,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (day.isOffDay)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(children: [
                            const Text('🏖️',
                                style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text('Dinlenme günü',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 15)),
                          ]),
                        )
                      else if (day.blocks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('Bu gün için plan yok.',
                              style: TextStyle(
                                  color: Colors.grey.shade400)),
                        )
                      else
                        ...day.blocks.map((b) {
                          final task = StudyTask.fromBlock(b, day.date);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TaskCard(task: task),
                          );
                        }),
                      const Divider(),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK NOTE SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _QuickNoteSheet extends ConsumerStatefulWidget {
  const _QuickNoteSheet();

  @override
  ConsumerState<_QuickNoteSheet> createState() => _QuickNoteSheetState();
}

class _QuickNoteSheetState extends ConsumerState<_QuickNoteSheet> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sheetHandle(),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('⚡',
                    style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hızlı Not Ekle',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  Text(
                    DateFormat('d MMMM yyyy · HH:mm', 'tr_TR')
                        .format(now),
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              hintText: 'Başlık girin (Opsiyonel)',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _contentCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Aklına geleni yaz...',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final content = _contentCtrl.text.trim();
                if (content.isEmpty) { return; }
                final note = QuickNote(
                  id: '${DateTime.now().millisecondsSinceEpoch}',
                  title: _titleCtrl.text.trim().isEmpty
                      ? null
                      : _titleCtrl.text.trim(),
                  content: content,
                  createdAt: DateTime.now(),
                );
                ref.read(quickNotesProvider.notifier).addNote(note);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check),
              label: const Text('Kaydet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD TASK MENU
// ─────────────────────────────────────────────────────────────────────────────

class _AddTaskMenu extends StatelessWidget {
  final VoidCallback onTopicEditor;
  final VoidCallback onManualTask;
  final VoidCallback onRestMode;

  const _AddTaskMenu({
    required this.onTopicEditor,
    required this.onManualTask,
    required this.onRestMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sheetHandle(),
          const SizedBox(height: 16),
          const Text('Ne Yapmak İstersin?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          _ActionTile(
            color: const Color(0xFFEEF2FF),
            iconColor: const Color(0xFF4F46E5),
            icon: Icons.list_alt_rounded,
            title: 'Çalışma Programım İçin Konuları Düzenle',
            subtitle: 'Derslerine konu ata ve takibini yap',
            onTap: onTopicEditor,
          ),
          const SizedBox(height: 10),
          _ActionTile(
            color: const Color(0xFFFFF7ED),
            iconColor: const Color(0xFFF97316),
            icon: Icons.edit_rounded,
            title: 'Kendim Görev Ekle',
            subtitle: 'Manuel olarak ders, konu ve süre belirle',
            onTap: onManualTask,
          ),
          const SizedBox(height: 10),
          _ActionTile(
            color: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF10B981),
            icon: Icons.sick_outlined,
            title: 'Hastayım / Dinlenme Modu',
            subtitle: 'Bugün çalışamayacak kadar kötüysen',
            onTap: onRestMode,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final Color color;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.color,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPIC EDITOR SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _TopicEditorSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  const _TopicEditorSheet({required this.scrollController});

  @override
  ConsumerState<_TopicEditorSheet> createState() =>
      _TopicEditorSheetState();
}

class _TopicEditorSheetState extends ConsumerState<_TopicEditorSheet> {
  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(studyPlanProvider);
    final assignments = ref.watch(topicAssignmentsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            child: Row(
              children: [
                const Text('📋',
                    style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Haftalık Konuları Düzenle',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              'Her dersin üzerine tıklayarak konu atayabilirsin',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ),
          Expanded(
            child: planAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  const Center(child: Text('Plan yüklenemedi.')),
              data: (days) {
                final today = DateTime.now();
                final todayAndTomorrow = days
                    .where((d) =>
                        d.date.difference(today).inDays >= 0 &&
                        d.date.difference(today).inDays <= 6 &&
                        !d.isOffDay &&
                        d.blocks.isNotEmpty)
                    .toList();

                return ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: todayAndTomorrow.length,
                  itemBuilder: (_, i) {
                    final day = todayAndTomorrow[i];
                    final studyBlocks =
                        day.blocks.where((b) => !b.isMola).toList();
                    final dateStr = DateFormat('EEEE – d MMMM', 'tr_TR')
                        .format(day.date);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 16, color: Color(0xFF4F46E5)),
                              const SizedBox(width: 6),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        ...studyBlocks.map((b) {
                          final assigned = assignments[b.id];
                          return GestureDetector(
                            onTap: () => _pickTopic(context, b.id, b.subjectName),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Text(b.emoji,
                                      style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(b.subjectName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14)),
                                        if (assigned != null)
                                          Text(assigned,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF4F46E5))),
                                      ],
                                    ),
                                  ),
                                  assigned != null
                                      ? const Icon(Icons.edit,
                                          color: Color(0xFF4F46E5))
                                      : Icon(Icons.add_circle_outline,
                                          color: Colors.grey.shade400),
                                ],
                              ),
                            ),
                          );
                        }),
                        const Divider(),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _pickTopic(BuildContext context, String blockId, String subjectName) {
    final topics = getTopicsForSubject(subjectName);
    if (topics.isEmpty) { return; }
    String? selected = ref.read(topicAssignmentsProvider)[blockId];

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('$subjectName – Konu Seç',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                  if (selected != null)
                    TextButton(
                      onPressed: () {
                        ref
                            .read(topicAssignmentsProvider.notifier)
                            .update((s) => {...s}..remove(blockId));
                        Navigator.pop(ctx);
                      },
                      child: const Text('Temizle',
                          style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: topics.length,
                itemBuilder: (_, i) {
                  final topic = topics[i];
                  final isSelected = selected == topic;
                  return ListTile(
                    title: Text(topic),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle,
                            color: Color(0xFF4F46E5))
                        : const Icon(Icons.radio_button_unchecked,
                            color: Colors.grey),
                    onTap: () {
                      setState(() => selected = topic);
                      ref
                          .read(topicAssignmentsProvider.notifier)
                          .update((s) => {...s, blockId: topic});
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MANUAL TASK SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _ManualTaskSheet extends ConsumerStatefulWidget {
  const _ManualTaskSheet();

  @override
  ConsumerState<_ManualTaskSheet> createState() => _ManualTaskSheetState();
}

class _ManualTaskSheetState extends ConsumerState<_ManualTaskSheet> {
  String? _subject;
  String? _topic;
  String _taskType = 'konu_anlatimi';
  int _duration = 60;

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(onboardingDataProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHandle(),
            const SizedBox(height: 12),
            const Row(
              children: [
                Text('✏️', style: TextStyle(fontSize: 24)),
                SizedBox(width: 8),
                Text('Görev Ekle',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 20),

            // Ders seçici
            _label('Ders'),
            dataAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('Veriler yüklenemedi.'),
              data: (data) {
                final subjects = data == null
                    ? <String>[]
                    : getSubjectsForExam(data.targetExam, data.selectedArea)
                        .map((s) => s.name)
                        .toList();
                return DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _subject,
                  hint: const Text('Ders seç'),
                  items: subjects
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s,
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() { _subject = v; _topic = null; }),
                  decoration: _inputDecoration(),
                );
              },
            ),
            const SizedBox(height: 14),

            // Konu seçici
            _label('Konu (İsteğe Bağlı)'),
            DropdownButtonFormField<String?>(
              isExpanded: true,
              initialValue: _topic,
              hint: const Text('🚫 Konu Belirtmek İstemiyorum'),
              items: [
                const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('🚫 Konu Belirtmek İstemiyorum',
                        overflow: TextOverflow.ellipsis)),
                ...getTopicsForSubject(_subject ?? '').map(
                    (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t,
                            overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (v) => setState(() => _topic = v),
              decoration: _inputDecoration(),
            ),
            const SizedBox(height: 14),

            // Görev türü
            _label('Görev Türü'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _typeChip('Konu Çalışması', 'konu_anlatimi',
                    const Color(0xFFFFF7ED), const Color(0xFFF97316)),
                _typeChip('Soru Çözümü', 'soru_cozumu',
                    Colors.white, Colors.black87),
                _typeChip('Deneme Sınavı', 'deneme',
                    Colors.white, Colors.black87),
                _typeChip('Tekrar', 'tekrar',
                    Colors.white, Colors.black87),
              ],
            ),
            const SizedBox(height: 14),

            // Süre
            _label('Süre (dk)'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [30, 45, 60, 90, 120, 180]
                  .map((dk) => _durationChip(dk))
                  .toList(),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal',
                      style: TextStyle(
                          color: Color(0xFF4F46E5), fontSize: 16)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _subject == null
                      ? null
                      : () {
                          // Bugünkü son görevin bitiş saatini bul
                          final todayTasks =
                              ref.read(todayTasksProvider).value ?? [];
                          int startMins = 9 * 60;
                          if (todayTasks.isNotEmpty) {
                            final last = todayTasks.last;
                            final parts = last.endTime
                                .split(':')
                                .map(int.tryParse)
                                .toList();
                            if (parts.length == 2 &&
                                parts[0] != null &&
                                parts[1] != null) {
                              startMins = parts[0]! * 60 + parts[1]! + 10;
                            }
                          }
                          startMins = startMins % (24 * 60);
                          final endMins = (startMins + _duration) % (24 * 60);
                          String fmt(int m) =>
                              '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
                          final task = StudyTask(
                            id: '${DateTime.now().millisecondsSinceEpoch}',
                            subjectName: _subject!,
                            emoji: _emojiFor(_subject!),
                            startTime: fmt(startMins),
                            endTime: fmt(endMins),
                            durationMinutes: _duration,
                            taskType: _taskType,
                            isCompleted: false,
                            isMola: false,
                            isStrong: true,
                            topicName: _topic,
                            date: DateTime.now(),
                          );
                          ref
                              .read(manualTasksProvider.notifier)
                              .add(task);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '$_subject görevi eklendi! ✅'),
                              backgroundColor: Colors.green.shade600,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Ekle',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String label, String value, Color bg, Color fg) {
    final selected = _taskType == value;
    return GestureDetector(
      onTap: () => setState(() => _taskType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF97316) : bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected
                  ? const Color(0xFFF97316)
                  : Colors.grey.shade300),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : fg,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _durationChip(int dk) {
    final selected = _duration == dk;
    return GestureDetector(
      onTap: () => setState(() => _duration = dk),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected
                  ? const Color(0xFF4F46E5)
                  : Colors.grey.shade300),
        ),
        child: Text('$dk dk',
            style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  static String _emojiFor(String name) {
    if (name.contains('Matematik') || name.contains('Geometri')) { return '📐'; }
    if (name.contains('Fizik')) { return '⚡'; }
    if (name.contains('Kimya')) { return '🧪'; }
    if (name.contains('Biyoloji')) { return '🧬'; }
    if (name.contains('Türkçe')) { return '📖'; }
    if (name.contains('Edebiyat')) { return '✏️'; }
    if (name.contains('Tarih')) { return '🏛️'; }
    if (name.contains('Coğrafya')) { return '🌍'; }
    if (name.contains('Felsefe')) { return '💭'; }
    return '📚';
  }

  static Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
      );

  static InputDecoration _inputDecoration() => InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// REST MODE DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _RestModeDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  const _RestModeDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🤒', style: TextStyle(fontSize: 28)),
              SizedBox(width: 8),
              Text('Geçmiş Olsun',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Bugün kendini iyi hissetmiyor musun? '
            'Sağlığın her şeyden önemli. Bugünün '
            'tüm görevlerini iptal edip dinlenmek ister misin?',
            style: TextStyle(
                fontSize: 15, height: 1.6, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç',
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Evet, Dinleneceğim',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING / ERROR STATES
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          const Text('Plan yüklenemedi.',
              style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

Widget _sheetHandle() => Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
