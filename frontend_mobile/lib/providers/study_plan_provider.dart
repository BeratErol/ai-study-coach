import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/onboarding_data.dart';
import '../models/quick_note.dart';
import '../models/study_plan.dart';
import '../models/study_task.dart';
import '../services/api_service.dart';
import '../services/study_plan_generator.dart';
import '../services/token_service.dart';
import '../services/user_prefs_service.dart';

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// ── Onboarding verisi ──────────────────────────────────────────────────────

final onboardingDataProvider = FutureProvider<OnboardingData?>((ref) async {
  final userId = await TokenService.getUserId();
  if (userId == null) { return null; }
  final dataMap = await UserPrefsService.getOnboardingData(userId);
  if (dataMap == null) { return null; }
  return OnboardingData.fromJson(dataMap);
});

// ── Haftalık plan ──────────────────────────────────────────────────────────

String _weeklyPlanKey(String userId) => 'weekly_plan_$userId';

/// Kaydedilmiş planı sil ve studyPlanProvider'ı yeniden oluşturmaya zorla.
Future<void> resetStudyPlan(WidgetRef ref, String userId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_weeklyPlanKey(userId));
  ref.invalidate(studyPlanProvider);
}

final studyPlanProvider = FutureProvider<List<StudyDay>>((ref) async {
  final userId = await TokenService.getUserId();
  if (userId == null) return [];
  final dataMap = await UserPrefsService.getOnboardingData(userId);
  if (dataMap == null) return [];
  final data = OnboardingData.fromJson(dataMap);

  final prefs = await SharedPreferences.getInstance();
  final key = _weeklyPlanKey(userId);
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);

  // Kaydedilmiş plan var mı?
  final raw = prefs.getString(key);
  if (raw != null) {
    try {
      final list = jsonDecode(raw) as List;
      final stored = list
          .map((e) => StudyDay.fromJson(e as Map<String, dynamic>))
          .toList();

      if (stored.isNotEmpty) {
        final startDate = DateTime(
          stored.first.date.year,
          stored.first.date.month,
          stored.first.date.day,
        );
        final endDate = startDate.add(const Duration(days: 6));

        if (!todayDate.isAfter(endDate)) {
          // Plan hâlâ geçerli: bugün ve sonrasındaki günleri döndür
          return stored
              .where((d) => !d.date
                  .isBefore(todayDate))
              .toList();
        }
        // Plan süresi dolmuş: yeni plan üret ve kaydet
      }
    } catch (_) {
      // Bozuk JSON: yeni plan üret
    }
  }

  // Yeni plan üret ve kaydet
  final plan = StudyPlanGenerator.generateWeeklyPlan(data);
  await prefs.setString(
      key, jsonEncode(plan.map((d) => d.toJson()).toList()));
  return plan;
});

// ── Sınav geri sayımı ──────────────────────────────────────────────────────

final examCountdownProvider = FutureProvider<int?>((ref) async {
  final userId = await TokenService.getUserId();
  if (userId == null) return null;

  // Kullanıcının kaydettiği sınav tarihi öncelikli
  final savedDate = await UserPrefsService.getExamDate(userId);
  if (savedDate != null) {
    final diff = savedDate.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : null;
  }

  // Backend'den taze veri dene
  try {
    final response = await ApiService().dio.get('/UserProfile');
    if (response.statusCode == 200 && response.data != null) {
      final examDateStr = response.data['examDate'] as String?;
      if (examDateStr != null && examDateStr.isNotEmpty) {
        final examDate = DateTime.parse(examDateStr);
        final diff = examDate.difference(DateTime.now()).inDays;
        return diff > 0 ? diff : null;
      }
      return null;
    }
  } catch (_) {
    // Backend'e ulaşılamazsa locale'e dön
  }

  // Fallback: locale onboarding verisi
  final dataMap = await UserPrefsService.getOnboardingData(userId);
  if (dataMap == null) return null;
  final examDateStr = dataMap['examDate'] as String?;
  if (examDateStr == null || examDateStr.isEmpty) return null;
  final examDate = DateTime.tryParse(examDateStr);
  if (examDate == null) return null;
  final diff = examDate.difference(DateTime.now()).inDays;
  return diff > 0 ? diff : null;
});

// ── Sınav hedefi ───────────────────────────────────────────────────────────

final examGoalProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final userId = await TokenService.getUserId();
  if (userId == null) return {};
  return UserPrefsService.getExamGoal(userId);
});

// ── Manuel görevler ────────────────────────────────────────────────────────

class ManualTasksNotifier extends StateNotifier<List<StudyTask>> {
  static String _key(String userId) => 'manual_tasks_$userId';

  ManualTasksNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final userId = await TokenService.getUserId() ?? 'anonymous';
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      state = list
          .map((e) => StudyTask.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _save() async {
    final userId = await TokenService.getUserId() ?? 'anonymous';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key(userId), jsonEncode(state.map((t) => t.toJson()).toList()));
  }

  void add(StudyTask task) {
    state = [...state, task];
    _save();
  }

  void remove(String id) {
    state = state.where((t) => t.id != id).toList();
    _save();
  }

  void clearForDate(DateTime date) {
    state = state
        .where((t) =>
            !(t.date.year == date.year &&
              t.date.month == date.month &&
              t.date.day == date.day))
        .toList();
    _save();
  }
}

final manualTasksProvider =
    StateNotifierProvider<ManualTasksNotifier, List<StudyTask>>(
  (ref) => ManualTasksNotifier(),
);

// ── Bugünün görevleri ──────────────────────────────────────────────────────

final todayTasksProvider = FutureProvider<List<StudyTask>>((ref) async {
  final plan = await ref.watch(studyPlanProvider.future);
  final manualTasks = ref.watch(manualTasksProvider);
  final today = DateTime.now();

  final todayDay = plan.firstWhere(
    (d) => _isSameDay(d.date, today),
    orElse: StudyDay.empty,
  );

  final generated = todayDay.blocks
      .map((b) => StudyTask.fromBlock(b, todayDay.date))
      .toList();

  final manual =
      manualTasks.where((t) => _isSameDay(t.date, today)).toList();

  final all = [...generated, ...manual];
  all.sort((a, b) => a.startTime.compareTo(b.startTime));
  return all;
});

// ── Tamamlanan görev id'leri (kalıcı: userId + tarih bazlı) ───────────────

class CompletedTasksNotifier extends StateNotifier<Set<String>> {
  CompletedTasksNotifier() : super({}) {
    _load();
  }

  static Future<String?> _key() async {
    final userId = await TokenService.getUserId();
    if (userId == null) return null;
    final d = DateTime.now();
    final date =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return 'completed_tasks_${userId}_$date';
  }

  Future<void> _load() async {
    final key = await _key();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(key);
    if (raw != null) state = raw.toSet();
  }

  Future<void> _save() async {
    final key = await _key();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, state.toList());
  }

  void mark(String id) {
    state = {...state, id};
    _save();
  }

  void unmark(String id) {
    state = {...state}..remove(id);
    _save();
  }

  void markAll(Set<String> ids) {
    state = ids;
    _save();
  }
}

final completedTaskIdsProvider =
    StateNotifierProvider<CompletedTasksNotifier, Set<String>>(
  (ref) => CompletedTasksNotifier(),
);

// ── Dinlenme günü sayacı (local, today filter için) ────────────────────────

final restDaysProvider = StateProvider<int>((ref) => 0);

// ── Konu atamaları (blockId → konu adı) — kalıcı ─────────────────────────

class TopicAssignmentsNotifier extends StateNotifier<Map<String, String>> {
  TopicAssignmentsNotifier() : super({}) {
    _load();
  }

  static Future<String> _key() async {
    final userId = await TokenService.getUserId() ?? 'anonymous';
    return 'topic_assignments_$userId';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(await _key());
    if (raw != null) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      state = map.cast<String, String>();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(await _key(), jsonEncode(state));
  }

  void assign(String blockId, String topic) {
    state = {...state, blockId: topic};
    _save();
  }

  void remove(String blockId) {
    state = {...state}..remove(blockId);
    _save();
  }
}

final topicAssignmentsProvider =
    StateNotifierProvider<TopicAssignmentsNotifier, Map<String, String>>(
  (ref) => TopicAssignmentsNotifier(),
);

// ── Hızlı notlar ──────────────────────────────────────────────────────────

class QuickNotesNotifier extends StateNotifier<List<QuickNote>> {
  QuickNotesNotifier() : super([]) {
    _load();
  }

  static Future<String> _key() async {
    final userId = await TokenService.getUserId() ?? 'anonymous';
    return 'quick_notes_$userId';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(await _key());
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      state = list
          .map((e) => QuickNote.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> addNote(QuickNote note) async {
    state = [note, ...state];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        await _key(), jsonEncode(state.map((n) => n.toJson()).toList()));
  }

  Future<void> removeNote(String id) async {
    state = state.where((n) => n.id != id).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        await _key(), jsonEncode(state.map((n) => n.toJson()).toList()));
  }
}

final quickNotesProvider =
    StateNotifierProvider<QuickNotesNotifier, List<QuickNote>>(
  (ref) => QuickNotesNotifier(),
);
