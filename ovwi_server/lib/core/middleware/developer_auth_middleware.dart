import 'package:shelf/shelf.dart';
import 'package:postgres/postgres.dart';
import '../services/developer_service.dart';
import '../http/json_response.dart';
import '../db/db.dart';

Middleware developerAuthMiddleware() {
  final service = DeveloperService();

  return (Handler innerHandler) {
    return (Request request) async {
      final path = request.requestedUri.path;

      if (!path.contains('/api/v1/dashboard')) {
        return innerHandler(request);
      }

      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return jsonResponse(
          {'error': 'missing_authorization_header'},
          statusCode: 401,
        );
      }

      final jwtSecret = authHeader.substring(7);

      try {
        final conn = await DB.connection;
        final result = await conn.execute(
          Sql.named('SELECT id FROM developers WHERE jwt_secret = @secret LIMIT 1'),
          parameters: {'secret': jwtSecret},
        );

        if (result.isEmpty) {
          return jsonResponse(
            {'error': 'invalid_jwt_secret'},
            statusCode: 401,
          );
        }

        final developerId = result.first[0] as int;

        return innerHandler(
          request.change(
            context: {
              ...request.context,
              'developer_id': developerId,
            },
          ),
        );
      } catch (e) {
        return jsonResponse(
          {'error': e.toString()},
          statusCode: 500,
        );
      }
    };
  };
}
