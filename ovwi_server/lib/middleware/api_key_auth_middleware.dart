import 'package:shelf/shelf.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../services/api_key_service.dart';
import 'package:postgres/postgres.dart';

Middleware apiKeyAuthMiddleware(ApiKeyService apiKeyService) {
  return (innerHandler) {
    return (request) async {
      final startTime = DateTime.now();
      final requestId = const Uuid().v4();

      final isPublic = request.url.path == '/health' || 
                 request.url.path.startsWith('/api/v1/developers') ||
                 request.url.path.startsWith('/api/v1/keys') ||
                 request.url.path.startsWith('/api/v1/dashboard');

      if (!isPublic) {
        final apiKeyHeader = request.headers['x-api-key'];

        if (apiKeyHeader == null || apiKeyHeader.isEmpty) {
          return _errorResponse(401, 'missing_api_key', 'API key required');
        }

        final (isValid, keyRecord, developerId) = await apiKeyService.validateApiKey(apiKeyHeader);

        if (!isValid || developerId == null) {
          return _errorResponse(401, 'invalid_api_key', 'API key invalid or revoked');
        }

        final updatedRequest = request.change(context: {
          ...request.context,
          'developer_id': developerId,
          'api_key_id': keyRecord!.id,
          'request_id': requestId,
          'start_time': startTime,
        });

        var response = await innerHandler(updatedRequest);
        
        _logUsageAsync(apiKeyService.connection, developerId, keyRecord.id, request.url.path, request.method, response.statusCode, DateTime.now().difference(startTime).inMilliseconds, requestId);

        return response;
      } else {
        final updatedRequest = request.change(context: {...request.context, 'request_id': requestId});
        return await innerHandler(updatedRequest);
      }
    };
  };
}

void _logUsageAsync(Connection connection, String developerId, String apiKeyId, String endpoint, String method, int statusCode, int latencyMs, String requestId) {
  connection.execute(
    Sql.named('INSERT INTO api_usage (api_key_id, developer_id, endpoint, method, status_code, latency_ms, request_id) VALUES (@api_key_id, @developer_id, @endpoint, @method, @status_code, @latency_ms, @request_id)'),
    parameters: {'api_key_id': apiKeyId, 'developer_id': developerId, 'endpoint': endpoint, 'method': method, 'status_code': statusCode, 'latency_ms': latencyMs, 'request_id': requestId},
  ).catchError((e) => print('Usage logging error: $e'));
}

Response _errorResponse(int statusCode, String code, String message) {
  return Response(statusCode, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': {'code': code, 'message': message}}));
}