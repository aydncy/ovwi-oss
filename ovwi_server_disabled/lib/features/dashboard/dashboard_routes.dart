import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router dashboardRoutes() {
  final router = Router();

  router.get('/stats', (Request req) async {
    return Response.ok(
      jsonEncode({
        "total_requests": 0,
        "successful_requests": 0,
        "failed_requests": 0,
        "avg_latency_ms": 0,
        "error_rate_percentage": 0,
        "period_days": 30
      }),
      headers: {'Content-Type': 'application/json'},
    );
  });

  return router;
}








