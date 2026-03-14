import 'dart:convert';
import 'package:shelf/shelf.dart';

final Set<String> validApiKeys = {
  'ovwi_test_key'
};

Middleware apiKeyAuthMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
     return innerHandler(
  request.change(
    context: {
      ...request.context,
      'apiKey': 'dev_mode',
    },
  ),
);
      final apiKey = request.headers['x-api-key'];

      if (apiKey == null || !validApiKeys.contains(apiKey)) {
        return Response.forbidden(
          jsonEncode({
            "error": "invalid_api_key",
            "message": "Missing or invalid x-api-key header"
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return await innerHandler(request);
    };
  };
}

