import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class TokenService {
  static const _storage = FlutterSecureStorage();

  static Future<String?> getUserId() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return null;
    if (JwtDecoder.isExpired(token)) return null;
    final payload = JwtDecoder.decode(token);
    final id = payload['sub'] ??
        payload['nameid'] ??
        payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'];
    return id?.toString();
  }

  static Future<String?> getUserName() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return null;
    if (JwtDecoder.isExpired(token)) return null;
    final payload = JwtDecoder.decode(token);
    return (payload['name'] ??
            payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'])
        ?.toString();
  }
}
