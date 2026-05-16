import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../core/global_navigator.dart';
import '../utils/constants.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        const storage = FlutterSecureStorage();
        final token = await storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        final status = e.response?.statusCode ?? 0;
        final path = e.requestOptions.path;

        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          showGlobalSnackBar('İnternet bağlantınızı kontrol edin.');
        } else if (status == 401) {
          const storage = FlutterSecureStorage();
          await storage.delete(key: 'jwt_token');
          showGlobalSnackBar('Oturumunuz sona erdi. Lütfen tekrar giriş yapın.');
          navigatorKey.currentContext?.go('/login');
        } else if ((status == 404 || status >= 500) &&
            (path.contains('UserProfile') ||
             path.contains('DailyReport') ||
             path.contains('gelisimim') ||
             path.contains('Gelisimim') ||
             path.contains('questionlog') ||
             path.contains('QuestionLog'))) {
          // Yeni kullanıcı / boş veri — sessizce geç
        } else if (status >= 500) {
          showGlobalSnackBar('Sunucu hatası, lütfen tekrar deneyin.');
        }
        return handler.next(e);
      },
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (o) => debugPrint(o.toString()),
      ));
    }
  }

  Dio get dio => _dio;

  Future<Response?> login(String email, String password) async {
    try {
      return await _dio.post('/Auth/login',
          data: {'email': email, 'password': password});
    } on DioException catch (e) {
      debugPrint('Login error [${e.type}]: ${e.message}');
      rethrow;
    }
  }

  Future<Response?> postAiPlan(String prompt) async {
    try {
      return await _dio.post('/Ai/plan', data: {'prompt': prompt});
    } on DioException catch (e) {
      debugPrint('AI plan error [${e.type}]: ${e.message}');
      if (e.response != null) {
        throw Exception(
            e.response?.data['message'] ?? 'AI servisinden hata döndü.');
      }
      throw Exception('AI servisine bağlanılamadı.');
    }
  }
}
