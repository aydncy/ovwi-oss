import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../../core/http/json_response.dart';
import '../../core/services/developer_service.dart';

Router authRoutes() {
  final router = Router();
  final service = DeveloperService();

  router.post('/api/v1/auth/signup', (Request request) async {
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

    final email = body['email']?.toString();
    final password = body['password']?.toString();

    if (email == null || password == null) {
      return jsonResponse(
        {'error': 'email and password required'},
        statusCode: 400,
      );
    }

    final dev = await service.createDeveloper(email, password);

    if (dev == null) {
      return jsonResponse(
        {'error': 'email already exists'},
        statusCode: 409,
      );
    }

    return jsonResponse({
      'developer': {
        'id': dev.id,
        'email': dev.email,
        'jwt_secret': dev.jwtSecret,
      }
    }, statusCode: 201);
  });

  router.post('/api/v1/auth/login', (Request request) async {
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

    final email = body['email']?.toString();
    final password = body['password']?.toString();

    if (email == null || password == null) {
      return jsonResponse(
        {'error': 'email and password required'},
        statusCode: 400,
      );
    }

    final dev = await service.authenticate(email, password);

    if (dev == null) {
      return jsonResponse(
        {'error': 'invalid credentials'},
        statusCode: 401,
      );
    }

    return jsonResponse({
      'developer': {
        'id': dev.id,
        'email': dev.email,
        'jwt_secret': dev.jwtSecret,
      }
    });
  });

  return router;
}
