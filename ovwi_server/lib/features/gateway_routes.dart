import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/api_gateway_service.dart';

Router gatewayRoutes() {
  final router = Router();
  final gateway = APIGatewayService();

  router.get('/api/v1/gateway/patients', (Request request) async {
    try {
      final apiKey = request.headers['x-api-key'] ?? '';
      final patients = await gateway.getPatients(apiKey);
      return Response.ok(jsonEncode(patients), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  });

  router.post('/api/v1/gateway/patients', (Request request) async {
    try {
      final apiKey = request.headers['x-api-key'] ?? '';
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final result = await gateway.createPatient(apiKey, json);
      return Response.ok(jsonEncode(result), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  });

  router.get('/api/v1/gateway/appointments', (Request request) async {
    try {
      final apiKey = request.headers['x-api-key'] ?? '';
      final appointments = await gateway.getAppointments(apiKey);
      return Response.ok(jsonEncode(appointments), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  });

  router.post('/api/v1/gateway/appointments', (Request request) async {
    try {
      final apiKey = request.headers['x-api-key'] ?? '';
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final result = await gateway.createAppointment(apiKey, json);
      return Response.ok(jsonEncode(result), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  });

  router.get('/api/v1/gateway/doctors', (Request request) async {
    try {
      final apiKey = request.headers['x-api-key'] ?? '';
      final doctors = await gateway.getDoctors(apiKey);
      return Response.ok(jsonEncode(doctors), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  });

  router.post('/api/v1/gateway/doctors', (Request request) async {
    try {
      final apiKey = request.headers['x-api-key'] ?? '';
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final result = await gateway.createDoctor(apiKey, json);
      return Response.ok(jsonEncode(result), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  });

  return router;
}
