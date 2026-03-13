import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../../core/http/json_response.dart';
import '../../core/services/analytics_query_service.dart';

Router analyticsRoutes() {
  final router = Router();
  final service = AnalyticsQueryService();

  router.get('/api/v1/analytics/summary', (Request request) async {
    try {
      final data = await service.getSummary();
      return jsonResponse(data);
    } catch (e) {
      return jsonResponse(
        {'error': e.toString()},
        statusCode: 500,
      );
    }
  });

  router.get('/api/v1/analytics/top-endpoints', (Request request) async {
    try {
      final limit = int.tryParse(request.url.queryParameters['limit'] ?? '10') ?? 10;
      final data = await service.getTopEndpoints(limit: limit);
      return jsonResponse({'endpoints': data});
    } catch (e) {
      return jsonResponse(
        {'error': e.toString()},
        statusCode: 500,
      );
    }
  });

  router.get('/api/v1/analytics/api-keys', (Request request) async {
    try {
      final limit = int.tryParse(request.url.queryParameters['limit'] ?? '20') ?? 20;
      final data = await service.getApiKeyUsage(limit: limit);
      return jsonResponse({'api_keys': data});
    } catch (e) {
      return jsonResponse(
        {'error': e.toString()},
        statusCode: 500,
      );
    }
  });

  router.get('/api/v1/analytics/errors', (Request request) async {
    try {
      final limit = int.tryParse(request.url.queryParameters['limit'] ?? '20') ?? 20;
      final data = await service.getErrors(limit: limit);
      return jsonResponse({'errors': data});
    } catch (e) {
      return jsonResponse(
        {'error': e.toString()},
        statusCode: 500,
      );
    }
  });

  return router;
}
