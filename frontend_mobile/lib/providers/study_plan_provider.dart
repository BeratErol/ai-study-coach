import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/onboarding_data.dart';
import '../models/quick_note.dart';
import '../models/study_plan.dart';
import '../models/study_task.dart';
import '../services/api_service.dart';
import '../services/app_state_service.dart';
import '../services/study_plan_generator.dart';
import '../services/token_service.dart';
import '../services/user_prefs_service.dart';
import 'gelisimim_provider.dart';

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

// Web ile ortak format: user_{userId}_weekly_plan
String _weeklyPlanKey(String userId) => 'user_${userId}_weekly_plan';

/// Kaydedilmiş planı sil ve studyPlanProvider'ı yeniden oluşturmaya zorla.
Future<void> resetStudyPlan(WidgetRef ref, String userId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_weeklyPlanKey(userId));
  ref.invalidate(studyPlanProvider);
}

/// "Etkin gün" — gece kuşu için sabah 04:00'a kadar dünden say (web ile aynı).
DateTime _effectiveTodayForPlan() {
  final now = DateTime.now();
  if (now.hour < 4) {
    final y = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    return y;
  }
  return DateTime(now.year, now.month, now.day);
}

/// Plan süresi doldu mu? Son gün etkin günden küçükse evet.
bool isPlanExpired(List<StudyDay> plan) {
  if (plan.isEmpty) return false;
  final last = plan.last.date;
  final lastDay = DateTime(last.year, last.month, last.day);
  return _effectiveTodayForPlan().isAfter(lastDay);
}

/// Yeni 7 günlük plan üretir + onboarding patch'iyle birlikte saklar.
/// Web'in `generateAndStorePlan` muadili.
Future<void> regenerateStudyPlan(
  WidgetRef ref, {
  OnboardingData? overrideOnboarding,
}) async {
  final userId = await TokenService.getUserId();
  if (userId == null) return;
  OnboardingData data;
  if (overrideOnboarding != null) {
    data = overrideOnboarding;
    await UserPrefsService.saveOnboardingData(userId, data.toJson());
  } else {
    final raw = await UserPrefsService.getOnboardingData(userId);
    if (raw == null) return;
    data = OnboardingData.fromJson(raw);
  }
  final prefs = await SharedPreferences.getInstance();
  // Mevcut planı önce arşive ekle — eski plan günlerinin blok/dinlenme
  // bilgisi "Geçmişi Gör" tarafından gerekli (web ile aynı mantık).
  final oldRaw = prefs.getString(_weeklyPlanKey(userId));
  if (oldRaw != null) {
    try {
      final oldList = (jsonDecode(oldRaw) as List).cast<dynamic>();
      final archiveKey = 'user_${userId}_weekly_plan_archive';
      final archiveRaw = prefs.getString(archiveKey);
      final archive = archiveRaw == null
          ? <dynamic>[]
          : (jsonDecode(archiveRaw) as List).cast<dynamic>();
      final knownDates = archive
          .map((e) => ((e as Map)['date'] as String?)?.substring(0, 10))
          .whereType<String>()
          .toSet();
      for (final d in oldList) {
        final dt = (d as Map)['date'] as String?;
        final k = dt?.substring(0, 10);
        if (k != null && !knownDates.contains(k)) {
          archive.add(d);
          knownDates.add(k);
        }
      }
      await prefs.setString(archiveKey, jsonEncode(archive));
      await AppStateService.pushAppState('weekly_plan_archive', archive);
    } catch (_) {}
  }
  final plan = StudyPlanGenerator.generateWeeklyPlan(data);
  final jsonList = plan.map((d) => d.toJson()).toList();
  await prefs.setString(_weeklyPlanKey(userId), jsonEncode(jsonList));
  await AppStateService.pushAppState('weekly_plan', jsonList);
  // İlk yenilemeden itibaren Gelişimim "Tüm Zamanlar" haftalık gruplamaya geçer.
  await prefs.setString(
      'user_${userId}_weekly_history_enabled', jsonEncode(true));
  await AppStateService.pushAppState('weekly_history_enabled', true);
  // Yeni plan id'leri farklı — bugünün tamamlama/atama kayıtları artık geçersiz.
  await ref.read(completedTaskIdsProvider.notifier).clearToday();
  ref.read(topicAssignmentsProvider.notifier).clearAll();
  ref.invalidate(studyPlanProvider);
  ref.invalidate(todayTasksProvider);
  ref.invalidate(onboardingDataProvider);
  ref.invalidate(weeklyHistoryEnabledProvider);
}

