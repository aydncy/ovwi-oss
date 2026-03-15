import 'package:shelf/shelf.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';

class ApiKeyAuthMiddleware {
  final Connection connection;

  ApiKeyAuthMiddleware({required this.connection});

  Middleware get middleware => (innerHandler) {
    return (request) async {
      final apiKey = request.headers['x-api-key'];
      
      if (apiKey == null) {
        return Response(401,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'success': false, 'error': {'code': 'unauthorized', 'message': 'API key required'}})
        );
      }

      final (isValid, developerId) = await validateApiKey(apiKey);
      
      if (!isValid) {
        return Response(401,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'success': false, 'error': {'code': 'invalid_api_key', 'message': 'Invalid or revoked API key'}})
        );
      }

      final newContext = {...request.context, 'developerId': developerId, 'apiKey': apiKey};
      final updatedRequest = request.change(context: newContext);

      return innerHandler(updatedRequest);
    };
  };

  Future<(bool, String?)> validateApiKey(String fullKey) async {
    try {
      final parts = fullKey.split('_');
      if (parts.length < 3) return (false, null);

      final prefix = parts.sublist(0, 2).join('_');
      final secret = parts.sublist(2).join('_');
      
      if (secret.isEmpty) return (false, null);

      final secretHash = sha256.convert(utf8.encode(secret)).toString();

      final result = await connection.execute(
        Sql.named('SELECT id, developer_id, key_prefix, status FROM api_keys WHERE key_hash = @key_hash AND status = @status LIMIT 1'),
        parameters: {'key_hash': secretHash, 'status': 'active'}
      );

      if (result.isEmpty) return (false, null);

      final row = result.first;
      final storedPrefix = row[2] as String;
      final developerId = row[1] as String;

      if (storedPrefix != prefix) return (false, null);

      connection.execute(
        Sql.named('UPDATE api_keys SET last_used_at = NOW() WHERE id = @id'),
        parameters: {'id': row[0]}
      ).catchError((_) => null);

      return (true, developerId);
    } catch (e) {
      print('Auth validation error: $e');
      return (false, null);
    }
  }
}
