import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject_data.dart';
import '../services/gelisimim_service.dart';
import '../services/token_service.dart';
import 'study_plan_provider.dart';

final _service = GelisimimService();

// Gelişimim sekmesi açıldığında varsayılan filtre 'Bugün' (webdeki gibi).
final activeFilterProvider = StateProvider<String>((ref) => 'today');

/// "all" modunda kapsam: 'current' = sadece mevcut program penceresi,
/// 'total' = uygulama kullanımının tamamı. Yeni program oluşturulduğunda
/// "Tüm Zamanlar" tıklanınca kullanıcıya sorulur.
final activeAllScopeProvider = StateProvider<String>((ref) => 'total');

// Canlı (local) istatistikler — completedTaskIds + restDaysProvider'dan türetilir
final localTodayStatsProvider = Provider<GelisimimStats>((ref) {
  final completedIds = ref.watch(completedTaskIdsProvider);
  final tasksAsync = ref.watch(todayTasksProvider);
  final restDays = ref.watch(restDaysProvider); // List<String> YYYY-MM-DD

  final tasks = tasksAsync.value ?? [];
  final completedNonMola = tasks
      .where((t) => !t.isMola && completedIds.contains(t.id))
      .toList();

  final today = DateTime.now();
  final todayStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  final isRestToday = restDays.contains(todayStr);

  return GelisimimStats(
    completedTasks: completedNonMola.length,
    totalMinutes: completedNonMola.fold(0, (s, t) => s + t.durationMinutes),
    totalQuestions: 0, // backend'den gelecek
    restDays: isRestToday ? 1 : 0,
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
    streakBeforeToday: base.streakBeforeToday,
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

// ── Tüm zamanlar: günlere göre tamamlanan ders detayları ─────────────────
// Web'deki getAllCompletedLessons karşılığı. SharedPreferences'taki
// 'user_{uid}_completed_lessons_{date}' anahtarlarını tarar.
class CompletedLessonByDay {
  final String date; // YYYY-MM-DD
  final List<CompletedLessonRecord> lessons;
  const CompletedLessonByDay({required this.date, required this.lessons});
}

class CompletedLessonRecord {
  final String id;
  final String subjectName;
  final String emoji;
  final String taskType;
  final int durationMinutes;
  final String? topicName;
  const CompletedLessonRecord({
    required this.id,
    required this.subjectName,
    required this.emoji,
    required this.taskType,
    required this.durationMinutes,
    this.topicName,
  });
  factory CompletedLessonRecord.fromJson(Map<String, dynamic> j) =>
      CompletedLessonRecord(
        id: j['id'] as String,
        subjectName: (j['subjectName'] as String?) ?? 'Tamamlanan Görev',
        emoji: (j['emoji'] as String?) ?? '✅',
        taskType: (j['taskType'] as String?) ?? 'konu_anlatimi',
        durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 60,
        topicName: j['topicName'] as String?,
      );
}

/// Streak için "çalışma günü" set'i: o gün mola DIŞINDA herhangi bir görev
/// (plan oturumu w_/s_ veya kullanıcının eklediği manuel görev) tamamlanmışsa
/// gün aktif sayılır. Yalnızca molalar (m_) hariç tutulur. Soru çözümü olan
/// günler ayrıca harmanlanır (questionsByDayProvider).
final streakActiveDaysProvider = FutureProvider<Set<String>>((ref) async {
  final userId = await TokenService.getUserId();
  if (userId == null) return <String>{};
  final prefs = await SharedPreferences.getInstance();
  final newPrefix = 'user_${userId}_completed_tasks_';
  final oldPrefix = 'completed_tasks_${userId}_';
  final days = <String>{};
  for (final key in prefs.getKeys()) {
    String? date;
    if (key.startsWith(newPrefix)) {
      date = key.substring(newPrefix.length);
    } else if (key.startsWith(oldPrefix)) {
      date = key.substring(oldPrefix.length);
    }
    if (date == null) continue;
    final raw = prefs.getString(key);
    List<String> ids;
    if (raw != null) {
      try {
        ids = (jsonDecode(raw) as List).cast<String>();
      } catch (_) {
        ids = [];
      }
    } else {
      ids = prefs.getStringList(key) ?? [];
    }
    // Mola dışında herhangi bir görev (plan w_/s_ veya manuel) çalışma sayılır.
    if (ids.any((id) => !id.startsWith('m_'))) {
      days.add(date);
    }
  }
  return days;
});

final completedLessonsByDayProvider =
    FutureProvider<List<CompletedLessonByDay>>((ref) async {
  final userId = await TokenService.getUserId();
  if (userId == null) return const [];
  final prefs = await SharedPreferences.getInstance();
  final prefix = 'user_${userId}_completed_lessons_';

  final byDate = <String, List<CompletedLessonRecord>>{};
  for (final key in prefs.getKeys()) {
    if (!key.startsWith(prefix)) continue;
    final date = key.substring(prefix.length);
    final raw = prefs.getString(key);
    if (raw == null) continue;
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => CompletedLessonRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      if (list.isNotEmpty) byDate[date] = list;
    } catch (_) {}
  }

  final entries = byDate.entries.toList()
    ..sort((a, b) => b.key.compareTo(a.key)); // tarih azalan
  return entries
      .map((e) => CompletedLessonByDay(date: e.key, lessons: e.value))
      .toList();
});

// ── Tüm zamanlar: günlere göre soru çözümleri ────────────────────────────
// Web'deki questionsByDay karşılığı. Son 2 ayın aktif günleri için
// daily-report çekip soru içeren günleri tarih azalan döndürür.
class QuestionsByDay {
  final String date;
  final List<DailyQuestion> questions;
  const QuestionsByDay({required this.date, required this.questions});
}

final questionsByDayProvider =
    FutureProvider<List<QuestionsByDay>>((ref) async {
  final now = DateTime.now();
  final dates = <String>{};
  for (int m = 0; m < 2; m++) {
    final d = DateTime(now.year, now.month - m, 1);
    try {
      final days = await _service.getCalendarActiveDays(d.year, d.month);
      dates.addAll(days);
    } catch (_) {}
  }
  final reports = await Future.wait(dates.map((date) async {
    try {
      final r = await _service.getDailyReport(date);
      return QuestionsByDay(date: date, questions: r.questions);
    } catch (_) {
      return QuestionsByDay(date: date, questions: const []);
    }
  }));
  final withQ = reports.where((r) => r.questions.isNotEmpty).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  return withQ;
});

// Kullanıcı en az 1 kez "Yeni Program Oluştur" akışını kullandıysa true.
// Gelişimim "Tüm Zamanlar" görünümü haftalık (collapsible) gruplama moduna geçer.
final weeklyHistoryEnabledProvider = FutureProvider<bool>((ref) async {
  final userId = await TokenService.getUserId();
  if (userId == null) return false;
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('user_${userId}_weekly_history_enabled');
  if (raw == null) return false;
  try { return jsonDecode(raw) == true; } catch (_) { return false; }
});

/// Mevcut planın başlangıç-bitiş tarih aralığı (YYYY-MM-DD, ymd string).
/// allScope == 'current' iken bu pencereye düşen kayıtlar sayılır.
({String? start, String? end}) _planWindow(List<dynamic> plan) {
  if (plan.isEmpty) return (start: null, end: null);
  String fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  final first = plan.first.date as DateTime;
  final last = plan.last.date as DateTime;
  return (start: fmt(first), end: fmt(last));
}

bool _dateInWindow(String date, String? start, String? end) {
  if (start == null || end == null) return true;
  return date.compareTo(start) >= 0 && date.compareTo(end) <= 0;
}

// Tüm zamanlar için local birikimli istatistikler
// SharedPreferences'taki tüm 'completed_tasks_{userId}_{date}' key'lerini tarar
// ve planla eşleşen görevlerin dk toplamını hesaplar
final localAllTimeStatsProvider = FutureProvider<({int completedTasks, int totalMinutes})>((ref) async {
  final userId = await TokenService.getUserId();
  if (userId == null) return (completedTasks: 0, totalMinutes: 0);
  final prefs = await SharedPreferences.getInstance();

  // Senkron katmanı key formatı: user_{userId}_completed_tasks_{YYYY-MM-DD}
  // (web ile ortak). Hem yeni hem eski (geriye dönük) prefix taranır.
  final newPrefix = 'user_${userId}_completed_tasks_';
  final oldPrefix = 'completed_tasks_${userId}_';
  final allKeys = prefs
      .getKeys()
      .where((k) => k.startsWith(newPrefix) || k.startsWith(oldPrefix))
      .toList();

  // Bugünün key'lerini çıkar — bunlar localTodayStats'tan geliyor
  final today = DateTime.now();
  final todayDate =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  final todayKeyNew = 'user_${userId}_completed_tasks_$todayDate';
  final todayKeyOld = 'completed_tasks_${userId}_$todayDate';

  int totalCompleted = 0;
  int totalMinutes = 0;

  // Plan + manuel görev sürelerini id → dk map'le (web ile aynı mantık).
  final planAsync = ref.read(studyPlanProvider);
  final plan = planAsync.value ?? [];
  final blockDurations = <String, int>{};
  for (final day in plan) {
    for (final block in day.blocks) {
      if (!block.isMola) blockDurations[block.id] = block.durationMinutes;
    }
  }
  // Manuel görev sürelerini de ekle — tamamlanmış manuel görev id'leri burada bulunur
  final manualRaw = prefs.getString('user_${userId}_manual_tasks');
  if (manualRaw != null) {
    try {
      for (final m in jsonDecode(manualRaw) as List) {
        final mm = m as Map<String, dynamic>;
        final id = mm['id'] as String?;
        final dur = (mm['durationMinutes'] as num?)?.toInt();
        if (id != null && dur != null) blockDurations[id] = dur;
      }
    } catch (_) {}
  }

  // Aynı tarih hem yeni hem eski formatta varsa çift saymamak için
  // tarih → id seti olarak topla.
  final byDate = <String, Set<String>>{};
  for (final key in allKeys) {
    if (key == todayKeyNew || key == todayKeyOld) continue;
    String date;
    if (key.startsWith(newPrefix)) {
      date = key.substring(newPrefix.length);
    } else {
      date = key.substring(oldPrefix.length);
    }
    // JSON dizi veya StringList olabilir
    final raw = prefs.getString(key);
    List<String> ids;
    if (raw != null) {
      try {
        ids = (jsonDecode(raw) as List).cast<String>();
      } catch (_) {
        ids = [];
      }
    } else {
      ids = prefs.getStringList(key) ?? [];
    }
    (byDate[date] ??= <String>{}).addAll(ids);
  }

  for (final ids in byDate.values) {
    for (final id in ids) {
      // 'm_' → mola; sayma
      if (id.startsWith('m_')) continue;
      totalCompleted += 1;
      final dur = blockDurations[id];
      if (dur != null) {
        totalMinutes += dur;
      } else {
        // Plan penceresinden çıkmış — web ile aynı tahmin: s_ → 30dk, diğer → 60dk
        totalMinutes += id.startsWith('s_') ? 30 : 60;
      }
    }
  }

  return (completedTasks: totalCompleted, totalMinutes: totalMinutes);
});

/// Mevcut plan penceresine düşen local birikim — "Mevcut Program" kapsamı.
/// localAllTimeStatsProvider ile aynı mantık; sadece tarih filtresi eklenir.
final currentPlanLocalStatsProvider =
    FutureProvider<({int completedTasks, int totalMinutes})>((ref) async {
  final userId = await TokenService.getUserId();
  if (userId == null) return (completedTasks: 0, totalMinutes: 0);
  final prefs = await SharedPreferences.getInstance();

  // Plan penceresi yoksa boş döner.
  final plan = ref.watch(studyPlanProvider).value ?? [];
  final window = _planWindow(plan);
  if (window.start == null || window.end == null) {
    return (completedTasks: 0, totalMinutes: 0);
  }

  final newPrefix = 'user_${userId}_completed_tasks_';
  final oldPrefix = 'completed_tasks_${userId}_';
  final allKeys = prefs
      .getKeys()
      .where((k) => k.startsWith(newPrefix) || k.startsWith(oldPrefix))
      .toList();

  final today = DateTime.now();
  final todayDate =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  final todayKeyNew = 'user_${userId}_completed_tasks_$todayDate';
  final todayKeyOld = 'completed_tasks_${userId}_$todayDate';

  final blockDurations = <String, int>{};
  for (final day in plan) {
    for (final block in day.blocks) {
      if (!block.isMola) blockDurations[block.id] = block.durationMinutes;
    }
  }
  final manualRaw = prefs.getString('user_${userId}_manual_tasks');
  if (manualRaw != null) {
    try {
      for (final m in jsonDecode(manualRaw) as List) {
        final mm = m as Map<String, dynamic>;
        final id = mm['id'] as String?;
        final dur = (mm['durationMinutes'] as num?)?.toInt();
        if (id != null && dur != null) blockDurations[id] = dur;
      }
    } catch (_) {}
  }

  final byDate = <String, Set<String>>{};
  for (final key in allKeys) {
    if (key == todayKeyNew || key == todayKeyOld) continue;
    final date = key.startsWith(newPrefix)
        ? key.substring(newPrefix.length)
        : key.substring(oldPrefix.length);
    if (!_dateInWindow(date, window.start, window.end)) continue;
    final raw = prefs.getString(key);
    List<String> ids;
    if (raw != null) {
      try {
        ids = (jsonDecode(raw) as List).cast<String>();
      } catch (_) {
        ids = [];
      }
    } else {
      ids = prefs.getStringList(key) ?? [];
    }
    (byDate[date] ??= <String>{}).addAll(ids);
  }

  int totalCompleted = 0;
  int totalMinutes = 0;
  for (final ids in byDate.values) {
    for (final id in ids) {
      if (id.startsWith('m_')) continue;
      totalCompleted += 1;
      final dur = blockDurations[id];
      totalMinutes += dur ?? (id.startsWith('s_') ? 30 : 60);
    }
  }
  return (completedTasks: totalCompleted, totalMinutes: totalMinutes);
});
