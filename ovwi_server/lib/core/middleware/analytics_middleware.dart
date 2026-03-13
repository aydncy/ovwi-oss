import 'package:shelf/shelf.dart';
import '../services/analytics_service.dart';

Middleware analyticsMiddleware() {
  final analyticsService = AnalyticsService();

  return (Handler innerHandler) {
    return (Request request) async {
      final startedAt =
          request.context['startedAt'] as DateTime? ?? DateTime.now();

      final response = await innerHandler(request);

      final endedAt = DateTime.now();
      final latency = endedAt.difference(startedAt).inMilliseconds;

      final apiKey = request.context['apiKey'] as String?;
      final requestId = request.context['requestId'] as String? ?? 'unknown';

      try {
        await analyticsService.logRequest(
          apiKey: apiKey,
          endpoint: '/${request.requestedUri.path}',
          method: request.method,
          statusCode: response.statusCode,
          latencyMs: latency,
          requestId: requestId,
        );
      } catch (e) {
        print('analytics logging failed: \$e');
      }

      return response;
    };
  };
}
