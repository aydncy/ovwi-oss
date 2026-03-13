import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../features/dashboard/dashboard_routes.dart';
import '../features/analytics/analytics_routes.dart';
import '../features/gateway_routes.dart';

Router buildRouter() {
  final router = Router();

  router.get('/health', (Request req) {
    return Response.ok(
      '{"status":"healthy","service":"OVWI API Platform","version":"1.0.0"}',
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.mount('/api/v1/dashboard/', dashboardRoutes());
  router.mount('/api/v1/analytics/', analyticsRoutes());
  router.mount('/api/v1/gateway/', gatewayRoutes());

  return router;
}
