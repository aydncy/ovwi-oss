import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

Response _json(body) =>
  Response.ok(jsonEncode(body), headers: {'content-type': 'application/json'});

void fireAndForgetDb(String key) async {
  try {
    final conn = PostgreSQLConnection(
      'nozomi.proxy.rlwy.net',
      44301,
      'railway',
      username: 'postgres',
      password: 'oPBSQKnLeMHYHqYqWQfejsyjcPxZhiPJ',
      useSSL: true,
    );

    await conn.open().timeout(Duration(seconds: 2));

    await conn.query(
      'UPDATE api_keys SET usage_count = usage_count + 1 WHERE api_key = @key',
      substitutionValues: {'key': key},
    );

    await conn.close();
  } catch (e) {
    print("DB BACKGROUND ERROR: $e");
  }
}

void main() async {
  final router = Router();

  router.get('/health', (Request req) {
    return _json({'status': 'ok'});
  });

  router.get('/verify/<key>', (Request req, String key) {
    // ?? hemen cevap ver
    Future(() => fireAndForgetDb(key));

    return Response.ok('ok');
  });

  final handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(router);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  await io.serve(handler, '0.0.0.0', port);
}