final studyPlanProvider = FutureProvider<List<StudyDay>>((ref) async {
  final userId = await TokenService.getUserId();
  if (userId == null) return [];
  final dataMap = await UserPrefsService.getOnboardingData(userId);
  if (dataMap == null) return [];
  final data = OnboardingData.fromJson(dataMap);

  final prefs = await SharedPreferences.getInstance();
  final key = _weeklyPlanKey(userId);

  // Kaydedilmiş plan var mı?
  final raw = prefs.getString(key);
  if (raw != null) {
    try {
      final list = jsonDecode(raw) as List;
      final stored = list
          .map((e) => StudyDay.fromJson(e as Map<String, dynamic>))
          .toList();

      if (stored.isNotEmpty) {
        // Kayıtlı plan ne olursa olsun döndür — mobil web ile senkron kalmak
        // için kendi planını ÜRETMEMELİDİR. Plan süresi dolduysa bile web
        // tarafının yeni planı push etmesi beklenir. Mobil'in plan üretmesi
        // sadece backend'de plan hiç yoksa (ilk onboarding) gerçekleşir.
        return stored;
      }
    } catch (_) {
      // Bozuk JSON: yeni plan üret
    }
  }

  // Yeni plan üret, hem cache'e hem backend'e yaz (web ile senkron olsun)
  final plan = StudyPlanGenerator.generateWeeklyPlan(data);
  final jsonList = plan.map((d) => d.toJson()).toList();
  await prefs.setString(key, jsonEncode(jsonList));
  await AppStateService.pushAppState('weekly_plan', jsonList);
  return plan;
});

// ── Sınav geri sayımı ──────────────────────────────────────────────────────

// Web ile aynı: gün farkı midnight-to-midnight hesaplanır (şu anki saat değil).
int? _daysUntil(DateTime examDate) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final exam = DateTime(examDate.year, examDate.month, examDate.day);
  final diff = exam.difference(today).inDays;
  return diff > 0 ? diff : null;
}

/// Sınav tarihinin bugüne göre durumu.
enum ExamPhase { upcoming, today, past, none }

class ExamStatus {
  final ExamPhase phase;
  final int daysLeft; // yalnızca upcoming için anlamlı
  const ExamStatus(this.phase, [this.daysLeft = 0]);
}

ExamStatus _examStatusFromDate(DateTime examDate) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final exam = DateTime(examDate.year, examDate.month, examDate.day);
  final diff = exam.difference(today).inDays;
  if (diff > 0) return ExamStatus(ExamPhase.upcoming, diff);
  if (diff == 0) return const ExamStatus(ExamPhase.today);
  return const ExamStatus(ExamPhase.past);
}

/// Sınav tarihini (geçmişse) sıfırlar: local cache + AppState + backend.
Future<void> _clearExamDate(String userId) async {
  final dataMap = await UserPrefsService.getOnboardingData(userId);
  if (dataMap == null) return;
  if ((dataMap['examDate'] as String?)?.isEmpty ?? true) return;
  dataMap['examDate'] = null;
  // saveOnboardingData içeride AppState'e de push eder.
  await UserPrefsService.saveOnboardingData(userId, dataMap);
  try {
    await ApiService().dio.post('/UserProfile', data: dataMap);
  } catch (_) {}
}

/// Dashboard için sınav durumu. Tek doğruluk kaynağı `onboarding_data.examDate`
/// — bu anahtar AppState ile senkronlu olduğundan web'de profilden yapılan
/// değişiklik hydrate sonrası buraya yansır. (Eski `sinav_tarihi` anahtarı stale
/// kalabildiği için artık kullanılmıyor.) Tarih geçmişse otomatik sıfırlar.
final examStatusProvider = FutureProvider<ExamStatus>((ref) async {
  final userId = await TokenService.getUserId();
  if (userId == null) return const ExamStatus(ExamPhase.none);

  final dataMap = await UserPrefsService.getOnboardingData(userId);
  final s = dataMap?['examDate'] as String?;
  if (s == null || s.isEmpty) return const ExamStatus(ExamPhase.none);
  final examDate = DateTime.tryParse(s);
  if (examDate == null) return const ExamStatus(ExamPhase.none);

  final status = _examStatusFromDate(examDate);
  if (status.phase == ExamPhase.past) {
    await _clearExamDate(userId);
    return const ExamStatus(ExamPhase.none);
  }
  return status;
});

