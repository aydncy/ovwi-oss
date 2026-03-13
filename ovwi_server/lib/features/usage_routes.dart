import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/usage_service.dart';

Router usageRoutes() {
  final router = Router();

  router.get('/api/v1/analytics/usage', (Request req) {
    return Response.ok(
      jsonEncode(usageSummary()),
      headers: {'Content-Type': 'application/json'},
    );
  });

  return router;
}
