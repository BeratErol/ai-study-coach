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

final studyPlanProvider = FutureProvider<List<StudyDay>>((ref) async {
  final userId = await TokenService.getUserId();
  if (userId == null) { return []; }
  final dataMap = await UserPrefsService.getOnboardingData(userId);
  if (dataMap == null) { return []; }
  final data = OnboardingData.fromJson(dataMap);
  return StudyPlanGenerator.generateWeeklyPlan(data);
});

// ── Sınav geri sayımı ──────────────────────────────────────────────────────

final examCountdownProvider = FutureProvider<int?>((ref) async {
  final userId = await TokenService.getUserId();
  if (userId == null) return null;

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

// ── Tamamlanan görev id'leri ───────────────────────────────────────────────

final completedTaskIdsProvider = StateProvider<Set<String>>((ref) => {});

// ── Konu atamaları (ders adı → konu adı) ──────────────────────────────────

final topicAssignmentsProvider =
    StateProvider<Map<String, String>>((ref) => {});

// ── Hızlı notlar ──────────────────────────────────────────────────────────

class QuickNotesNotifier extends StateNotifier<List<QuickNote>> {
  QuickNotesNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('quick_notes');
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
        'quick_notes', jsonEncode(state.map((n) => n.toJson()).toList()));
  }

  Future<void> removeNote(String id) async {
    state = state.where((n) => n.id != id).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'quick_notes', jsonEncode(state.map((n) => n.toJson()).toList()));
  }
}

final quickNotesProvider =
    StateNotifierProvider<QuickNotesNotifier, List<QuickNote>>(
  (ref) => QuickNotesNotifier(),
);
