import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_state_service.dart';

class UserPrefsService {
  static String _key(String userId, String key) => 'user_${userId}_$key';

  static Future<bool> isOnboardingCompleted(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(userId, 'onboarding_completed')) ?? false;
  }

  static Future<void> setOnboardingCompleted(
      String userId, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(userId, 'onboarding_completed'), value);
  }

  static Future<void> saveOnboardingData(
      String userId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId, 'onboarding_data'), jsonEncode(data));
    await AppStateService.pushAppState('onboarding_data', data);
  }

  static Future<Map<String, dynamic>?> getOnboardingData(
      String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId, 'onboarding_data'));
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> clearUserData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId, 'onboarding_completed'));
    await prefs.remove(_key(userId, 'onboarding_data'));
    // Tamamlanan görev geçmişi — başka kullanıcıya sızmasın
    final taskKeys = prefs.getKeys()
        .where((k) => k.startsWith('completed_tasks_${userId}_'))
        .toList();
    for (final k in taskKeys) {
      await prefs.remove(k);
    }
    // Chatbot sohbetleri
    await prefs.remove('chatbot_conversations_$userId');
  }

  // Akademik hedef — web ile ortak tek-obje formatı: user_{userId}_exam_goal
  // { tytHedef, tytNet, aytHedef, aytNet }
  static Future<void> saveExamGoal(String userId, {
    String? tytHedef, double? tytNet,
    String? aytHedef, double? aytNet,
  }) async {
    final current = await getExamGoal(userId);
    final goal = {
      'tytHedef': tytHedef ?? current['tytHedef'],
      'tytNet': tytNet ?? current['tytNet'],
      'aytHedef': aytHedef ?? current['aytHedef'],
      'aytNet': aytNet ?? current['aytNet'],
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId, 'exam_goal'), jsonEncode(goal));
    await AppStateService.pushAppState('exam_goal', goal);
  }

  static Future<Map<String, dynamic>> getExamGoal(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId, 'exam_goal'));
    if (raw != null) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        return {
          'tytHedef': m['tytHedef'],
          'tytNet': (m['tytNet'] as num?)?.toDouble(),
          'aytHedef': m['aytHedef'],
          'aytNet': (m['aytNet'] as num?)?.toDouble(),
        };
      } catch (_) {}
    }
    // Eski 4-anahtar formatından geriye dönük okuma
    return {
      'tytHedef': prefs.getString(_key(userId, 'tyt_hedef')),
      'tytNet': prefs.getDouble(_key(userId, 'tyt_hedef_net')),
      'aytHedef': prefs.getString(_key(userId, 'ayt_hedef')),
      'aytNet': prefs.getDouble(_key(userId, 'ayt_hedef_net')),
    };
  }

  static Future<void> saveExamDate(String userId, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId, 'sinav_tarihi'), date.toIso8601String());
  }

  static Future<DateTime?> getExamDate(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId, 'sinav_tarihi'));
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }
}
