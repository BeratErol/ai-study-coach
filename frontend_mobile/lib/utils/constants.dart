import 'dart:io';

class ApiConstants {
  static String get baseUrl {
    if (Platform.isAndroid) {
      // 10.0.2.2 hem emülatörde hem fiziksel cihazda çalışır:
      // emülatör → host localhost, fiziksel → bağlantı hatası alır (kendi IP'ni kullan)
      // Fiziksel cihaz için gerçek IP kullan.
      return 'http://10.14.8.61:5228/api';
    } else if (Platform.isIOS) {
      return 'http://localhost:5228/api';
    }
    return 'http://localhost:5228/api';
  }
}
