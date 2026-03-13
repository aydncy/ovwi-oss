import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Future<Response> _proxyGet(String targetPath) async {
  final client = HttpClient();

  try {
    final uri = Uri.parse('http://localhost:8083/api/v1/' + targetPath);
    final request = await client.getUrl(uri);
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();

    return Response(
      response.statusCode,
      body: body,
      headers: {
        'Content-Type': 'application/json',
      },
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({
        "error": "gateway_proxy_failed",
        "message": e.toString()
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } finally {
    client.close(force: true);
  }
}

Router gatewayRoutes() {
  final router = Router();

  router.get('/patients', (Request req) async {
    return await _proxyGet('patients');
  });

  router.get('/doctors', (Request req) async {
    return await _proxyGet('doctors');
  });

  router.get('/appointments', (Request req) async {
    return await _proxyGet('appointments');
  });

  return router;
}
