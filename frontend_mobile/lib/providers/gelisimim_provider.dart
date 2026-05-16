import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject_data.dart';
import '../services/gelisimim_service.dart';
import '../services/token_service.dart';
import 'study_plan_provider.dart';

final _service = GelisimimService();

final activeFilterProvider = StateProvider<String>((ref) => 'all');

// Canlı (local) istatistikler — completedTaskIds + restDaysProvider'dan türetilir
final localTodayStatsProvider = Provider<GelisimimStats>((ref) {
  final completedIds = ref.watch(completedTaskIdsProvider);
  final tasksAsync = ref.watch(todayTasksProvider);
  final restDays = ref.watch(restDaysProvider);

  final tasks = tasksAsync.value ?? [];
  final completedNonMola = tasks
      .where((t) => !t.isMola && completedIds.contains(t.id))
      .toList();

  return GelisimimStats(
    completedTasks: completedNonMola.length,
    totalMinutes: completedNonMola.fold(0, (s, t) => s + t.durationMinutes),
    totalQuestions: 0, // backend'den gelecek
    restDays: restDays,
  );
});

// Lokal tamamlanan ders başına 10 XP
final localXpBoostProvider = Provider<int>((ref) {
  final local = ref.watch(localTodayStatsProvider);
  return local.completedTasks * 10;
});

// Backend XpInfo'yu lokal XP ile günceller, seviye geçişlerini yeniden hesaplar
XpInfo applyXpBoost(XpInfo base, int boost) {
  final total = base.totalXP + boost;
  final String levelName;
  final String levelEmoji;
  final int curLvl;
  final int nextLvl;

  if (total <= 2000) {
    levelName = 'Çırak Öğrenci'; levelEmoji = '🌱';
    curLvl = 0; nextLvl = 2000;
  } else if (total <= 5000) {
    levelName = 'Acemi Öğrenci'; levelEmoji = '📖';
    curLvl = 2000; nextLvl = 5000;
  } else if (total <= 10000) {
    levelName = 'Gelişen Öğrenci'; levelEmoji = '📚';
    curLvl = 5000; nextLvl = 10000;
  } else {
    levelName = 'Uzman Öğrenci'; levelEmoji = '🎓';
    curLvl = 10000; nextLvl = 20000;
  }

  return XpInfo(
    totalXP: total,
    currentLevelXP: curLvl,
    nextLevelXP: nextLvl,
    levelName: levelName,
    levelEmoji: levelEmoji,
    streakDays: base.streakDays,
    totalQuestions: base.totalQuestions,
  );
}

final gelisimimStatsProvider =
    FutureProvider.family<GelisimimStats, String>((ref, filter) async {
  return _service.getStats(filter);
});

String _subjectKey(String name) => name
    .toLowerCase()
    .replaceAll(' ', '_')
    .replaceAll('/', '_')
    .replaceAll('-', '_')
    .replaceAll('.', '');

final questionSubjectsProvider =
    FutureProvider<List<SubjectEntry>>((ref) async {
  final data = await ref.watch(onboardingDataProvider.future);
  final baseSubjects = data == null
      ? <SubjectData>[]
      : getSubjectsForExam(data.targetExam, data.selectedArea);

  // Merge custom subjects not already in base pool
  final baseNames = baseSubjects.map((s) => s.name).toSet();
  final extraSubjects = (data?.customSubjects ?? [])
      .where((n) => !baseNames.contains(n))
      .map((n) => SubjectData(name: n, emoji: '📝'))
      .toList();
  final subjects = [...baseSubjects, ...extraSubjects];

  // Fetch today's saved counts from backend to pre-fill existing entries
  final todayStr = DateTime.now().toIso8601String().substring(0, 10);
  List<DailyQuestion> todayCounts = [];
  try {
    final report = await _service.getDailyReport(todayStr);
    todayCounts = report.questions;
  } catch (_) {}

  return subjects.map((s) {
    final match = todayCounts.firstWhere(
      (q) => q.subjectName == s.name,
      orElse: () => const DailyQuestion(subjectName: '', count: 0),
    );
    return SubjectEntry(
      key: _subjectKey(s.name),
      name: s.name,
      icon: s.emoji,
      todayCount: match.count,
    );
  }).toList();
});

final calendarActiveDaysProvider = StateProvider<List<String>>((ref) => []);

final xpInfoProvider = FutureProvider<XpInfo>((ref) async {
  return _service.getXpInfo();
});

final lessonDistributionProvider =
    FutureProvider.family<List<LessonDistribution>, String>((ref, filter) async {
  return _service.getLessonDistribution(filter);
});

// Tüm zamanlar için local birikimli istatistikler
// SharedPreferences'taki tüm 'completed_tasks_{userId}_{date}' key'lerini tarar
// ve planla eşleşen görevlerin dk toplamını hesaplar
final localAllTimeStatsProvider = FutureProvider<({int completedTasks, int totalMinutes})>((ref) async {
  final userId = await TokenService.getUserId();
  if (userId == null) return (completedTasks: 0, totalMinutes: 0);
  final prefs = await SharedPreferences.getInstance();

  final prefix = 'completed_tasks_${userId}_';
  final allKeys = prefs.getKeys().where((k) => k.startsWith(prefix));

  // Bugünün key'ini çıkar — bunlar zaten localTodayStatsProvider'dan geliyor
  final today = DateTime.now();
  final todayKey =
      'completed_tasks_${userId}_${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  int totalCompleted = 0;
  int totalMinutes = 0;

  // Haftalık plandan block sürelerini almak için planı oku
  final planAsync = ref.read(studyPlanProvider);
  final plan = planAsync.value ?? [];

  // Tüm plan bloklarını id → durationMinutes olarak map'le
  final blockDurations = <String, int>{};
  for (final day in plan) {
    for (final block in day.blocks) {
      if (!block.isMola) {
        blockDurations[block.id] = block.durationMinutes;
      }
    }
  }

  for (final key in allKeys) {
    if (key == todayKey) continue; // bugünkü zaten localTodayStats'ta

    final ids = prefs.getStringList(key) ?? [];
    totalCompleted += ids.length;

    for (final id in ids) {
      // ID'yi plan bloklarında ara; bulamazsa sabit 60 dk varsay
      final dur = blockDurations[id];
      if (dur != null) {
        totalMinutes += dur;
      } else {
        // manuel görev veya plan dışı: StudyTask'tan id prefix'iyle tahmin et
        // 's_' → strong (~40 dk), 'w_' → weak (~60 dk), 'm_' → manual (~60 dk)
        if (id.startsWith('s_')) {
          totalMinutes += 40;
        } else {
          totalMinutes += 60;
        }
      }
    }
  }

  return (completedTasks: totalCompleted, totalMinutes: totalMinutes);
});
