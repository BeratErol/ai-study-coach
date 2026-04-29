import 'package:dio/dio.dart';
import '../utils/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add authorization interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          const storage = FlutterSecureStorage();
          final token = await storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );

    // Add logging interceptor for debugging during development
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  Dio get dio => _dio;

  // Add a dedicated login method with detailed error handling
  Future<Response?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/Auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      return response;
    } on DioException catch (e) {
      print('\n=== BAĞLANTI HATASI (DioException) ===');
      print('URL: ${e.requestOptions.uri}');
      print('Hata Tipi: ${e.type}');
      print('Mesaj: ${e.message}');
      if (e.response != null) {
        print('Yanıt: ${e.response?.data}');
      } else {
        print('Sunucudan yanıt alınamadı. Backend çalışmıyor veya IP adresi yanlış olabilir.');
      }
      print('=======================================\n');
      rethrow;
    } catch (e) {
      print('\n=== BEKLENMEYEN HATA ===');
      print(e.toString());
      print('========================\n');
      rethrow;
    }
  }
}