final examCountdownProvider = FutureProvider<int?>((ref) async {
  final userId = await TokenService.getUserId();
  if (userId == null) return null;

  // Kullanıcının kaydettiği sınav tarihi öncelikli
  final savedDate = await UserPrefsService.getExamDate(userId);
  if (savedDate != null) return _daysUntil(savedDate);

  // Backend'den taze veri dene
  try {
    final response = await ApiService().dio.get('/UserProfile');
    if (response.statusCode == 200 && response.data != null) {
      final examDateStr = response.data['examDate'] as String?;
      if (examDateStr != null && examDateStr.isNotEmpty) {
        final examDate = DateTime.parse(examDateStr);
        return _daysUntil(examDate);
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
  return _daysUntil(examDate);
});

// ── Sınav hedefi ───────────────────────────────────────────────────────────

final examGoalProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final userId = await TokenService.getUserId();
  if (userId == null) return {};
  return UserPrefsService.getExamGoal(userId);
});

// ── Manuel görevler ────────────────────────────────────────────────────────

class ManualTasksNotifier extends StateNotifier<List<StudyTask>> {
  // Web ile ortak format: user_{userId}_manual_tasks
  static String _key(String userId) => 'user_${userId}_manual_tasks';

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
    final jsonList = state.map((t) => t.toJson()).toList();
    await prefs.setString(_key(userId), jsonEncode(jsonList));
    // Backend senkronu (web ile ortak 'manual_tasks' anahtarı)
    await AppStateService.pushAppState('manual_tasks', jsonList);
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

  // Saatli görevler saate göre sıralı; saatsiz manuel görevler en sona.
  // "HH:MM" formatını dk'ya çevir; 04:00'dan küçükse ertesi günün gece saati
  // (gece kuşu programı) olarak +24 saat ekle ki 18:10 → 23:00 → 00:30 doğru
  // sırada gelsin.
  int sortKey(String hhmm) {
    final p = hhmm.split(':');
    if (p.length < 2) return 0;
    final h = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p[1]) ?? 0;
    final mins = h * 60 + m;
    return mins < 4 * 60 ? mins + 24 * 60 : mins;
  }

  final all = [...generated, ...manual];
  all.sort((a, b) {
    final aEmpty = a.startTime.isEmpty;
    final bEmpty = b.startTime.isEmpty;
    if (aEmpty && bEmpty) return 0;
    if (aEmpty) return 1;
    if (bEmpty) return -1;
    return sortKey(a.startTime).compareTo(sortKey(b.startTime));
  });
  return all;
});

// ── Tamamlanan görev id'leri (kalıcı: userId + tarih bazlı) ───────────────

class CompletedTasksNotifier extends StateNotifier<Set<String>> {
  final Ref? _ref;
  CompletedTasksNotifier([this._ref]) : super({}) {
    _load();
  }

  /// Streak hesabı `streakActiveDaysProvider` (FutureProvider) üzerinden gider.
  /// Bir tamamlama olduğunda o sağlayıcının cache'lediği veri eskir; bu helper
  /// çağrısıyla invalidate edilip yenisi çözülür.
  void _invalidateStreak() {
    _ref?.invalidate(streakActiveDaysProvider);
  }

  static String _todayDate() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  // Web ile ortak format: user_{userId}_completed_tasks_{date}
  static Future<String?> _key() async {
    final userId = await TokenService.getUserId();
    if (userId == null) return null;
    return 'user_${userId}_completed_tasks_${_todayDate()}';
  }

  static Future<String?> _lessonsKey() async {
    final userId = await TokenService.getUserId();
    if (userId == null) return null;
    return 'user_${userId}_completed_lessons_${_todayDate()}';
  }

  Future<void> _load() async {
    final key = await _key();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    // Web JSON dizisi olarak yazar; mobil eskiden StringList yazardı — ikisini de oku.
    final raw = prefs.getString(key);
    if (raw != null) {
      try {
        state = (jsonDecode(raw) as List).cast<String>().toSet();
        return;
      } catch (_) {}
    }
    final legacy = prefs.getStringList(key);
    if (legacy != null) state = legacy.toSet();
  }

  Future<void> _save() async {
    final key = await _key();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final list = state.toList();
    // JSON dizi olarak yaz (web ile aynı biçim)
    await prefs.setString(key, jsonEncode(list));
    await AppStateService.pushAppState('completed_tasks_${_todayDate()}', list);
  }

  /// Bir dersi tamamlandı olarak işaretler. [task] verilirse o günün
  /// `completed_lessons_{date}` listesine ders detayı (ad, emoji, tür, süre,
  /// konu) da yazılır — web ile aynı şema. Gelişimim Tüm Zamanlar bu kayda
  /// göre günlere göre listeler.
  void mark(String id, {StudyTask? task}) {
    state = {...state, id};
    _save();
    if (task != null && !task.isMola) {
      _saveLesson(task);
    }
    _invalidateStreak();
  }

  void unmark(String id) {
    state = {...state}..remove(id);
    _save();
    _removeLesson(id);
    _invalidateStreak();
  }

  void markAll(Set<String> ids) {
    state = ids;
    _save();
    _invalidateStreak();
  }

