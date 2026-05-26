import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';
import '../models/study_task.dart';
import '../providers/gelisimim_provider.dart';
import '../providers/study_plan_provider.dart';
import '../services/gelisimim_service.dart';
import '../widgets/quick_note_sheet.dart';
import 'gelisimim/soru_gelisimi_sheet.dart';
import 'gelisimim/gecmisi_gor_calendar.dart';

class GelisimimScreen extends ConsumerStatefulWidget {
  const GelisimimScreen({super.key});

  @override
  ConsumerState<GelisimimScreen> createState() => _GelisimimScreenState();
}

class _GelisimimScreenState extends ConsumerState<GelisimimScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Ekrana her geçişte canlı veriyi yenile — yeni tamamlanan görevler,
      // eklenen sorular ve günlere göre tamamlananlar anında yansısın.
      ref.invalidate(xpInfoProvider);
      ref.invalidate(gelisimimStatsProvider('all'));
      ref.invalidate(gelisimimStatsProvider('today'));
      ref.invalidate(lessonDistributionProvider('all'));
      ref.invalidate(lessonDistributionProvider('today'));
      ref.invalidate(localAllTimeStatsProvider);
      ref.invalidate(completedLessonsByDayProvider);
      ref.invalidate(questionsByDayProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(activeFilterProvider);
    final statsAsync = ref.watch(gelisimimStatsProvider(filter));
    final xpAsync = ref.watch(xpInfoProvider);
    final distAsync = ref.watch(lessonDistributionProvider(filter));
    final localStats = ref.watch(localTodayStatsProvider);
    final localXpBoost = ref.watch(localXpBoostProvider);
    final localAllAsync = ref.watch(localAllTimeStatsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(xpInfoProvider);
          ref.invalidate(gelisimimStatsProvider(filter));
          ref.invalidate(lessonDistributionProvider(filter));
        },
        child: CustomScrollView(
          slivers: [
            // ── Green XP header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: xpAsync.when(
                data: (xp) => _XpHeader(
                  xp: applyXpBoost(xp, localXpBoost),
                  localCompletedToday: localStats.completedTasks,
                ),
                loading: () => _XpHeaderSkeleton(),
                error: (e, st) => _XpHeader(
                  xp: XpInfo.empty,
                  localCompletedToday: localStats.completedTasks,
                ),
              ),
            ),
            // ── Body ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stat cards — lokal tamamlananlar her iki filtrede de eklenir
                    statsAsync.when(
                      data: (s) {
                        final pastLocal = localAllAsync.value;
                        // Dinlenme: kullanıcının açıkça işaretlediği günler
                        // (rest_days listesi). Bugün filtresi → bugün rest mi,
                        // tüm zamanlar → liste uzunluğu.
                        final restList = ref.watch(restDaysProvider);
                        // "Tüm Zamanlar" iken aktif kapsam (current vs total).
                        final allScope =
                            ref.watch(activeAllScopeProvider);
                        // Mevcut program penceresi (start..end) — current scope için filtre.
                        final plan = ref.watch(studyPlanProvider).value ?? [];
                        String? planStartStr;
                        String? planEndStr;
                        if (plan.isNotEmpty) {
                          String fmt(DateTime d) =>
                              '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                          planStartStr = fmt(plan.first.date);
                          planEndStr = fmt(plan.last.date);
                        }
                        bool inWindow(String date) {
                          final s = planStartStr;
                          final e = planEndStr;
                          if (s == null || e == null) return true;
                          return date.compareTo(s) >= 0 &&
                              date.compareTo(e) <= 0;
                        }
                        final today = DateTime.now();
                        final todayStr =
                            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                        final todayInWindow = inWindow(todayStr);

                        GelisimimStats merged;
                        if (filter == 'today') {
                          merged = GelisimimStats(
                            completedTasks: localStats.completedTasks,
                            totalMinutes: localStats.totalMinutes,
                            totalQuestions: s.totalQuestions,
                            restDays: localStats.restDays,
                          );
                        } else if (allScope == 'current') {
                          // Mevcut Program kapsamı: backend total'i kullanmaz;
                          // sadece plan penceresine düşen lokal kayıtları toplar.
                          final currentLocal =
                              ref.watch(currentPlanLocalStatsProvider).value;
                          final questionsByDay =
                              ref.watch(questionsByDayProvider).value ?? const [];
                          final qInWindow = questionsByDay
                              .where((r) => inWindow(r.date))
                              .fold<int>(
                                  0,
                                  (sum, r) =>
                                      sum +
                                      r.questions.fold<int>(
                                          0, (a, q) => a + q.count));
                          final restInWindow = restList
                              .where((d) => inWindow(d))
                              .length;
                          merged = GelisimimStats(
                            completedTasks:
                                (currentLocal?.completedTasks ?? 0) +
                                    (todayInWindow ? localStats.completedTasks : 0),
                            totalMinutes:
                                (currentLocal?.totalMinutes ?? 0) +
                                    (todayInWindow ? localStats.totalMinutes : 0),
                            totalQuestions: qInWindow,
                            restDays: restInWindow,
                          );
                        } else {
                          merged = GelisimimStats(
                            completedTasks: s.completedTasks +
                                localStats.completedTasks +
                                (pastLocal?.completedTasks ?? 0),
                            totalMinutes: s.totalMinutes +
                                localStats.totalMinutes +
                                (pastLocal?.totalMinutes ?? 0),
                            totalQuestions: s.totalQuestions,
                            restDays: restList.length,
                          );
                        }
                        return _StatsGrid(stats: merged);
                      },
                      loading: () => _StatsGridSkeleton(),
                      error: (e, st) => _StatsGrid(stats: localStats),
                    ),
                    const SizedBox(height: 16),
                    // Action buttons
                    _ActionButtons(onNote: _openNote),
                    const SizedBox(height: 12),
                    // Filter toggle — "Tüm Zamanlar" tıklanınca kapsam seçim sheet'i.
                    _FilterToggle(
                      selected: filter,
                      allScope: ref.watch(activeAllScopeProvider),
                      weeklyHistoryOn:
                          ref.watch(weeklyHistoryEnabledProvider).value ?? false,
                      onChanged: (v) {
                        if (v == 'all' &&
                            (ref.read(weeklyHistoryEnabledProvider).value ?? false)) {
                          _showAllScopePicker(context, ref);
                        } else {
                          if (v == 'all') {
                            ref.read(activeAllScopeProvider.notifier).state = 'total';
                          }
                          ref.read(activeFilterProvider.notifier).state = v;
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    // ── Ders Dağılımı (tamamlanan dersler) ──
                    Text('Ders Dağılımı',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).textTheme.bodyLarge?.color)),
                    const SizedBox(height: 12),
                    filter == 'today'
                        ? const _CompletedLessonsSection()
                        : const _CompletedLessonsByDaySection(),
                    const SizedBox(height: 20),
                    // ── Soru Çözümleri ──
                    Text('Soru Çözümleri',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).textTheme.bodyLarge?.color)),
                    const SizedBox(height: 12),
                    if (filter == 'today')
                      distAsync.when(
                        data: (list) => _LessonDistribution(items: list),
                        loading: () => const _DistSkeleton(),
                        error: (e, st) => _LessonDistribution(items: const []),
                      )
                    else
                      const _QuestionsByDaySection(),
                    // Alt nav bar + safe area + FAB boşluğu — son içerik kapanmasın
                    SizedBox(height: 100 + MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Note FAB (bottom-left via Stack)
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: _NoteFab(onTap: _openNote),
    );
  }

  void _openNote() {
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

  /// "Tüm Zamanlar" tıklandığında kullanıcıya kapsam soran sheet.
  /// Yeni program oluşturulduktan sonra her tıklamada açılır.
  void _showAllScopePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hangi Aralıkta Göstereyim?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'Mevcut programın istatistikleri ile başlangıçtan bu yana toplamı arasında seç.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              _ScopeChoice(
                emoji: '📅',
                title: 'Mevcut Program İstatistikleri',
                subtitle: 'Sadece şu anki 7 günlük programının kayıtları.',
                accent: AppColors.primary,
                onTap: () {
                  ref.read(activeAllScopeProvider.notifier).state = 'current';
                  ref.read(activeFilterProvider.notifier).state = 'all';
                  Navigator.of(sheetCtx).pop();
                },
              ),
              const SizedBox(height: 10),
              _ScopeChoice(
                emoji: '🌐',
                title: 'Bütün Zamanların İstatistikleri',
                subtitle:
                    'Uygulamayı kullanmaya başladığından bu yana toplam.',
                accent: Colors.grey.shade600,
                onTap: () {
                  ref.read(activeAllScopeProvider.notifier).state = 'total';
                  ref.read(activeFilterProvider.notifier).state = 'all';
                  Navigator.of(sheetCtx).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScopeChoice extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _ScopeChoice({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.5), width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: accent)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── XP Header ────────────────────────────────────────────────────────────────

class _XpHeader extends StatelessWidget {
  final XpInfo xp;
  final int localCompletedToday;
  const _XpHeader({required this.xp, this.localCompletedToday = 0});

  // Soru çözümü VEYA tamamlanan ders → bugün aktif.
  int get _effectiveStreak {
    final backendCountsToday = xp.streakDays > xp.streakBeforeToday;
    final todayActive = backendCountsToday || localCompletedToday > 0;
    return todayActive ? xp.streakBeforeToday + 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          // XP + streak badge'leri — sol üst köşe
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Badge(
                  text: '${xp.totalXP} XP',
                  bg: const Color(0xFFFBBF24),
                  textColor: Colors.black87),
              if (_effectiveStreak > 0) ...[
                const SizedBox(height: 6),
                _Badge(
                    text: '🔥 $_effectiveStreak Gün',
                    bg: Colors.white.withValues(alpha: 0.25)),
              ],
            ],
          ),
          // Ortalı içerik
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 4),
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(xp.levelEmoji,
                      style: const TextStyle(fontSize: 30)),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                xp.levelName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '🎯 Toplam ${xp.totalQuestions} Soru Çözüldü',
                style: const TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              // XP progress bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${xp.currentLevelXP} XP',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11)),
                  Text('${xp.nextLevelXP} XP',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: xp.progressFraction,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFBBF24)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color textColor;

  const _Badge(
      {required this.text,
      required this.bg,
      this.textColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 13)),
    );
  }
}

