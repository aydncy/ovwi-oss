import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/auth_service.dart';

Router authRoutes() {
  final router = Router();
  final authService = AuthService();

  router.post('/api/v1/auth/register', (Request request) async {
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;

      final developer = await authService.register(
        email: json['email'] as String,
        password: json['password'] as String,
        name: json['name'] as String,
      );

      return Response.ok(
        jsonEncode({'developer': developer, 'status': 'registered'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  });

  router.post('/api/v1/auth/login', (Request request) async {
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;

      final auth = await authService.login(
        email: json['email'] as String,
        password: json['password'] as String,
      );

      return Response.ok(
        jsonEncode(auth),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  });

  router.post('/api/v1/auth/refresh', (Request request) async {
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;

      final newAccessToken = 'ovwi_dev_' + DateTime.now().millisecondsSinceEpoch.toString();
      final expiresAt = DateTime.now().add(Duration(hours: 24));

      return Response.ok(
        jsonEncode({
          'access_token': newAccessToken,
          'expires_at': expiresAt.toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  });

  return router;
}








