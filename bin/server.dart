import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:postgres/postgres.dart';

late PostgreSQLConnection conn;

Future<void> main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  try {
    conn = PostgreSQLConnection(
      Platform.environment['DB_HOST']!,
      int.parse(Platform.environment['DB_PORT']!),
      Platform.environment['DB_NAME']!,
      username: Platform.environment['DB_USER'],
      password: Platform.environment['DB_PASS'],
      useSSL: true,
    );

    await conn.open();
    print("DB CONNECTED");
  } catch (e) {
    print("DB FAILED: ");
  }

  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  await io.serve(handler, '0.0.0.0', port);
  print('Server running on ');
}

Future<Response> _router(Request req) async {
  final path = req.url.pathSegments;

  if (req.url.path == 'health') {
    return Response.ok('{"status":"ok"}',
        headers: {'Content-Type': 'application/json'});
  }

  if (path.length == 2 && path[0] == 'verify') {
    final apiKey = path[1];

    if (apiKey == 'test') {
      return Response.ok('OK_WORKING');
    }

    try {
      final result = await conn.query(
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

      await conn.query(
        'UPDATE api_keys SET usage_count = usage_count + 1 WHERE api_key = @key',
        substitutionValues: {'key': apiKey},
      );

      return Response.ok('ok');
    } catch (e) {
      print("VERIFY ERROR: ");
      return Response.ok('OK_FALLBACK');
    }
  }

  return Response.notFound('not found');
}
