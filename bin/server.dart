import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

late PostgreSQLConnection? conn;

Future<void> initDb() async {
  try {
    conn = PostgreSQLConnection(
      Platform.environment['DB_HOST'] ?? '',
      int.tryParse(Platform.environment['DB_PORT'] ?? '5432') ?? 5432,
      Platform.environment['DB_NAME'] ?? '',
      username: Platform.environment['DB_USER'],
      password: Platform.environment['DB_PASS'],
    );
    await conn!.open();
    print('DB OK');
  } catch (e) {
    print('DB FAIL: $e');
    conn = null;
  }
}

Response _json(body) =>
    Response.ok(jsonEncode(body), headers: {'content-type': 'application/json'});

Future<void> main() async {
  await initDb();

  final router = Router();

  router.get('/health', (Request req) {
    return _json({'status': 'ok'});
  });

  router.get('/verify/<key>', (Request req, String key) async {
    try {
      if (conn == null) {
        return Response(500, body: 'db not connected');
      }

      final result = await conn!.query(
        'SELECT usage_count, usage_limit, is_active FROM api_keys WHERE api_key = @key',
        substitutionValues: {'key': key},
      );

      if (result.isEmpty) {
        return Response(401, body: 'invalid key');
      }

      final usage = result.first[0] as int;
      final limit = result.first[1] as int;
      final active = result.first[2] as bool;

      if (!active || usage >= limit) {
        return Response(402, body: 'limit exceeded');
      }

      await conn!.query(
        'UPDATE api_keys SET usage_count = usage_count + 1 WHERE api_key = @key',
        substitutionValues: {'key': key},
      );

      return Response.ok('ok');
    } catch (e) {
      print('ERROR: $e');
      return Response(500, body: 'error');
    }
  });

  final handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(router);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  await io.serve(handler, '0.0.0.0', port);

  print('LIVE $port');
}
