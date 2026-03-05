import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import '../lib/db.dart';
import '../lib/jwt_engine.dart';
import '../lib/stripe_webhook.dart';
import '../lib/jwks.dart';
const validApiKeys = {"demo-public-key"};

Future<void> main() async {
  initDb();
  //initJwt();

  final port = int.parse(
    Platform.environment['PORT'] ?? '8080',
  );

  final router = Router();

  router.get('/health', (Request req) {
    return Response.ok('OVWI running');
  });

  // JWKS endpoint
  router.get('/.well-known/jwks.json', (Request req) {
    final publicKey = getPublicKeyBase64Url();
    final jwks = buildJwks(publicKey, 'ovwi-key-1');

    return Response.ok(
      jsonEncode(jwks),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.get('/success', (Request req) {
    final email = req.requestedUri.queryParameters['email'];

    if (email == null) {
      return Response.badRequest(body: 'Missing email');
    }

    final newKey = "ovwi_${DateTime.now().millisecondsSinceEpoch}";
    insertKey(newKey, email, 500000);

    return Response.ok(
      "Payment successful!\n\nYour API Key:\n\n$newKey",
      headers: {'Content-Type': 'text/plain'},
    );
  });

  router.post('/api/v1/stripe/webhook', stripeWebhook);

  router.get('/api/v1/token/test', (Request req) {
    final apiKey = req.headers['x-api-key'];

    if (apiKey == null) {
      return Response.forbidden('Missing API key');
    }

    final keyData = getKey(apiKey);

    if (keyData == null) {
      return Response.forbidden('Invalid API key');
    }

    if (keyData['active'] != true) {
      return Response.forbidden('API key disabled');
    }

    if (keyData['usage'] >= keyData['limit']) {
      return Response.forbidden('Usage limit exceeded');
    }

    incrementUsage(apiKey);

    final token = generateJwt('test');

    return Response.ok(
      jsonEncode({'token': token}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router);

  final server = await io.serve(handler, '0.0.0.0', port);

  print('🚀 OVWI running on port ${server.port}');
}
