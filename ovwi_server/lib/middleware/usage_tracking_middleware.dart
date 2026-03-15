import 'package:shelf/shelf.dart';
import 'dart:convert';
import 'package:postgres/postgres.dart';

class UsageTrackingMiddleware {
  final Connection connection;

  UsageTrackingMiddleware({required this.connection});

  Middleware get middleware => (innerHandler) {
    return (request) async {
      final startTime = DateTime.now();
      final developerId = request.context['developerId'] as String?;
      final apiKey = request.context['apiKey'] as String?;

      final response = await innerHandler(request);

      if (developerId != null && apiKey != null) {
        final latency = DateTime.now().difference(startTime).inMilliseconds;
        final statusCode = response.statusCode;

        connection.execute(
          Sql.named('INSERT INTO api_usage (id, developer_id, endpoint, method, status_code, latency_ms, created_at) VALUES (gen_random_uuid(), @developer_id, @endpoint, @method, @status_code, @latency_ms, NOW())'),
          parameters: {
            'developer_id': developerId,
            'endpoint': request.url.path,
            'method': request.method,
            'status_code': statusCode,
            'latency_ms': latency
          }
        ).then((_) {
          print('✓ Usage logged: $developerId ${request.method} ${request.url.path}');
        }).catchError((e) {
          print('✗ Usage tracking error: $e');
        });
      }

      return response;
    };
  };
}
