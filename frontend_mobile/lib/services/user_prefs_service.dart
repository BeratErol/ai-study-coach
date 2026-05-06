import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  }
}
