import 'package:shelf/shelf.dart';
import '../services/api_key_manager.dart';

Middleware apiKeyMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final key = request.headers['x-api-key'];

      if (key == null || !ApiKeyService.isValid(key)) {
        return Response.forbidden('Invalid API Key');
      }

      return innerHandler(request);
    };
  };
}