class _XpHeaderSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF059669),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
    );
  }
}

// ─── Stats Grid ───────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final GelisimimStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _CardData(
        label: 'Tamamlanan',
        value: stats.completedTasks,
        unit: 'oturum',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      ),
      _CardData(
        label: 'Toplam Süre',
        value: stats.totalMinutes,
        unit: _fmtMin(stats.totalMinutes),
        icon: Icons.timer_rounded,
        color: AppColors.warning,
        isTime: true,
      ),
      _CardData(
        label: 'Çözülen Soru',
        value: stats.totalQuestions,
        unit: 'soru',
        icon: Icons.description_rounded,
        color: AppColors.error,
      ),
      _CardData(
        label: 'Dinlenme',
        value: stats.restDays,
        unit: 'gün',
        icon: Icons.hotel_rounded,
        color: const Color(0xFF14B8A6),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: cards.map((c) => _StatCard(data: c)).toList(),
    );
  }

  static String _fmtMin(int m) {
    if (m < 60) return '${m}dk';
    final h = m ~/ 60;
    final rem = m % 60;
    return rem > 0 ? '${h}s ${rem}dk' : '${h}s';
  }
}

class _CardData {
  final String label;
  final int value;
  final String unit;
  final IconData icon;
  final Color color;
  final bool isTime;

