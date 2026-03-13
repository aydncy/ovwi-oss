import 'package:shelf_router/shelf_router.dart';
import '../features/health/health_routes.dart';
import '../features/debug/debug_routes.dart';
import '../features/keys/key_routes.dart';
import '../features/token/token_routes.dart';
import '../features/plugins/plugin_routes.dart';
import '../features/analytics/analytics_routes.dart';
import '../features/auth/auth_routes.dart';
import '../features/dashboard/dashboard_routes.dart';

Router buildRouter() {
  final router = Router();

  router.mount('/', healthRoutes().call);
  router.mount('/', debugRoutes().call);
  router.mount('/', keyRoutes().call);
  router.mount('/', tokenRoutes().call);
  router.mount('/', pluginRoutes().call);
  router.mount('/', analyticsRoutes().call);
  router.mount('/', authRoutes().call);
  router.mount('/', dashboardRoutes().call);

  return router;
}
