import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router analyticsRoutes() {
  final router = Router();

  router.get('/summary', (Request req) async {
    return Response.ok(
      jsonEncode({
        "requests": 0,
        "errors": 0
      }),
      headers: {'Content-Type': 'application/json'},
    );
  });

  return router;
}








