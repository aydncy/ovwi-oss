import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/api_key_manager.dart';

Router apiKeyRouter() {
  final router = Router();

  router.post('/api/v1/keys', (Request req) {
    final key = ApiKeyService.generateKey();
    return Response.ok(jsonEncode({"api_key": key}),
        headers: {'Content-Type': 'application/json'});
  });

  router.get('/api/v1/keys', (Request req) {
    return Response.ok(jsonEncode(ApiKeyService.listKeys()),
        headers: {'Content-Type': 'application/json'});
  });

  router.delete('/api/v1/keys/<key>', (Request req, String key) {
    final removed = ApiKeyService.revokeKey(key);

    return Response.ok(
      jsonEncode({"revoked": removed}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  return router;
}