  const _CardData({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.isTime = false,
  });
}

class _StatCard extends StatelessWidget {
  final _CardData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final displayValue = data.isTime ? data.unit : '${data.value}';
    final displayUnit = data.isTime ? '' : data.unit;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: data.color),
            ),
          ),
          const SizedBox(height: 8),
          Icon(data.icon, color: data.color, size: 28),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              displayUnit.isEmpty
                  ? displayValue
                  : '$displayValue $displayUnit',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGridSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: List.generate(
          4,
          (_) => Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
              )),
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends ConsumerWidget {
  final VoidCallback onNote;
  const _ActionButtons({required this.onNote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xp = ref.watch(xpInfoProvider).valueOrNull;
    final localStats = ref.watch(localTodayStatsProvider);

    // Bugün soru çözümü VEYA tamamlanan ders varsa streak'i göster.
    int effectiveStreak() {
      if (xp == null) return 0;
      final backendCountsToday = xp.streakDays > xp.streakBeforeToday;
      final todayActive = backendCountsToday || localStats.completedTasks > 0;
      return todayActive ? xp.streakBeforeToday + 1 : 0;
    }
    final streak = effectiveStreak();

    return IntrinsicHeight(
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Soru Gelişimi (orange, left)
        Expanded(
          child: ElevatedButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useRootNavigator: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const SoruGelisimiSheet(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Row(
              children: [
                const Icon(Icons.edit_note_rounded,
                    color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Soru Gelişimi',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      const Text('Bugün kaç soru çözdün?',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Geçmişi Gör (light purple, right)
        Expanded(
          child: ElevatedButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useRootNavigator: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const GecmisiGorCalendar(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              elevation: 0,
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded,
                    color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Geçmişi Gör',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.primary)),
                      Text(
                        streak > 0
                            ? '$streak günlük seri'
                            : 'Takvimi incele',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ));
  }
}

// ─── Filter Toggle ────────────────────────────────────────────────────────────

class _FilterToggle extends StatelessWidget {
  final String selected;
  final String allScope;
  final bool weeklyHistoryOn;
  final ValueChanged<String> onChanged;

  const _FilterToggle({
    required this.selected,
    required this.allScope,
    required this.weeklyHistoryOn,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final allLabel = (selected == 'all' && weeklyHistoryOn)
        ? (allScope == 'current'
            ? 'Tüm Zamanlar · Mevcut Program'
            : 'Tüm Zamanlar · Hepsi')
        : 'Tüm Zamanlar';
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _Btn(
              label: 'Bugün',
              active: selected == 'today',
              onTap: () => onChanged('today')),
          _Btn(
              label: allLabel,
              active: selected == 'all',
              onTap: () => onChanged('all')),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Btn(
      {required this.label,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active
                  ? Colors.white
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Lesson Distribution ──────────────────────────────────────────────────────

class _LessonDistribution extends StatelessWidget {
  final List<LessonDistribution> items;
  const _LessonDistribution({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: items.isEmpty
          ? Column(
              children: [
                Icon(Icons.pie_chart_outline_rounded,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text(
                  'Henüz tamamlanmış görev yok.',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Soru çözdükçe burada ders dağılımın görünecek!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textHint),
                ),
              ],
            )
          : Column(
              children: items
                  .map((item) => _DistRow(item: item,
                      max: items.first.totalQuestions))
                  .toList(),
            ),
    );
  }
}

class _DistRow extends StatelessWidget {
  final LessonDistribution item;
  final int max;

  const _DistRow({required this.item, required this.max});

  @override
  Widget build(BuildContext context) {
    final fraction =
        max > 0 ? item.totalQuestions / max : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(item.lessonName,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color)),
              ),
              Text('${item.totalQuestions} soru',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _DistSkeleton extends StatelessWidget {
  const _DistSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ─── Completed Lessons Section ────────────────────────────────────────────────

class _CompletedLessonsSection extends ConsumerWidget {
  const _CompletedLessonsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedIds = ref.watch(completedTaskIdsProvider);
    final tasksAsync = ref.watch(todayTasksProvider);
    final topicMap = ref.watch(topicAssignmentsProvider);
    final tasks = tasksAsync.value ?? [];
    final done = tasks
        .where((t) => !t.isMola && completedIds.contains(t.id))
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: done.isEmpty
          ? Column(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text(
                  'Henüz tamamlanan ders yok.',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Dersler tamamlandıkça burada görünecek!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            )
          : Column(
              children: done
                  .map((t) => _CompletedLessonRow(task: t, topicMap: topicMap))
                  .toList(),
            ),
    );
  }
}

class _CompletedLessonRow extends StatelessWidget {
  final StudyTask task;
  final Map<String, String> topicMap;

  const _CompletedLessonRow(
      {required this.task, required this.topicMap});

  static String _typeLabel(String type) {
    switch (type) {
      case 'konu_anlatimi': return 'Konu Anlatımı';
      case 'soru_cozumu':   return 'Soru Çözümü';
      case 'deneme':        return 'Deneme Sınavı';
      case 'tekrar':        return 'Tekrar';
      default:              return type;
    }
  }

  static Color _typeColor(String type) {
    switch (type) {
      case 'konu_anlatimi': return const Color(0xFF4F46E5);
      case 'soru_cozumu':   return const Color(0xFFF97316);
      case 'deneme':        return const Color(0xFFEF4444);
      case 'tekrar':        return const Color(0xFF10B981);
      default:              return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topicName = task.topicName ?? topicMap[task.id];
    final typeLabel = _typeLabel(task.taskType);
    final typeColor = _typeColor(task.taskType);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(task.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(task.subjectName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(typeLabel,
                          style: TextStyle(
                              fontSize: 10,
                              color: typeColor,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                if (topicName != null) ...[
                  const SizedBox(height: 2),
                  Text(topicName,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${task.durationMinutes} dk',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Note FAB ────────────────────────────────────────────────────────────────

class _NoteFab extends StatelessWidget {
  final VoidCallback onTap;
  const _NoteFab({required this.onTap});

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
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 8)
          ],
        ),
        child: const Icon(Icons.edit_note_rounded,
            color: Colors.white, size: 28),
      ),
    );
  }
}

// ─── Tüm Zamanlar: günlere göre tamamlanan dersler ───────────────────────────

class _CompletedLessonsByDaySection extends ConsumerWidget {
  const _CompletedLessonsByDaySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(completedLessonsByDayProvider);
    final weeklyOn = ref.watch(weeklyHistoryEnabledProvider).value ?? false;
    final planAsync = ref.watch(studyPlanProvider);
    final planStart = planAsync.maybeWhen(
      data: (p) => p.isNotEmpty
          ? DateTime(p.first.date.year, p.first.date.month, p.first.date.day)
          : null,
      orElse: () => null,
    );
    return daysAsync.when(
      loading: () => Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (days) {
        if (days.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text('Henüz tamamlanan ders yok.',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        final todayStr = _todayStr();
        Widget renderDay(CompletedLessonByDay entry) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DayHeaderChip(
                    date: entry.date,
                    todayStr: todayStr,
                    count: entry.lessons.length,
                    suffix: 'ders'),
                const SizedBox(height: 8),
                ...entry.lessons.map((l) => _SimpleLessonRow(lesson: l)),
                const SizedBox(height: 14),
              ],
            );

        if (!weeklyOn || planStart == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: days.map(renderDay).toList(),
            ),
          );
        }

        // Haftalık gruplama
        final buckets = <String, List<CompletedLessonByDay>>{};
        for (final e in days) {
          final wk = _weekStartFor(planStart, e.date);
          buckets.putIfAbsent(wk, () => []).add(e);
        }
        final currentWeek = _ymd(planStart);
        final sortedKeys = buckets.keys.toList()
          ..sort((a, b) => b.compareTo(a));
        return Column(
          children: sortedKeys.map((wk) {
            final dayList = buckets[wk]!;
            final totalLessons =
                dayList.fold<int>(0, (s, e) => s + e.lessons.length);
            final isCurrent = wk == currentWeek;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _WeekAccordion(
                title: isCurrent ? 'Bu Hafta' : _weekRangeLabel(wk),
                subtitle: '$totalLessons ders',
                defaultOpen: isCurrent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: dayList.map(renderDay).toList(),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SimpleLessonRow extends StatelessWidget {
  final CompletedLessonRecord lesson;
  const _SimpleLessonRow({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lesson.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.topicName != null
                      ? '${lesson.subjectName} — ${lesson.topicName}'
                      : lesson.subjectName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(_typeLabel(lesson.taskType),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('${lesson.durationMinutes} dk',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  static String _typeLabel(String t) {
    switch (t) {
      case 'konu_anlatimi': return 'Konu Anlatımı';
      case 'soru_cozumu': return 'Soru Çözümü';
      case 'deneme': return 'Deneme Sınavı';
      case 'tekrar': return 'Tekrar';
      default: return t;
    }
  }
}

// ─── Tüm Zamanlar: günlere göre soru çözümleri ────────────────────────────

class _QuestionsByDaySection extends ConsumerWidget {
  const _QuestionsByDaySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(questionsByDayProvider);
    final weeklyOn = ref.watch(weeklyHistoryEnabledProvider).value ?? false;
    final planAsync = ref.watch(studyPlanProvider);
    final planStart = planAsync.maybeWhen(
      data: (p) => p.isNotEmpty
          ? DateTime(p.first.date.year, p.first.date.month, p.first.date.day)
          : null,
      orElse: () => null,
    );
    return daysAsync.when(
      loading: () => Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (days) {
        if (days.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.pie_chart_outline_rounded,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text('Henüz çözülen soru yok.',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        final todayStr = _todayStr();
        Widget renderDay(QuestionsByDay entry) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DayHeaderChip(
                    date: entry.date,
                    todayStr: todayStr,
                    count:
                        entry.questions.fold<int>(0, (s, q) => s + q.count),
                    suffix: 'soru'),
                const SizedBox(height: 8),
                ..._sortedQ(entry.questions, (q) => q.count, descending: true)
                    .map((q) => _DistRow(
                          item: LessonDistribution(
                              lessonName: q.subjectName,
                              totalQuestions: q.count),
                          max: _maxCount(entry.questions),
                        )),
                const SizedBox(height: 14),
              ],
            );

        if (!weeklyOn || planStart == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: days.map(renderDay).toList(),
            ),
          );
        }

        // Haftalık gruplama
        final buckets = <String, List<QuestionsByDay>>{};
        for (final e in days) {
          final wk = _weekStartFor(planStart, e.date);
          buckets.putIfAbsent(wk, () => []).add(e);
        }
        final currentWeek = _ymd(planStart);
        final sortedKeys = buckets.keys.toList()
          ..sort((a, b) => b.compareTo(a));
        return Column(
          children: sortedKeys.map((wk) {
            final dayList = buckets[wk]!;
            final totalQ = dayList.fold<int>(
                0,
                (s, e) =>
                    s + e.questions.fold<int>(0, (q, qq) => q + qq.count));
            final isCurrent = wk == currentWeek;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _WeekAccordion(
                title: isCurrent ? 'Bu Hafta' : _weekRangeLabel(wk),
                subtitle: '$totalQ soru',
                defaultOpen: isCurrent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: dayList.map(renderDay).toList(),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  static int _maxCount(List<DailyQuestion> list) =>
      list.isEmpty ? 1 : list.map((q) => q.count).reduce((a, b) => a > b ? a : b);

  static List<DailyQuestion> _sortedQ(
      List<DailyQuestion> list, int Function(DailyQuestion) k,
      {bool descending = false}) {
    final out = [...list];
    out.sort((a, b) => descending ? k(b) - k(a) : k(a) - k(b));
    return out;
  }
}

// ─── Gün başlık chip'i ───────────────────────────────────────────────────────

class _DayHeaderChip extends StatelessWidget {
  final String date; // YYYY-MM-DD
  final String todayStr;
  final int count;
  final String suffix;

  const _DayHeaderChip({
    required this.date,
    required this.todayStr,
    required this.count,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final label = date == todayStr ? 'Bugün' : _formatTr(date);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
          ),
          const SizedBox(width: 8),
          Text('$count $suffix',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textHint)),
        ],
      ),
    );
  }

  static const _months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];
  static const _weekdays = [
    'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'
  ];

  static String _formatTr(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day} ${_months[d.month - 1]} ${_weekdays[d.weekday - 1]}';
    } catch (_) {
      return iso;
    }
  }
}

String _todayStr() {
  final d = DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Verilen tarih dizesini, [planStart] referans alınarak ait olduğu haftanın
/// başlangıç tarihine (YYYY-MM-DD) çevirir. Mevcut hafta: planStart..+6.
String _weekStartFor(DateTime planStart, String dateStr) {
  final d = DateTime.parse(dateStr);
  final day = DateTime(d.year, d.month, d.day);
  final diffDays = day.difference(planStart).inDays;
  final weekIndex = (diffDays / 7).floor();
  final ws = planStart.add(Duration(days: weekIndex * 7));
  return _ymd(ws);
}

String _weekRangeLabel(String weekStartStr) {
  final s = DateTime.parse(weekStartStr);
  final e = s.add(const Duration(days: 6));
  const months = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];
  return '${s.day} ${months[s.month - 1]} – ${e.day} ${months[e.month - 1]}';
}

class _WeekAccordion extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool defaultOpen;
  final Widget child;
  const _WeekAccordion({
    required this.title,
    required this.subtitle,
    required this.defaultOpen,
    required this.child,
  });

  @override
  State<_WeekAccordion> createState() => _WeekAccordionState();
}

class _WeekAccordionState extends State<_WeekAccordion> {
  late bool _open;

  @override
  void initState() {
    super.initState();
    _open = widget.defaultOpen;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                  ),
                  Text(widget.subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textHint)),
                  const SizedBox(width: 8),
                  Icon(_open ? Icons.expand_less : Icons.expand_more,
                      size: 20, color: AppColors.textHint),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}
