import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import '../lib/core/middleware/request_logger_middleware.dart';
import '../lib/middleware/rate_limiter.dart';
import '../lib/middleware/analytics_middleware.dart';
import '../lib/features/auth_routes.dart';

Middleware requestLoggerMiddleware() {
  return (Handler handler) {
    return (Request request) async {
      final start = DateTime.now();
      final response = await handler(request);
      final duration = DateTime.now().difference(start).inMilliseconds;
      print('[${request.method}] ${request.requestedUri.path} › ${response.statusCode} (${duration}ms)');
      return response;
    };
  };
}

Future<void> main() async {
  final router = Router();

  router.get('/health', (Request req) {
    return Response.ok(
      jsonEncode({'status': 'healthy', 'timestamp': DateTime.now().toIso8601String()}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.get('/debug', (Request req) {
    return Response.ok(jsonEncode({'debug': 'active'}), headers: {'Content-Type': 'application/json'});
  });

  router.post('/api/v1/keys', (Request request) async {
    final key = 'ovwi_' + DateTime.now().millisecondsSinceEpoch.toString();
    return Response.ok(
      jsonEncode({'api_key': key}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.get('/api/v1/dashboard/stats', (Request req) {
    return Response.ok(
      jsonEncode({'total_requests': 0, 'avg_latency_ms': 0.0, 'error_rate_percentage': 0.0}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  final authRouter = authRoutes();

  final handler = Pipeline()
      .addMiddleware(requestLoggerMiddleware())
      .addHandler((request) async {
        var response = router(request);
        if (response is Response) return response;
        return authRouter(request);
      });

  final port = int.parse(Platform.environment['PORT'] ?? '8081');

  final server = await io.serve(handler, InternetAddress.anyIPv4, port);

  print('OVWI server running on port ' + port.toString());
  print('Health: http://localhost:8081/health');
  print('Auth: http://localhost:8081/api/v1/auth/register');
}
