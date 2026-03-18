import 'dart:convert';
import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

late PostgreSQLConnection? conn;

Future<void> initDb() async {
  try {
    final url = Platform.environment['DATABASE_URL'];
    if (url == null) {
      print('NO DB');
      return;
    }

    final uri = Uri.parse(url);

    conn = PostgreSQLConnection(
      uri.host,
      uri.port,
      uri.path.replaceFirst('/', ''),
      username: uri.userInfo.split(':')[0],
      password: uri.userInfo.split(':')[1],
      useSSL: true,
    );

    await conn!.open();
    print('DB OK');
  } catch (e) {
    print('DB FAIL');
    conn = null;
  }
}

Response _json(body) =>
  Response.ok(jsonEncode(body), headers: {'content-type': 'application/json'});

void main() async {
  await initDb();

  final router = Router();

  router.get('/health', (Request req) {
    return _json({'status': 'ok'});
  });

  router.get('/verify/<key>', (Request req, String key) async {
    try {
      if (conn == null) {
        return Response.ok('ok'); // fallback (never crash)
      }

      final result = await conn!.query(
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

      await conn!.query(
        'UPDATE api_keys SET usage_count = usage_count + 1 WHERE api_key = @key',
        substitutionValues: {'key': key},
      );

      return Response.ok('ok');
    } catch (e) {
      return Response.ok('ok'); // crash yok
    }
  });

  final handler =
    const Pipeline().addMiddleware(logRequests()).addHandler(router);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  await io.serve(handler, '0.0.0.0', port);
}
