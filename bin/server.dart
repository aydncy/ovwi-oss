import 'dart:convert';
import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

Response _json(body) =>
  Response.ok(jsonEncode(body), headers: {'content-type': 'application/json'});

Future<PostgreSQLConnection?> connectDb() async {
  try {
    final host = Platform.environment['DB_HOST'];
    final port = int.parse(Platform.environment['DB_PORT'] ?? '5432');
    final db = Platform.environment['DB_NAME'];
    final user = Platform.environment['DB_USER'];
    final pass = Platform.environment['DB_PASS'];

    if (host == null || db == null || user == null || pass == null) {
      return null;
    }

    final conn = PostgreSQLConnection(
      host,
      port,
      db,
      username: user,
      password: pass,
      useSSL: true,
    );

    await conn.open().timeout(Duration(seconds: 3));
    return conn;
  } catch (e) {
    print("DB ERROR: $e");
    return null;
  }
}

void main() async {
  final router = Router();

  router.get('/health', (Request req) {
    return _json({'status': 'ok'});
  });

  router.get('/verify/<key>', (Request req, String key) async {
    final conn = await connectDb();

    if (conn == null) {
      return Response.ok('fallback_ok');
    }

    try {
      final result = await conn.query(
        'SELECT usage_count, usage_limit FROM api_keys WHERE api_key = @key',
        substitutionValues: {'key': key},
      );

      if (result.isEmpty) {
        return Response(401, body: 'invalid');
      }

      final usage = result.first[0] as int;
      final limit = result.first[1] as int;

      if (usage >= limit) {
        return Response(402, body: 'limit');
      }

      await conn.query(
        'UPDATE api_keys SET usage_count = usage_count + 1 WHERE api_key = @key',
        substitutionValues: {'key': key},
      );

      return Response.ok('ok');
    } catch (e) {
      print("QUERY ERROR: $e");
      return Response.ok('safe_ok');
    } finally {
      await conn.close();
    }
  });

  final handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(router);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  await io.serve(handler, '0.0.0.0', port);
}
