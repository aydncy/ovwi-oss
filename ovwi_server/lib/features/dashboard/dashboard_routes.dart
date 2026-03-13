import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../../core/http/json_response.dart';
import '../../core/services/dashboard_stats_service.dart';

Router dashboardRoutes() {
  final router = Router();
  final service = DashboardStatsService();

  // Developer stats
  router.get('/api/v1/dashboard/stats', (Request request) async {
    try {
      // Context'ten developer_id al (middleware'den gelecek)
      final developerId = request.context['developer_id'] as int?;
      
      if (developerId == null) {
        return jsonResponse(
          {'error': 'developer_id not found in context'},
          statusCode: 400,
        );
      }

      final stats = await service.getDeveloperStats(developerId);
      return jsonResponse(stats);
    } catch (e) {
      return jsonResponse(
        {'error': e.toString()},
        statusCode: 500,
      );
    }
  });

  // Daily usage breakdown
  router.get('/api/v1/dashboard/daily-usage', (Request request) async {
    try {
      final developerId = request.context['developer_id'] as int?;
      final days = int.tryParse(request.url.queryParameters['days'] ?? '7') ?? 7;

      if (developerId == null) {
        return jsonResponse(
          {'error': 'developer_id not found'},
          statusCode: 400,
        );
      }

      final dailyUsage = await service.getDailyUsage(developerId, days: days);
      return jsonResponse({
        'daily_usage': dailyUsage,
        'days': days,
      });
    } catch (e) {
      return jsonResponse(
        {'error': e.toString()},
        statusCode: 500,
      );
    }
  });

  // API key stats
  router.get('/api/v1/dashboard/api-keys', (Request request) async {
    try {
      final developerId = request.context['developer_id'] as int?;

      if (developerId == null) {
        return jsonResponse(
          {'error': 'developer_id not found'},
          statusCode: 400,
        );
      }

      final keyStats = await service.getApiKeyStats(developerId);
      return jsonResponse({
        'api_keys': keyStats,
      });
    } catch (e) {
      return jsonResponse(
        {'error': e.toString()},
        statusCode: 500,
      );
    }
  });

  // System health
  router.get('/api/v1/dashboard/health', (Request request) async {
    try {
      final health = await service.getSystemHealth();
      return jsonResponse(health);
    } catch (e) {
      return jsonResponse(
        {'error': e.toString()},
        statusCode: 500,
      );
    }
  });

  return router;
}
