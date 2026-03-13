import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';

import '../lib/core/middleware/request_logger_middleware.dart';
import '../lib/middleware/rate_limiter.dart';
import '../lib/middleware/analytics_middleware.dart';

late Connection conn;

Future<void> initDatabase() async {
  conn = await Connection.open(
    Endpoint(
      host: 'nozomi.proxy.rlwy.net',
      port: 44301,
      database: 'railway',
      username: 'postgres',
      password: 'oPBSQKnLeMHYHqYqWQfejsyjcPxZhiPJ',
    ),
    settings: const ConnectionSettings(
      sslMode: SslMode.require,
    ),
  );

  print("Connected to Railway PostgreSQL");
}

Middleware apiKeyMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {

      final path = request.url.path;

      if (path == 'health' ||
          path == 'debug' ||
          path == 'api/v1/keys') {
        return innerHandler(request);
      }

      final apiKey = request.headers['x-api-key'];

      if (apiKey == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Missing API key'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final result = await conn.execute(
        Sql.named('SELECT id FROM api_keys WHERE api_key = @key'),
        parameters: {'key': apiKey},
      );

      if (result.isEmpty) {
        return Response.forbidden(
          jsonEncode({'error': 'Invalid API key'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      await conn.execute(
        Sql.named(
          'UPDATE api_keys SET usage_count = usage_count + 1, last_used = now() WHERE api_key = @key',
        ),
        parameters: {'key': apiKey},
      );

      return innerHandler(request);
    };
  };
}

Future<void> main() async {

  await initDatabase();

  final router = Router();

  /// Health check
  router.get('/health', (Request req) {
    return Response.ok(
      jsonEncode({'status': 'healthy'}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  /// Debug endpoint
  router.get('/debug', (Request req) {
    return Response.ok('Debug endpoint active');
  });

  /// Test protected endpoint
  router.get('/api/v1/token/test', (Request req) {

    final token = 'token-${DateTime.now().millisecondsSinceEpoch}';

    return Response.ok(
      jsonEncode({'token': token}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  /// API key generation
  router.post('/api/v1/keys', (Request request) async {

    final key = 'ovwi_${DateTime.now().millisecondsSinceEpoch}';

    await conn.execute(
      Sql.named('INSERT INTO api_keys (api_key) VALUES (@key)'),
      parameters: {'key': key},
    );

    return Response.ok(
      jsonEncode({'api_key': key}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  /// Analytics summary
  router.get('/api/v1/analytics/summary', (Request req) async {

    final result = await conn.execute(
      Sql.named('''
        SELECT
          COUNT(*) as total_requests,
          COUNT(DISTINCT api_key) as unique_keys,
          AVG(latency_ms) as avg_latency
        FROM api_usage
        WHERE created_at > NOW() - INTERVAL '24 hours'
      '''),
    );

    final row = result.first;

    return Response.ok(
      jsonEncode({
        'requests_24h': row[0],
        'unique_keys': row[1],
        'avg_latency': row[2]
      }),
      headers: {'Content-Type': 'application/json'},
    );
  });

  /// Top endpoints analytics
  router.get('/api/v1/analytics/top-endpoints', (Request req) async {

    final result = await conn.execute(
      Sql.named('''
        SELECT endpoint, COUNT(*)
        FROM api_usage
        GROUP BY endpoint
        ORDER BY COUNT(*) DESC
        LIMIT 10
      '''),
    );

    final data = result.map((r) => {
      'endpoint': r[0],
      'count': r[1]
    }).toList();

    return Response.ok(
      jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );
  });

  final handler = Pipeline()
      .addMiddleware(requestLoggerMiddleware())
      .addMiddleware(rateLimiter())
      .addMiddleware(analyticsMiddleware(conn))
      .addMiddleware(apiKeyMiddleware())
      .addHandler(router.call);

  final server = await io.serve(
      handler,
      InternetAddress.anyIPv4,
      8081);

  print('OVWI server running on port 8081');
}