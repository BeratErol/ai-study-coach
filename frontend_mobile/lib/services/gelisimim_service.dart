import 'api_service.dart';

class GelisimimStats {
  final int completedTasks;
  final int totalMinutes;
  final int totalQuestions;
  final int restDays;

  const GelisimimStats({
    required this.completedTasks,
    required this.totalMinutes,
    required this.totalQuestions,
    required this.restDays,
  });

  factory GelisimimStats.fromJson(Map<String, dynamic> json) => GelisimimStats(
        completedTasks: json['completedTasks'] ?? 0,
        totalMinutes: json['totalMinutes'] ?? 0,
        totalQuestions: json['totalQuestions'] ?? 0,
        restDays: json['restDays'] ?? 0,
      );

  static const empty = GelisimimStats(
    completedTasks: 0,
    totalMinutes: 0,
    totalQuestions: 0,
    restDays: 0,
  );
}

class SubjectEntry {
  final String key;
  final String name;
  final String icon;
  final int todayCount;
  int pendingCount; // local edit state (not persisted until Save)

  SubjectEntry({
    required this.key,
    required this.name,
    required this.icon,
    required this.todayCount,
    this.pendingCount = 0,
  });

  factory SubjectEntry.fromJson(Map<String, dynamic> json) => SubjectEntry(
        key: json['key'] ?? '',
        name: json['name'] ?? '',
        icon: json['icon'] ?? '📚',
        todayCount: json['todayCount'] ?? 0,
      );

  int get effectiveCount => pendingCount > 0 ? pendingCount : todayCount;
  bool get hasData => effectiveCount > 0;
}

class DailyQuestion {
  final String subjectName;
  final int count;

  const DailyQuestion({required this.subjectName, required this.count});

  factory DailyQuestion.fromJson(Map<String, dynamic> json) => DailyQuestion(
        subjectName: json['subjectName'] ?? '',
        count: json['count'] ?? 0,
      );
}

class DailyTasks {
  final int completed;
  final int missed;
  final int totalMinutes;

  const DailyTasks({
    required this.completed,
    required this.missed,
    required this.totalMinutes,
  });

  factory DailyTasks.fromJson(Map<String, dynamic> json) => DailyTasks(
        completed: json['completed'] ?? 0,
        missed: json['missed'] ?? 0,
        totalMinutes: json['totalMinutes'] ?? 0,
      );
}

class DailyReport {
  final String date;
  final List<DailyQuestion> questions;
  final DailyTasks tasks;
  final bool isEmpty;

  const DailyReport({
    required this.date,
    required this.questions,
    required this.tasks,
    required this.isEmpty,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) => DailyReport(
        date: json['date'] ?? '',
        questions: (json['questions'] as List? ?? [])
            .map((e) => DailyQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
        tasks: DailyTasks.fromJson(
            (json['tasks'] as Map<String, dynamic>?) ?? {}),
        isEmpty: json['isEmpty'] ?? true,
      );
}

class XpInfo {
  final int totalXP;
  final int currentLevelXP;
  final int nextLevelXP;
  final String levelName;
  final String levelEmoji;
  final int streakDays;
  final int streakBeforeToday;
  final int totalQuestions;

  const XpInfo({
    required this.totalXP,
    required this.currentLevelXP,
    required this.nextLevelXP,
    required this.levelName,
    required this.levelEmoji,
    required this.streakDays,
    required this.streakBeforeToday,
    required this.totalQuestions,
  });

  factory XpInfo.fromJson(Map<String, dynamic> json) => XpInfo(
        totalXP: json['totalXP'] ?? 0,
        currentLevelXP: json['currentLevelXP'] ?? 0,
        nextLevelXP: json['nextLevelXP'] ?? 2000,
        levelName: json['levelName'] ?? 'Çırak Öğrenci',
        levelEmoji: json['levelEmoji'] ?? '🌱',
        streakDays: json['streakDays'] ?? 0,
        streakBeforeToday: json['streakBeforeToday'] ?? 0,
        totalQuestions: json['totalQuestions'] ?? 0,
      );

  static const empty = XpInfo(
    totalXP: 0,
    currentLevelXP: 0,
    nextLevelXP: 2000,
    levelName: 'Çırak Öğrenci',
    levelEmoji: '🌱',
    streakDays: 0,
    streakBeforeToday: 0,
    totalQuestions: 0,
  );

  double get progressFraction {
    final range = nextLevelXP - currentLevelXP;
    if (range <= 0) return 1.0;
    return ((totalXP - currentLevelXP) / range).clamp(0.0, 1.0);
  }
}

class LessonDistribution {
  final String lessonName;
  final int totalQuestions;

  const LessonDistribution(
      {required this.lessonName, required this.totalQuestions});

  factory LessonDistribution.fromJson(Map<String, dynamic> json) =>
      LessonDistribution(
        lessonName: json['lessonName'] ?? '',
        totalQuestions: json['totalQuestions'] ?? 0,
      );
}

class GelisimimService {
  final _api = ApiService();

  Future<GelisimimStats> getStats(String filter) async {
    final res = await _api.dio
        .get('/Gelisimim/stats', queryParameters: {'filter': filter});
    return GelisimimStats.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<SubjectEntry>> getQuestionSubjects() async {
    final res = await _api.dio.get('/Gelisimim/question-subjects');
    return (res.data as List)
        .map((e) => SubjectEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> saveQuestions(List<SubjectEntry> entries) async {
    final body = {
      'entries': entries
          .where((e) => e.pendingCount > 0)
          .map((e) => {
                'subjectKey': e.key,
                'subjectName': e.name,
                'count': e.pendingCount,
              })
          .toList(),
    };
    final res = await _api.dio.post('/Gelisimim/save-questions', data: body);
    return (res.data as Map<String, dynamic>)['totalToday'] ?? 0;
  }

  Future<List<String>> getCalendarActiveDays(int year, int month) async {
    final res = await _api.dio.get(
      '/Gelisimim/calendar',
      queryParameters: {'year': year, 'month': month},
    );
    return ((res.data as Map<String, dynamic>)['activeDays'] as List)
        .cast<String>();
  }

  Future<DailyReport> getDailyReport(String date) async {
    final res = await _api.dio
        .get('/Gelisimim/daily-report', queryParameters: {'date': date});
    return DailyReport.fromJson(res.data as Map<String, dynamic>);
  }

  Future<XpInfo> getXpInfo() async {
    final res = await _api.dio.get('/Gelisimim/xp-info');
    return XpInfo.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<LessonDistribution>> getLessonDistribution(String filter) async {
    final res = await _api.dio.get('/Gelisimim/lesson-distribution',
        queryParameters: {'filter': filter});
    return (res.data as List)
        .map((e) => LessonDistribution.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
