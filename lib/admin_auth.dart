import 'package:shelf/shelf.dart';

Middleware adminAuthMiddleware() {
  final secret = const String.fromEnvironment(
    'OVWI_ADMIN_SECRET',
    defaultValue: '',
  );

  return (Handler innerHandler) {
    return (Request request) async {
      if (secret.isEmpty) {
        return Response.internalServerError(
          body: 'Admin secret not configured',
        );
      }

      final authHeader = request.headers['authorization'];

      if (authHeader == null ||
          !authHeader.startsWith('Bearer ')) {
        return Response.forbidden('Missing Authorization');
      }

      final token = authHeader.substring(7);

      if (token != secret) {
        return Response.forbidden('Invalid admin token');
      }

      return innerHandler(request);
    };
  };
}
