import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthService {
  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  static bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }

  static String generateToken() {
    return 'ovwi_dev_' + DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final id = 'dev_' + DateTime.now().millisecondsSinceEpoch.toString();
    final passwordHash = hashPassword(password);

    return {
      'id': id,
      'email': email,
      'password_hash': passwordHash,
      'name': name,
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final accessToken = generateToken();
    final refreshToken = generateToken() + '_refresh';
    final expiresAt = DateTime.now().add(Duration(hours: 24));

    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}
