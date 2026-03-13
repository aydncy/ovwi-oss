import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import '../lib/core/middleware/request_logger_middleware.dart';
import '../lib/features/auth_routes.dart';
import '../lib/features/gateway_routes.dart';

Middleware requestLoggerMiddleware() {
  return (Handler handler) {
    return (Request request) async {
      final start = DateTime.now();
      final response = await handler(request);
      final duration = DateTime.now().difference(start).inMilliseconds;
      print('[${request.method}] ${request.requestedUri.path} › ${response.statusCode} (${duration}ms)');
      return response;
    };
  };
}

Future<void> main() async {
  final router = Router();

  router.get('/health', (Request req) {
    return Response.ok(
      jsonEncode({
        'status': 'healthy',
        'service': 'OVWI API Platform',
        'version': '1.0.0',
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.get('/debug', (Request req) {
    return Response.ok(
      jsonEncode({'debug': 'active', 'environment': 'development'}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.post('/api/v1/keys', (Request request) async {
    final key = 'ovwi_' + DateTime.now().millisecondsSinceEpoch.toString();
    return Response.ok(
      jsonEncode({
        'api_key': key,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'active',
      }),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.get('/api/v1/dashboard/stats', (Request req) {
    return Response.ok(
      jsonEncode({
        'total_requests': 1250,
        'successful_requests': 1180,
        'failed_requests': 70,
        'avg_latency_ms': 45.5,
        'error_rate_percentage': 5.6,
        'period_days': 30,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.get('/api/v1/dashboard/keys', (Request req) {
    return Response.ok(
      jsonEncode([
        {
          'key_id': 'ovwi_key_001',
          'masked_key': 'ovwi_****...5678',
          'created_at': '2026-02-15T10:30:00Z',
          'last_used': '2026-03-13T12:50:00Z',
          'request_count': 450,
          'is_active': true,
        },
        {
          'key_id': 'ovwi_key_002',
          'masked_key': 'ovwi_****...9012',
          'created_at': '2026-03-01T14:20:00Z',
          'last_used': '2026-03-13T11:30:00Z',
          'request_count': 800,
          'is_active': true,
        },
      ]),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.get('/api/v1/dashboard/top-endpoints', (Request req) {
    return Response.ok(
      jsonEncode([
        {
          'endpoint': '/api/v1/gateway/patients',
          'method': 'GET',
          'request_count': 380,
          'avg_latency_ms': 42.3,
          'error_count': 5,
        },
        {
          'endpoint': '/api/v1/gateway/appointments',
          'method': 'POST',
          'request_count': 320,
          'avg_latency_ms': 58.7,
          'error_count': 12,
        },
        {
          'endpoint': '/api/v1/gateway/doctors',
          'method': 'GET',
          'request_count': 290,
          'avg_latency_ms': 38.1,
          'error_count': 3,
        },
      ]),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.get('/api/v1/dashboard/usage-chart', (Request req) {
    return Response.ok(
      jsonEncode({
        'data': [
          {'date': '2026-03-08', 'requests': 156, 'avg_latency': 45.2, 'errors': 8},
          {'date': '2026-03-09', 'requests': 189, 'avg_latency': 48.1, 'errors': 11},
          {'date': '2026-03-10', 'requests': 203, 'avg_latency': 43.8, 'errors': 9},
          {'date': '2026-03-11', 'requests': 178, 'avg_latency': 46.5, 'errors': 13},
          {'date': '2026-03-12', 'requests': 216, 'avg_latency': 44.3, 'errors': 10},
          {'date': '2026-03-13', 'requests': 308, 'avg_latency': 45.1, 'errors': 19},
        ],
        'period': '7_days',
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.post('/api/v1/auth/register', (Request request) async {
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;

      return Response.ok(
        jsonEncode({
          'id': 'dev_' + DateTime.now().millisecondsSinceEpoch.toString(),
          'email': json['email'],
          'name': json['name'],
          'status': 'registered',
          'created_at': DateTime.now().toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  });

  router.post('/api/v1/auth/login', (Request request) async {
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;

      return Response.ok(
        jsonEncode({
          'access_token': 'ovwi_dev_' + DateTime.now().millisecondsSinceEpoch.toString(),
          'refresh_token': 'ovwi_ref_' + DateTime.now().millisecondsSinceEpoch.toString(),
          'expires_at': DateTime.now().add(Duration(hours: 24)).toIso8601String(),
          'developer': {
            'email': json['email'],
            'name': json['email'].toString().split('@')[0],
          },
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  });

  router.get('/api/v1/gateway/patients', (Request request) async {
    return Response.ok(
      jsonEncode([
        {
          'id': 'pat_001',
          'first_name': 'John',
          'last_name': 'Anderson',
          'phone': '+43 664 123 4567',
          'email': 'john.anderson@example.at',
        },
        {
          'id': 'pat_002',
          'first_name': 'Maria',
          'last_name': 'Mueller',
          'phone': '+49 173 456 7890',
          'email': 'maria.mueller@example.de',
        },
      ]),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.get('/api/v1/gateway/doctors', (Request request) async {
    return Response.ok(
      jsonEncode([
        {
          'id': 'doc_001',
          'first_name': 'Dr. Klaus',
          'last_name': 'Bergmann',
          'specialty': 'Cardiology',
          'license_number': 'MED-DE-001234',
          'email': 'klaus.bergmann@clinic.de',
        },
        {
          'id': 'doc_002',
          'first_name': 'Dr. Elisabeth',
          'last_name': 'Weber',
          'specialty': 'Neurology',
          'license_number': 'MED-AT-005678',
          'email': 'elisabeth.weber@clinic.at',
        },
      ]),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.get('/api/v1/gateway/appointments', (Request request) async {
    return Response.ok(
      jsonEncode([
        {
          'id': 'apt_001',
          'patient_id': 'pat_001',
          'doctor_id': 'doc_001',
          'appointment_time': '2026-03-20T10:00:00Z',
          'status': 'scheduled',
        },
        {
          'id': 'apt_002',
          'patient_id': 'pat_002',
          'doctor_id': 'doc_002',
          'appointment_time': '2026-03-21T14:30:00Z',
          'status': 'scheduled',
        },
      ]),
      headers: {'Content-Type': 'application/json'},
    );
  });

  final handler = Pipeline()
      .addMiddleware(requestLoggerMiddleware())
      .addHandler(router);

  final port = int.parse(Platform.environment['PORT'] ?? '8081');

  final server = await io.serve(handler, InternetAddress.anyIPv4, port);

  print('OVWI API Platform running on port ' + port.toString());
  print('Health: http://localhost:' + port.toString() + '/health');
  print('Dashboard: http://localhost:' + port.toString() + '/api/v1/dashboard/stats');
}
