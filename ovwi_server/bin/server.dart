import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

import '../lib/router/app_router.dart';
import '../lib/middleware/api_key_middleware.dart';

void main() async {

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(apiKeyAuthMiddleware())
      .addHandler(buildRouter());

  final server = await io.serve(handler, '0.0.0.0', 8081);

  print("OVWI server running on http://localhost:" + server.port.toString());
}
