import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:postgres/postgres.dart';

PostgreSQLConnection? conn;

Future<void> main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  try {
    conn = PostgreSQLConnection(
      Platform.environment['DB_HOST'] ?? '',
      int.parse(Platform.environment['DB_PORT'] ?? '5432'),
      Platform.environment['DB_NAME'] ?? '',
      username: Platform.environment['DB_USER'],
      password: Platform.environment['DB_PASS'],
      useSSL: true,
    );

    await conn!.open();
    print("DB CONNECTED");
  } catch (e) {
    print("DB FAILED");
    conn = null;
  }

  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  await io.serve(handler, '0.0.0.0', port);
  print('Server running');
}

Future<Response> _router(Request req) async {
  final path = req.url.pathSegments;

  if (req.url.path == 'health') {
    return Response.ok('{"status":"ok"}',
        headers: {'Content-Type': 'application/json'});
  }

  if (path.length == 2 && path[0] == 'verify') {
    final apiKey = path[1];

    if (conn == null) {
      return Response.ok('NO_DB');
    }

    try {
      final result = await conn!.query(
        'SELECT usage_count, usage_limit FROM api_keys WHERE api_key = @key',
        substitutionValues: {'key': apiKey},
      );

      if (result.isEmpty) {
        return Response.notFound('invalid');
      }

      final usage = result.first[0] as int;
      final limit = result.first[1] as int;

      if (usage >= limit) {
        return Response.forbidden('limit reached');
      }

      await conn!.query(
        'UPDATE api_keys SET usage_count = usage_count + 1 WHERE api_key = @key',
        substitutionValues: {'key': apiKey},
      );

      return Response.ok('ok');
    } catch (e) {
      return Response.ok('QUERY_FAIL');
    }
  }

  // ?? PAYMENT SUCCESS
  if (req.url.path == 'payment/success') {
    final email = req.url.queryParameters['email'] ?? '';
    final plan = req.url.queryParameters['plan'] ?? '';

    if (email.isEmpty || plan.isEmpty) {
      return Response(400, body: 'missing params');
    }

    if (conn == null) {
      return Response.ok('NO_DB');
    }

    try {
      // duplicate kontrol
      final existing = await conn!.query(
        'SELECT api_key FROM api_keys WHERE email = @email LIMIT 1',
        substitutionValues: {'email': email},
      );

      if (existing.isNotEmpty) {
        final existingKey = existing.first[0];
        return Response.ok(
          '{"ok":true,"api_key":"","plan":"","email":"","reused":true}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      final apiKey = _generateApiKey();

      int limit = 100;
      if (plan == 'pro') limit = 10000;
      if (plan == 'ultra') limit = 100000;

      await conn!.query(
        '''
        INSERT INTO api_keys (api_key, plan, usage_count, usage_limit, is_active, email)
        VALUES (@key, @plan, 0, @limit, true, @email)
        ''',
        substitutionValues: {
          'key': apiKey,
          'plan': plan,
          'limit': limit,
          'email': email,
        },
      );

      return Response.ok(
        '{"ok":true,"api_key":"","plan":"","email":"","reused":false}',
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.ok('FAIL');
    }
  }

  return Response.notFound('not found');
}

String _generateApiKey() {
  final rand = DateTime.now().millisecondsSinceEpoch.toString();
  return 'ovwi_live_';
}

