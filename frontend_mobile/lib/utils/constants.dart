import 'dart:io';

class ApiConstants {
  // Return the appropriate base URL depending on the platform
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5228/api';
    } else if (Platform.isIOS) {
      return 'http://localhost:5228/api';
    }
    // Fallback for other platforms (e.g. desktop)
    return 'http://localhost:5228/api';
  }
}
