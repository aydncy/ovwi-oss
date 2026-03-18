import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

Response _json(body) =>
  Response.ok(jsonEncode(body), headers: {'content-type': 'application/json'});

void main() async {
  final router = Router();

  router.get('/health', (Request req) {
    return _json({'status': 'ok'});
  });

  router.get('/verify/<key>', (Request req, String key) {
    return Response.ok('ok');
  });

  final handler =
    const Pipeline().addMiddleware(logRequests()).addHandler(router);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  await io.serve(handler, '0.0.0.0', port);
}
