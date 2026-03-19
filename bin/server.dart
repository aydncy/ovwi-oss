import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

Future<Response> handler(Request req) async {
  // HEALTH
  if (req.url.path == 'health') {
    return Response.ok('ok');
  }

  // CREATE KEY (NO AUTH, NO TOKEN)
  if (req.url.path == 'create-key' && req.method == 'POST') {
    final apiKey = 'ovwi_live_' + DateTime.now().millisecondsSinceEpoch.toString();
    return Response.ok(
      jsonEncode({'api_key': apiKey}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  return Response.notFound('not found');
}

void main(List<String> args) async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await io.serve(handler, '0.0.0.0', port);
  print('Server running on port ${server.port}');
}
