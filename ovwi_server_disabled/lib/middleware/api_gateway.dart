import 'package:shelf/shelf.dart';

class APIGatewayMiddleware {
  // CORS middleware - built-in
  static Middleware corsMiddleware() {
    return createMiddleware(
      responseHandler: (Response response) {
        return response.change(headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
          'Content-Type': 'application/json',
        });
      },
    );
  }

  // Request logging
  static Middleware requestLogging() {
    return createMiddleware(
      requestHandler: (Request request) {
        print('📨 API: ${request.method} ${request.url.path}');
        return null;
      },
    );
  }

  // Error handling
  static Middleware errorHandler() {
    return createMiddleware(
      responseHandler: (Response response) {
        if (response.statusCode >= 400) {
          print('❌ Error ${response.statusCode}');
        }
        return response;
      },
    );
  }

  // API Key validation
  static Middleware apiKeyValidation() {
    return createMiddleware(
      requestHandler: (Request request) {
        final apiKey = request.headers['X-API-Key'];
        if (request.url.path.startsWith('/api/') && apiKey == null) {
          return Response.unauthorized('Missing API Key');
        }
        return null;
      },
    );
  }
}








