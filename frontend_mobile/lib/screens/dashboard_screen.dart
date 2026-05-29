import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/app_theme.dart';
import '../models/onboarding_data.dart';
import '../models/study_plan.dart';
import '../models/study_task.dart';
import '../providers/gelisimim_provider.dart';
import '../providers/study_plan_provider.dart';
import '../data/subject_topics.dart';
import '../models/subject_data.dart';
import '../widgets/task_card.dart';
import '../widgets/quick_note_sheet.dart';

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
      ref.invalidate(examStatusProvider);
      ref.invalidate(onboardingDataProvider);
      ref.invalidate(studyPlanProvider);
      ref.invalidate(todayTasksProvider);
      ref.invalidate(manualTasksProvider);
      ref.invalidate(questionSubjectsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(todayTasksProvider);
    final examStatusAsync = ref.watch(examStatusProvider);
    final examStatus = examStatusAsync.value;

    final dayName = DateFormat('EEEE', 'tr_TR').format(DateTime.now());
    final taskCount =
        todayAsync.value?.where((t) => !t.isMola).length ?? 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                      // Countdown ball / Sınav günü rozeti
                      if (examStatus != null &&
                          examStatus.phase == ExamPhase.upcoming)
                        Positioned(
                          right: 16,
                          bottom: 0,
                          child: _CountdownBall(days: examStatus.daysLeft),
                        )
                      else if (examStatus != null &&
                          examStatus.phase == ExamPhase.today)
                        const Positioned(
                          right: 16,
                          bottom: 0,
                          child: _ExamDayBall(),
                        ),
                    ],
                  ),
                ),
              ),
              // ── Hedefe Kalan Yol ─────────────────────────────────────
              SliverToBoxAdapter(
                child: _ExamGoalCard(ref: ref),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: todayAsync.when(
                    loading: () => const _LoadingSkeleton(),
                    error: (_, _) => _ContentArea(
                      tasks: const [],
                      onWeeklyPlan: () =>
                          _showWeeklyPlanSheet(context, ref),
                    ),
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
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => QuickNoteSheet(messenger: messenger),
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
          // Zaten dinlenme modundaysa tekrar onay sorma — sadece uyarı.
          if (ref.read(restDaysProvider.notifier).isTodayRest) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Zaten dinlenme modundasın 😴'),
              backgroundColor: Color(0xFF10B981),
            ));
            return;
          }
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
            // Tamamlanmamış görevleri otomatik tamamlama; daha önce
            // tamamlananlar tamamlanmış kalır.
            ref.read(restDaysProvider.notifier).markToday();
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
// EXAM GOAL CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ExamGoalCard extends ConsumerWidget {
  final WidgetRef ref;
  const _ExamGoalCard({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalAsync = ref.watch(examGoalProvider);
    // OkulSinavi → hedef "net" değil "ortalama" (not ortalaması) olarak gösterilir.
    final targetExam = ref.watch(onboardingDataProvider).maybeWhen(
          data: (d) => d?.targetExam ?? '',
          orElse: () => '',
        );
    final unitLabel = targetExam == 'OkulSinavi' ? 'Ortalama' : 'Net';
    return goalAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (goal) {
        final tytHedef = (goal['tytHedef'] as String? ?? '').trim();
        final tytNet = goal['tytNet'] as double?;
        final aytHedef = (goal['aytHedef'] as String? ?? '').trim();
        final aytNet = goal['aytNet'] as double?;

        final hasTyt = tytHedef.isNotEmpty;
        final hasAyt = aytHedef.isNotEmpty;

        if (!hasTyt && !hasAyt) return const SizedBox.shrink();

        // Satır üret: "hedef — X.X Net/Ortalama" ya da sadece "hedef"
        String line(String hedef, double? net) =>
            net != null ? '$hedef — ${net.toStringAsFixed(1)} $unitLabel' : hedef;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🚀', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hedefe Kalan Yol',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hasTyt) ...[
                      if (hasAyt)
                        const Text('TYT',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      Text(
                        line(tytHedef, tytNet),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                    if (hasTyt && hasAyt) const SizedBox(height: 6),
                    if (hasAyt) ...[
                      if (hasTyt)
                        const Text('AYT',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      Text(
                        line(aytHedef, aytNet),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                    const SizedBox(height: 4),
                    const Text(
                      'Bas Gaza! 💪',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

// Sınav günü rozeti — kalan gün yerine bugün sınav olduğunda gösterilir.
class _ExamDayBall extends StatelessWidget {
  const _ExamDayBall();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🎯', style: TextStyle(fontSize: 22)),
          SizedBox(height: 2),
          Text(
            'SINAV\nGÜNÜ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

// Sınav günü kutlama mesajı — içerik alanının üstünde, o gün boyunca.
class _ExamDayBanner extends StatelessWidget {
  const _ExamDayBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Text('🎉', style: TextStyle(fontSize: 44)),
          SizedBox(height: 8),
          Text('Sınavında başarılar!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text(
            'Bugün senin günün. Sakin ol, kendine güven — emeklerinin karşılığını alacaksın. 💪',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTENT AREA
// ─────────────────────────────────────────────────────────────────────────────

class _ContentArea extends ConsumerWidget {
  final List<StudyTask> tasks;
  final VoidCallback onWeeklyPlan;

  const _ContentArea({required this.tasks, required this.onWeeklyPlan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restDays = ref.watch(restDaysProvider);
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final isRestToday = restDays.contains(todayStr);

    // Haftalık plan süresi doldu mu? Doluysa task listesi yerine yenileme akışı.
    final planAsync = ref.watch(studyPlanProvider);
    final planExpired = planAsync.maybeWhen(
      data: (plan) => isPlanExpired(plan),
      orElse: () => false,
    );

    // Sınav bugünse kutlama mesajı (o gün boyunca).
    final isExamDay = ref.watch(examStatusProvider).maybeWhen(
          data: (s) => s.phase == ExamPhase.today,
          orElse: () => false,
        );

    return Column(
      children: [
        _WeeklyPlanButton(onTap: onWeeklyPlan),
        const SizedBox(height: 16),
        if (isExamDay) ...[
          const _ExamDayBanner(),
          const SizedBox(height: 16),
        ],
        if (planExpired)
          _PlanExpiredState(
            onRenewSame: () => _showRenewSameDialog(context, ref),
            onRenewChange: () => _showRenewChangeSheet(context, ref),
          )
        else if (isRestToday)
          _RestDayState(onDisable: () {
            ref.read(restDaysProvider.notifier).unmarkToday();
          })
        else if (tasks.isEmpty)
          _EmptyState()
        else
          _TaskList(tasks: tasks),
      ],
    );
  }

  Future<void> _showRenewSameDialog(BuildContext context, WidgetRef ref) async {
    // .value yerine .future: provider invalidate edildikten sonra ilk açılışta
    // eski hesabın cache'lenmiş değeri dönebiliyor. .future her zaman güncel
    // (yeni hesabın) onboarding verisini çözer.
    final data = await ref.read(onboardingDataProvider.future);
    if (data == null || !context.mounted) return;
    showDialog(
      context: context,
      builder: (dialogCtx) => _RenewSameDialog(
        data: data,
        onConfirm: () async {
          Navigator.of(dialogCtx).pop();
          await regenerateStudyPlan(ref);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Yeni haftalık programın hazır! 🎉'),
              backgroundColor: Color(0xFF10B981),
            ));
          }
        },
      ),
    );
  }

  Future<void> _showRenewChangeSheet(BuildContext context, WidgetRef ref) async {
    final data = await ref.read(onboardingDataProvider.future);
    if (data == null || !context.mounted) return;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, sc) => _RenewChangeSheet(
          data: data,
          scrollController: sc,
          onConfirm: (updated) async {
            Navigator.of(sheetCtx).pop();
            await regenerateStudyPlan(ref, overrideOnboarding: updated);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Yeni haftalık programın hazır! 🎉'),
                backgroundColor: Color(0xFF10B981),
              ));
            }
          },
        ),
      ),
    );
  }
}

class _PlanExpiredState extends StatelessWidget {
  final VoidCallback onRenewSame;
  final VoidCallback onRenewChange;
  const _PlanExpiredState({required this.onRenewSame, required this.onRenewChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 10),
          Text(
            'Tebrikler haftalık çalışmanı tamamladın!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Yeni haftaya hazır mısın?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRenewSame,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('🔁 Aynı Derslerle Yeni Program',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onRenewChange,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('✏️ Dersleri Değiştir',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RenewSameDialog extends StatelessWidget {
  final OnboardingData data;
  final VoidCallback onConfirm;
  const _RenewSameDialog({required this.data, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final weak = data.weakSubjects;
    final strong = data.strongSubjects;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🔁 Aynı Derslerle Yeni Program',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              const Text(
                'Mevcut ders profilinle yeni 7 günlük program oluşturulacak.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text('⚡ Zorlandığın Dersler',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFEA580C))),
              const SizedBox(height: 6),
              if (weak.isEmpty)
                const Text('Seçili değil', style: TextStyle(fontSize: 12, color: Colors.grey))
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: weak
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: const Color(0xFFFFEDD5),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(s,
                                style: const TextStyle(
                                    color: Color(0xFF9A3412),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ))
                      .toList(),
                ),
              const SizedBox(height: 12),
              const Text('💪 Güçlü Olduğun Dersler',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
              const SizedBox(height: 6),
              if (strong.isEmpty)
                const Text('Seçili değil', style: TextStyle(fontSize: 12, color: Colors.grey))
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: strong
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(s,
                                style: const TextStyle(
                                    color: Color(0xFF15803D),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ))
                      .toList(),
                ),
              const SizedBox(height: 16),
              const Text(
                'Bu derslere göre program oluşturulacaktır, emin misin?',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Vazgeç', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: weak.isEmpty ? null : onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Evet, oluştur', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RenewChangeSheet extends StatefulWidget {
  final OnboardingData data;
  final ScrollController scrollController;
  final void Function(OnboardingData updated) onConfirm;
  const _RenewChangeSheet({
    required this.data,
    required this.scrollController,
    required this.onConfirm,
  });

  @override
  State<_RenewChangeSheet> createState() => _RenewChangeSheetState();
}

class _RenewChangeSheetState extends State<_RenewChangeSheet> {
  late List<String> _strong;
  late List<String> _weak;
  String? _error;

  @override
  void initState() {
    super.initState();
    _strong = List<String>.from(widget.data.strongSubjects);
    _weak = List<String>.from(widget.data.weakSubjects);
  }

  void _toggle(String name, {required bool isStrong}) {
    setState(() {
      _error = null;
      if (isStrong) {
        if (_strong.contains(name)) {
          _strong.remove(name);
        } else {
          _strong.add(name);
          _weak.remove(name);
        }
      } else {
        if (_weak.contains(name)) {
          _weak.remove(name);
        } else {
          _weak.add(name);
          _strong.remove(name);
        }
      }
    });
  }

  void _submit() {
    final isFullyManual = widget.data.targetExam == 'OkulSinavi' &&
        widget.data.selectedArea == 'uni_diger';
    final hasMin = isFullyManual
        ? widget.data.customSubjects.isNotEmpty
        : _weak.isNotEmpty;
    if (!hasMin) {
      setState(() {
        _error = 'Program oluşturmak için en az 1 zayıf ders seçmelisin.';
      });
      return;
    }
    widget.onConfirm(widget.data.copyWith(
      strongSubjects: _strong,
      weakSubjects: _weak,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isFullyManual = widget.data.targetExam == 'OkulSinavi' &&
        widget.data.selectedArea == 'uni_diger';
    final base = isFullyManual
        ? <SubjectData>[]
        : getSubjectsForExam(widget.data.targetExam, widget.data.selectedArea);
    final baseNames = base.map((s) => s.name).toSet();
    final extras = widget.data.customSubjects
        .where((n) => !baseNames.contains(n))
        .map((n) => SubjectData(name: n, emoji: '📝'))
        .toList();
    final allSubjects = [...base, ...extras];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('✏️ Dersleri Değiştir',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Eklemek veya çıkarmak istediğin dersleri seç.',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
            ),
          ),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              children: [
                const Text('💪 Güçlü Olduğun Dersler',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF16A34A))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: allSubjects.map((s) {
                    final isSel = _strong.contains(s.name);
                    final disabled = _weak.contains(s.name);
                    return GestureDetector(
                      onTap: disabled ? null : () => _toggle(s.name, isStrong: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF16A34A) : Colors.transparent,
                          border: Border.all(
                            color: isSel ? const Color(0xFF16A34A) : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Opacity(
                          opacity: disabled ? 0.4 : 1,
                          child: Text('${s.emoji} ${s.name}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSel ? Colors.white : null)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                const Text('⚡ Zorlandığın Dersler',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEA580C))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: allSubjects.map((s) {
                    final isSel = _weak.contains(s.name);
                    final disabled = _strong.contains(s.name);
                    return GestureDetector(
                      onTap: disabled ? null : () => _toggle(s.name, isStrong: false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFEA580C) : Colors.transparent,
                          border: Border.all(
                            color: isSel ? const Color(0xFFEA580C) : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Opacity(
                          opacity: disabled ? 0.4 : 1,
                          child: Text('${s.emoji} ${s.name}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSel ? Colors.white : null)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('⚠️ $_error',
                        style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 8, 20, 16 + MediaQuery.of(context).padding.bottom),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Vazgeç', style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Oluştur',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RestDayState extends StatelessWidget {
  final VoidCallback onDisable;
  const _RestDayState({required this.onDisable});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          const Text('😴', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Bugün dinlenme günü',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'İyileş ve yarın güçlü dön!',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onDisable,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEEF2FF),
              foregroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Dinlenme modunu kapat',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dimColor = Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.4);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: dimColor),
          const SizedBox(height: 16),
          Text(
            'Bugün için planlanmış görev yok.',
            style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 8),
          Text(
            'Aşağıdaki butona basarak görev ekle\nya da haftalık planını incele.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: dimColor),
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

    // Manuel görevler her zaman 'manual-' ön ekli — saatli plan bloklarından ayrı tut.
    bool isManual(StudyTask t) => t.id.startsWith('manual-');

    final weakTasks =
        tasks.where((t) => !t.isStrong && !t.isMola && !isManual(t)).toList();
    // Plan kaynaklı güçlü dersler (manuel olmayan)
    final generatedStrongTasks =
        tasks.where((t) => t.isStrong && !t.isMola && !isManual(t)).toList();
    // Manuel eklenen görevler — web ile aynı: her zaman en sonda gösterilir
    final manualStrongTasks = tasks.where(isManual).toList();
    final molaTasks = tasks.where((t) => t.isMola).toList();

    // Gece kuşu: 04:00'dan küçük saatler ertesi günün gece saati (+24h) sayılır.
    int sortKey(String hhmm) {
      final p = hhmm.split(':');
      if (p.length < 2) return 0;
      final h = int.tryParse(p[0]) ?? 0;
      final m = int.tryParse(p[1]) ?? 0;
      final mins = h * 60 + m;
      return mins < 4 * 60 ? mins + 24 * 60 : mins;
    }
    final priorityTasks = [...weakTasks, ...molaTasks]
      ..sort((a, b) => sortKey(a.startTime).compareTo(sortKey(b.startTime)));

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
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
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

  Future<void> _downloadPdf(BuildContext context, List<StudyDay> days) async {
    // Türkçe karakter desteği için Noto Sans fontlarını yükle
    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold    = await PdfGoogleFonts.notoSansBold();

    final doc = pw.Document();

    const months = [
      '', 'Ocak', 'Subat', 'Mart', 'Nisan', 'Mayis', 'Haziran',
      'Temmuz', 'Agustos', 'Eylul', 'Ekim', 'Kasim', 'Aralik'
    ];
    const monthsTr = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];

    pw.TextStyle regular({double size = 12, PdfColor? color}) =>
        pw.TextStyle(font: fontRegular, fontSize: size, color: color);
    pw.TextStyle bold({double size = 12, PdfColor? color}) =>
        pw.TextStyle(font: fontBold, fontSize: size, color: color);

    String fmtTime(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    String taskTypeLabel(String type) {
      switch (type) {
        case 'konu_anlatimi': return 'Konu Anlatimi';
        case 'soru_cozumu':   return 'Soru Cozumu';
        case 'deneme':        return 'Deneme Sinavi';
        case 'tekrar':        return 'Tekrar';
        case 'mola':          return 'Mola';
        default:              return type;
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Haftalik Calisma Planim',
              style: bold(size: 22),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'AI Study Coach — ${days.isNotEmpty ? '${days.first.date.day} ${months[days.first.date.month]}' : ''} itibaren',
              style: regular(size: 11, color: PdfColors.grey600),
            ),
            pw.Divider(color: PdfColors.indigo300, thickness: 1.5),
            pw.SizedBox(height: 4),
          ],
        ),
        build: (_) => days.map((day) {
          final dt = day.date;
          final dateLabel = '${dt.day} ${monthsTr[dt.month]} ${dt.year}';
          final weekdays = ['', 'Pazartesi', 'Sali', 'Carsamba', 'Persembe', 'Cuma', 'Cumartesi', 'Pazar'];
          final dayLabel = weekdays[dt.weekday];

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.indigo50,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  '$dayLabel, $dateLabel',
                  style: bold(size: 13, color: PdfColors.indigo800),
                ),
              ),
              pw.SizedBox(height: 6),
              if (day.isOffDay)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 8, bottom: 8),
                  child: pw.Text('Dinlenme gunu', style: regular(size: 12, color: PdfColors.grey600)),
                )
              else if (day.blocks.isEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 8, bottom: 8),
                  child: pw.Text('Bu gun icin plan yok.', style: regular(size: 12, color: PdfColors.grey500)),
                )
              else
                ...day.blocks.map((b) => pw.Container(
                  margin: const pw.EdgeInsets.only(left: 8, bottom: 5),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(left: pw.BorderSide(
                      color: b.isMola ? PdfColors.green400 : PdfColors.indigo300,
                      width: 3,
                    )),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          b.isMola ? 'Mola' : b.subjectName,
                          style: bold(size: 12),
                        ),
                      ),
                      pw.Text(
                        '${fmtTime(b.startTime)} - ${fmtTime(b.endTime)}  (${b.durationMinutes} dk)',
                        style: regular(size: 11, color: PdfColors.grey700),
                      ),
                      if (!b.isMola) ...[
                        pw.SizedBox(width: 8),
                        pw.Text(
                          taskTypeLabel(b.taskType),
                          style: regular(size: 10, color: PdfColors.indigo600),
                        ),
                      ],
                    ],
                  ),
                )),
              pw.SizedBox(height: 10),
            ],
          );
        }).toList(),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(studyPlanProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                planAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (days) => GestureDetector(
                    onTap: () => _downloadPdf(context, days),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.picture_as_pdf_rounded, size: 16, color: Color(0xFF4F46E5)),
                          SizedBox(width: 4),
                          Text('PDF İndir',
                              style: TextStyle(
                                  color: Color(0xFF4F46E5),
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
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
                padding: EdgeInsets.fromLTRB(
                    16, 0, 16, 24 + MediaQuery.of(context).padding.bottom),
                itemCount: days.length,
                itemBuilder: (_, i) {
                  final day = days[i];
                  final dateStr = DateFormat('d MMM – EEEE', 'tr_TR')
                      .format(day.date);
                  final now = DateTime.now();
                  final today =
                      DateTime(now.year, now.month, now.day);
                  final d = DateTime(day.date.year, day.date.month, day.date.day);
                  final isPast = d.isBefore(today);
                  return Opacity(
                    opacity: isPast ? 0.55 : 1,
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Text(
                              dateStr,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800),
                            ),
                            if (isPast) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text('Geçmiş Gün',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey.shade600)),
                              ),
                            ],
                          ],
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
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                                    fontSize: 15)),
                          ]),
                        )
                      else if (day.blocks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('Bu gün için plan yok.',
                              style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                        )
                      else
                        ...day.blocks.map((b) {
                          final task = StudyTask.fromBlock(b, day.date);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TaskCard(task: task, readOnly: true),
                          );
                        }),
                      const Divider(),
                    ],
                  ),
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
      // Alt safe area + telefon nav bar boşluğu — son seçenek kapanmasın
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sheetHandle(),
          const SizedBox(height: 16),
          const Text('Ne Yapmak İstersin?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          _ActionTile(
            iconColor: const Color(0xFF4F46E5),
            icon: Icons.list_alt_rounded,
            title: 'Çalışma Programım İçin Konuları Düzenle',
            subtitle: 'Derslerine konu ata ve takibini yap',
            onTap: onTopicEditor,
          ),
          const SizedBox(height: 10),
          _ActionTile(
            iconColor: const Color(0xFFF97316),
            icon: Icons.edit_rounded,
            title: 'Kendim Görev Ekle',
            subtitle: 'Manuel olarak ders, konu ve süre belirle',
            onTap: onManualTask,
          ),
          const SizedBox(height: 10),
          _ActionTile(
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
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
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
          color: iconColor.withValues(alpha: 0.12),
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
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodySmall?.color)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Theme.of(context).textTheme.bodySmall?.color),
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
              style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
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
                  padding: EdgeInsets.fromLTRB(
                      16, 0, 16, 24 + MediaQuery.of(context).padding.bottom),
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
                                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Theme.of(context).dividerColor),
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
    final predefinedTopics = getTopicsForSubject(subjectName);
    final initialSelected = ref.read(topicAssignmentsProvider)[blockId];
    // Controller bir kez oluşturulur — StatefulBuilder içinde yaratılırsa her
    // tuş basışında sıfırlanırdı.
    final ctrl = TextEditingController();

    void assignAndClose(BuildContext ctx, String topic) {
      ref.read(topicAssignmentsProvider.notifier).assign(blockId, topic);
      Navigator.pop(ctx);
    }

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) {
          String? selected = initialSelected;
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
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
                            ref.read(topicAssignmentsProvider.notifier)
                                .remove(blockId);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Temizle',
                              style: TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
                ),
                // Custom topic input
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ctrl,
                          autofocus: predefinedTopics.isEmpty,
                          decoration: InputDecoration(
                            hintText: 'Konu adı yaz ve ekle…',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onSubmitted: (v) {
                            final t = v.trim();
                            if (t.isNotEmpty) assignAndClose(ctx, t);
                          },
                          textInputAction: TextInputAction.done,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          final t = ctrl.text.trim();
                          if (t.isNotEmpty) assignAndClose(ctx, t);
                        },
                        child: Container(
                          height: 46, width: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
                if (predefinedTopics.isNotEmpty) ...[
                  const Divider(height: 1),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: predefinedTopics.length,
                      itemBuilder: (_, i) {
                        final topic = predefinedTopics[i];
                        final isSelected = selected == topic;
                        return ListTile(
                          title: Text(topic),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: Color(0xFF4F46E5))
                              : const Icon(Icons.radio_button_unchecked,
                                  color: Colors.grey),
                          onTap: () {
                            setSt(() => selected = topic);
                            assignAndClose(ctx, topic);
                          },
                        );
                      },
                    ),
                  ),
                ] else
                  // Sabit konu listesi olmayan (manuel/okul) dersler için ipucu.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                    child: Text(
                      'Bu ders için hazır konu listesi yok. Yukarıya konu adını yazıp ekleyebilirsin.',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ),
                SizedBox(height: 16 + MediaQuery.of(ctx).padding.bottom),
              ],
            ),
          );
        },
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
        // Alt safe area + nav bar boşluğu — Ekle/İptal butonları kapanmasın
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
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
                final base = data == null
                    ? <String>[]
                    : getSubjectsForExam(data.targetExam, data.selectedArea)
                        .map((s) => s.name)
                        .toList();
                // Add custom subjects not already in base pool
                final baseSet = base.toSet();
                final extra = (data?.customSubjects ?? [])
                    .where((s) => !baseSet.contains(s))
                    .toList();
                final subjects = [...base, ...extra];
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
            Builder(builder: (context) {
              final topics = getTopicsForSubject(_subject ?? '');
              if (topics.isEmpty) {
                // Özel dersler veya konu listesi olmayan dersler için serbest yazım
                return TextFormField(
                  initialValue: _topic,
                  decoration: _inputDecoration().copyWith(
                    hintText: 'Konu adı yaz (opsiyonel)',
                  ),
                  onChanged: (v) => setState(() => _topic = v.trim().isEmpty ? null : v.trim()),
                );
              }
              return DropdownButtonFormField<String?>(
                isExpanded: true,
                initialValue: _topic,
                hint: const Text('🚫 Konu Belirtmek İstemiyorum'),
                items: [
                  const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('🚫 Konu Belirtmek İstemiyorum',
                          overflow: TextOverflow.ellipsis)),
                  ...topics.map(
                      (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t,
                              overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => setState(() => _topic = v),
                decoration: _inputDecoration(),
              );
            }),
            const SizedBox(height: 14),

            // Görev türü
            _label('Görev Türü'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _typeChip(context, 'Konu Çalışması', 'konu_anlatimi'),
                _typeChip(context, 'Soru Çözümü', 'soru_cozumu'),
                _typeChip(context, 'Deneme Sınavı', 'deneme'),
                _typeChip(context, 'Tekrar', 'tekrar'),
              ],
            ),
            const SizedBox(height: 14),

            // Süre
            _label('Süre (dk)'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [30, 45, 60, 90, 120, 180]
                  .map((dk) => _durationChip(context, dk))
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
                          // Web ile aynı: manuel görev saatsiz eklenir,
                          // programın sonunda görünür. id 'manual-' ön ekli.
                          final task = StudyTask(
                            id: 'manual-${DateTime.now().millisecondsSinceEpoch}',
                            subjectName: _subject!,
                            emoji: _emojiFor(_subject!),
                            startTime: '',
                            endTime: '',
                            durationMinutes: _duration,
                            taskType: _taskType,
                            isCompleted: false,
                            isMola: false,
                            // Web ile aynı: manuel görev isStrong=false; bölge ayrımı
                            // 'manual-' id ön ekiyle yapılır.
                            isStrong: false,
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

  Widget _typeChip(BuildContext context, String label, String value) {
    final selected = _taskType == value;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    return GestureDetector(
      onTap: () => setState(() => _taskType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFF97316)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected
                  ? const Color(0xFFF97316)
                  : Theme.of(context).dividerColor),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : textColor,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _durationChip(BuildContext context, int dk) {
    final selected = _duration == dk;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    return GestureDetector(
      onTap: () => setState(() => _duration = dk),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF4F46E5)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected
                  ? const Color(0xFF4F46E5)
                  : Theme.of(context).dividerColor),
        ),
        child: Text('$dk dk',
            style: TextStyle(
                color: selected ? Colors.white : textColor,
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

  InputDecoration _inputDecoration() {
    final theme = Theme.of(context);
    return InputDecoration(
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
    );
  }
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
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
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
