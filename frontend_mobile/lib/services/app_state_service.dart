import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'token_service.dart';

/// Cihazdan bağımsız generic key-value senkron katmanı (web ile birebir aynı).
///
/// SharedPreferences verileri `user_{userId}_{key}` biçiminde tutar
/// (hızlı/offline cache). Bu servis aynı veriyi backend `AppState`
/// tablosuyla senkron eder:
///  - [pushAppState]    → SharedPreferences + backend'e yazar
///  - [hydrateAppState] → backend'deki tüm değerleri cache'e indirir
///
/// Backend tarafında key sade haliyle (`quick_notes`), userId token'dan gelir.
class AppStateService {
  /// Bir anahtarı SharedPreferences'a yazar ve backend'e push eder.
  /// Backend hatası yerel kaydı durdurmaz (offline toleransı).
  static Future<void> pushAppState(String key, Object? value) async {
    final userId = await TokenService.getUserId();
    if (userId == null) return;
    final encoded = jsonEncode(value);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_${userId}_$key', encoded);

    try {
      await ApiService().dio.put(
            '/AppState/$key',
            data: value,
          );
    } catch (_) {
      // Ağ hatası → yerel kayıt korunur, sonraki senkronda gönderilir.
    }
  }

  /// Bir anahtarı hem SharedPreferences'tan hem backend'den siler.
  static Future<void> deleteAppState(String key) async {
    final userId = await TokenService.getUserId();
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_${userId}_$key');
    try {
      await ApiService().dio.delete('/AppState/$key');
    } catch (_) {}
  }

  /// Backend'deki tüm AppState değerlerini çekip SharedPreferences cache'ine
  /// yazar. Login sonrası çağrılır — başka cihazdaki değişiklikler iner.
  static Future<void> hydrateAppState() async {
    final userId = await TokenService.getUserId();
    if (userId == null) {
      debugPrint('[AppState] hydrate: userId yok, atlandı');
      return;
    }
    try {
      final res = await ApiService().dio.get('/AppState');
      final data = res.data;
      if (data is Map) {
        debugPrint('[AppState] hydrate uid=$userId anahtarlar: ${data.keys.toList()}');
        final prefs = await SharedPreferences.getInstance();
        for (final entry in data.entries) {
          await prefs.setString(
            'user_${userId}_${entry.key}',
            jsonEncode(entry.value),
          );
        }
      } else {
        debugPrint('[AppState] hydrate: beklenmeyen yanıt tipi: ${data.runtimeType}');
      }
    } catch (e) {
      debugPrint('[AppState] hydrate başarısız: $e');
    }
  }
}
