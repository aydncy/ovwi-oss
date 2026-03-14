import 'package:shelf/shelf.dart';
import '../http/json_response.dart';
import '../services/api_key_service.dart';

Middleware apiKeyMiddleware() {
  final service = APIKeyService();

  return (Handler innerHandler) {
    return (Request request) async {
      final path = request.requestedUri.path;

final isPublic = path == '/health' ||
    path == '/debug' ||
    path == '/api/v1/keys';

if (isPublic) {
  return innerHandler(request);
}

      final apiKey = request.headers['x-api-key'];

      if (apiKey == null || apiKey.isEmpty) {
        return jsonResponse(
          {
            'error': 'missing_api_key',
            'message': 'x-api-key header is required',
          },
          statusCode: 401,
        );
      }

      final exists = await service.exists(apiKey);

      if (!exists) {
        return jsonResponse(
          {
            'error': 'invalid_api_key',
            'message': 'API key is invalid',
          },
          statusCode: 401,
        );
      }

      await service.markUsage(apiKey);

      return innerHandler(
        request.change(
          context: {
            ...request.context,
            'apiKey': apiKey,
          },
        ),
      );
    };
  };
}

