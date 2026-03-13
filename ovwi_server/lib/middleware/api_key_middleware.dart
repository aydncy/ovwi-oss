import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../core/auth_engine.dart';

Middleware apiKeyMiddleware(
  Map<String, Map<String, dynamic>> apiKeys,
  void Function(String hash) incrementUsage,
  Map<String, dynamic>? Function(String hash) getKeyByHash,
) {
  return (Handler innerHandler) {
    return (Request request) async {

      if (request.url.path == "health") {
        return innerHandler(request);
      }

      final path = request.url.path;
      if(path == 'health' || path == 'debug'){ return innerHandler(request); }

      final apiKey = request.headers['x-api-key'];

      if (apiKey == null || apiKey.isEmpty) {
        return Response.forbidden(
          jsonEncode({"error": "Missing API key"}),
          headers: {"Content-Type": "application/json"},
        );
      }

      if (!OvwiAuthEngine.isFormatValid(apiKey)) {
        return Response.forbidden(
          jsonEncode({"error": "Malformed API key"}),
          headers: {"Content-Type": "application/json"},
        );
      }

      final hash = OvwiAuthEngine.hashKey(apiKey);
      final keyData = getKeyByHash(hash);

      if (keyData == null) {
        return Response.forbidden(
          jsonEncode({"error": "Unknown API key"}),
          headers: {"Content-Type": "application/json"},
        );
      }

      if (keyData["active"] != true) {
        return Response.forbidden(
          jsonEncode({"error": "API key disabled"}),
          headers: {"Content-Type": "application/json"},
        );
      }

      if ((keyData["usage"] as int) >= (keyData["limit"] as int)) {
        return Response.forbidden(
          jsonEncode({"error": "Usage limit exceeded"}),
          headers: {"Content-Type": "application/json"},
        );
      }

      incrementUsage(hash);

      return innerHandler(request);
    };
  };
}