  /// Bugüne ait tüm tamamlanan görev id'lerini ve ders detaylarını siler.
  /// Program ders havuzu değiştiğinde çağrılır — eski id'ler yeni planla
  /// uyuşmaz, kayıt bırakılması yanıltıcı olur.
  Future<void> clearToday() async {
    state = <String>{};
    await _save();
    final lessonsKey = await _lessonsKey();
    if (lessonsKey != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(lessonsKey, jsonEncode(const []));
      await AppStateService.pushAppState(
          'completed_lessons_${_todayDate()}', const []);
    }
    _invalidateStreak();
  }

  Future<void> _saveLesson(StudyTask t) async {
    final key = await _lessonsKey();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    List<Map<String, dynamic>> list = [];
    if (raw != null) {
      try {
        list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      } catch (_) {}
    }
    if (list.any((e) => e['id'] == t.id)) return;
    list.add({
      'id': t.id,
      'subjectName': t.subjectName,
      'emoji': t.emoji,
      'taskType': t.taskType,
      'durationMinutes': t.durationMinutes,
      if (t.topicName != null) 'topicName': t.topicName,
    });
    await prefs.setString(key, jsonEncode(list));
    await AppStateService.pushAppState(
        'completed_lessons_${_todayDate()}', list);
  }

  Future<void> _removeLesson(String id) async {
    final key = await _lessonsKey();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .where((e) => e['id'] != id)
          .toList();
      await prefs.setString(key, jsonEncode(list));
      await AppStateService.pushAppState(
          'completed_lessons_${_todayDate()}', list);
    } catch (_) {}
  }
}

final completedTaskIdsProvider =
    StateNotifierProvider<CompletedTasksNotifier, Set<String>>(
  (ref) => CompletedTasksNotifier(ref),
);

// ── Dinlenme günleri — kullanıcının açıkça işaretlediği günler ───────────
// Web ile ortak format: user_{userId}_rest_days, ["YYYY-MM-DD", ...]
class RestDaysNotifier extends StateNotifier<List<String>> {
  RestDaysNotifier() : super([]) {
    _load();
  }

  static Future<String?> _key() async {
    final userId = await TokenService.getUserId();
    if (userId == null) return null;
    return 'user_${userId}_rest_days';
  }

  static String _today() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    final key = await _key();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return;
    try {
      state = (jsonDecode(raw) as List).cast<String>();
    } catch (_) {}
  }

  Future<void> _save() async {
    final key = await _key();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(state));
    await AppStateService.pushAppState('rest_days', state);
  }

  /// Bugünü dinlenme günü olarak işaretler (zaten varsa eklemez).
  Future<void> markToday() async {
    final t = _today();
    if (state.contains(t)) return;
    state = [...state, t];
    await _save();
  }

  /// Bugünden dinlenme işaretini kaldırır.
  Future<void> unmarkToday() async {
    final t = _today();
    state = state.where((d) => d != t).toList();
    await _save();
  }

  bool get isTodayRest => state.contains(_today());
}

final restDaysProvider =
    StateNotifierProvider<RestDaysNotifier, List<String>>(
  (ref) => RestDaysNotifier(),
);

// ── Konu atamaları (blockId → konu adı) — kalıcı ─────────────────────────

class TopicAssignmentsNotifier extends StateNotifier<Map<String, String>> {
  TopicAssignmentsNotifier() : super({}) {
    _load();
  }

  // Web ile ortak format: user_{userId}_topic_assignments
  static Future<String> _key() async {
    final userId = await TokenService.getUserId() ?? 'anonymous';
    return 'user_${userId}_topic_assignments';
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
    await AppStateService.pushAppState('topic_assignments', state);
  }

  void assign(String blockId, String topic) {
    state = {...state, blockId: topic};
    _save();
  }

  void remove(String blockId) {
    state = {...state}..remove(blockId);
    _save();
  }

  /// Tüm konu atamalarını temizler (örn. ders havuzu değiştiğinde).
  void clearAll() {
    state = {};
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

  // Web ile ortak format: user_{userId}_quick_notes
  static Future<String> _key() async {
    final userId = await TokenService.getUserId() ?? 'anonymous';
    return 'user_${userId}_quick_notes';
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

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = state.map((n) => n.toJson()).toList();
    await prefs.setString(await _key(), jsonEncode(jsonList));
    await AppStateService.pushAppState('quick_notes', jsonList);
  }

  Future<void> addNote(QuickNote note) async {
    state = [note, ...state];
    await _save();
  }

  Future<void> removeNote(String id) async {
    state = state.where((n) => n.id != id).toList();
    await _save();
  }
}

final quickNotesProvider =
    StateNotifierProvider<QuickNotesNotifier, List<QuickNote>>(
  (ref) => QuickNotesNotifier(),
);
