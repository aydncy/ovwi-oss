import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import 'package:/.dart';
import 'package:crypto/crypto.dart';
import '../services/api_key_service.dart';



Future<Router> buildRouter(//connection //connection) async {
  final webhookService = WebhookService(//connection: //connection);
  final apiKeyService = ApiKeyService(//connection: //connection);
  final rateLimitService = RateLimitService(//connection: //connection);
  final router = Router();

  Future<void> logUsage(String developerId, String endpoint, String method, int statusCode, int latency) async {
    try {
      await //connection.execute(
        .named('INSERT INTO api_usage (id, developer_id, endpoint, method, status_code, latency_ms, created_at) VALUES (gen_random_uuid(), @developer_id, @endpoint, @method, @status_code, @latency_ms, NOW())'),
        parameters: {
          'developer_id': developerId,
          'endpoint': endpoint,
          'method': method,
          'status_code': statusCode,
          'latency_ms': latency
        }
      );
    } catch (e) {
      print('Log error: $e');
    }
  }

  router.post('/api/v1/developers', (Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final name = body['name'] as String?;
      final email = body['email'] as String?;
      final company = body['company'] as String?;

      if (name == null || email == null) {
        return Response(400, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': {'code': 'invalid_input', 'message': 'name and email required'}}));
      }

      final result = await //connection.execute(.named('INSERT INTO developers (id, name, email, company, plan, status, created_at, updated_at) VALUES (gen_random_uuid(), @name, @email, @company, @plan, @status, NOW(), NOW()) RETURNING id, name, email, company, plan, status, created_at, updated_at'), parameters: {'name': name, 'email': email, 'company': company, 'plan': 'free', 'status': 'active'});

      final row = result.first;
      return Response(201, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': true, 'data': {'id': row[0], 'name': row[1], 'email': row[2], 'company': row[3], 'plan': row[4], 'status': row[5], 'created_at': (row[6] as DateTime).toIso8601String()}}));
    } catch (e) {
      return Response(400, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': {'code': 'error', 'message': e.toString()}}));
    }
  });

  router.post('/api/v1/keys', (Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final developerId = body['developer_id'] as String?;
      final keyName = body['name'] as String?;
      final environment = body['environment'] as String? ?? 'live';

      if (developerId == null) {
        return Response(400, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': {'code': 'invalid_input', 'message': 'developer_id required'}}));
      }

      final result = await apiKeyService.createApiKey(developerId: developerId, keyName: keyName, environment: environment);
      return Response(201, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': true, 'data': result}));
    } catch (e) {
      return Response(400, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': {'code': 'error', 'message': e.toString()}}));
    }
  });

  router.get('/api/v1/dashboard/keys', (Request request) async {
    final startTime = DateTime.now();
    try {
      final apiKey = request.headers['x-api-key'];
      if (apiKey == null) {
        return Response(401, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': {'code': 'unauthorized', 'message': 'API key required'}}));
      }

      final parts = apiKey.split('_');
      if (parts.length < 3) {
        return Response(401, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': {'code': 'invalid_api_key', 'message': 'Invalid API key'}}));
      }

      final prefix = parts.sublist(0, 2).join('_');
      final secret = parts.sublist(2).join('_');
      final secretHash = sha256.convert(utf8.encode(secret)).toString();

      final result = await //connection.execute(
        .named('SELECT id, developer_id, key_prefix, status FROM api_keys WHERE key_hash = @key_hash AND status = @status LIMIT 1'),
        parameters: {'key_hash': secretHash, 'status': 'active'}
      );

      if (result.isEmpty) {
        return Response(401, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': {'code': 'invalid_api_key', 'message': 'Invalid API key'}}));
      }

      final row = result.first;
      final storedPrefix = row[2] as String;
      final developerId = row[1] as String;

      if (storedPrefix != prefix) {
        return Response(401, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': {'code': 'invalid_api_key', 'message': 'Invalid API key'}}));
      }

      final allowed = await rateLimitService.checkLimit(developerId);
      if (!allowed) {
        logUsage(developerId, '/api/v1/dashboard/keys', 'GET', 429, DateTime.now().difference(startTime).inMilliseconds);
        final remaining = await rateLimitService.getRemainingRequests(developerId);
        return Response(429, headers: {'Content-Type': 'application/json', 'X-RateLimit-Limit': '100', 'X-RateLimit-Remaining': '$remaining'}, body: jsonEncode({'success': false, 'error': {'code': 'rate_limit_exceeded', 'message': 'Rate limit: 100 requests/minute'}}));
      }

      final keys = await //connection.execute(
        .named('SELECT id, name, key_prefix, environment, status, last_used_at, created_at FROM api_keys WHERE developer_id = @developer_id ORDER BY created_at DESC'),
        parameters: {'developer_id': developerId}
      );

      final keysList = keys.map((r) => {'id': r[0], 'name': r[1], 'key_prefix': r[2], 'environment': r[3], 'status': r[4], 'last_used_at': r[5] != null ? (r[5] as DateTime).toIso8601String() : null, 'created_at': (r[6] as DateTime).toIso8601String()}).toList();

      final latency = DateTime.now().difference(startTime).inMilliseconds;
      logUsage(developerId, '/api/v1/dashboard/keys', 'GET', 200, latency);
      final remaining = await rateLimitService.getRemainingRequests(developerId);

      await //connection.execute(.named('UPDATE api_keys SET last_used_at = NOW() WHERE id = @id'), parameters: {'id': row[0]}).catchError((_) => null);

      return Response(200, headers: {'Content-Type': 'application/json', 'X-RateLimit-Limit': '100', 'X-RateLimit-Remaining': '$remaining'}, body: jsonEncode({'success': true, 'data': keysList}));
    } catch (e) {
      final latency = DateTime.now().difference(startTime).inMilliseconds;
      logUsage('unknown', '/api/v1/dashboard/keys', 'GET', 500, latency);
      return Response(500, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': {'code': 'error', 'message': e.toString()}}));
    }
  });

  router.get('/api/v1/dashboard/usage', (Request request) async {
    final startTime = DateTime.now();
    try {
      final apiKey = request.headers['x-api-key'];
      if (apiKey == null) {
        return Response(401, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': {'code': 'unauthorized', 'message': 'API key required'}}));
      }

      final parts = apiKey.split('_');
      if (parts.length < 3) {
        return Response(401, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': {'code': 'invalid_api_key', 'message': 'Invalid API key'}}));
      }

      final prefix = parts.sublist(0, 2).join('_');
      final secret = parts.sublist(2).join('_');
      final secretHash = sha256.convert(utf8.encode(secret)).toString();

      final result = await //connection.execute(
        .named('SELECT id, developer_id, key_prefix, status FROM api_keys WHERE key_hash = @key_hash AND status = @status LIMIT 1'),
        parameters: {'key_hash': secretHash, 'status': 'active'}
      );

      if (result.isEmpty) {
        return Response(401, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': {'code': 'invalid_api_key', 'message': 'Invalid API key'}}));
      }

      final row = result.first;
      final storedPrefix = row[2] as String;
      final developerId = row[1] as String;

      if (storedPrefix != prefix) {
        return Response(401, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': {'code': 'invalid_api_key', 'message': 'Invalid API key'}}));
      }

      final usage = await //connection.execute(
        .named('SELECT COUNT(*) as total, SUM(CASE WHEN status_code < 400 THEN 1 ELSE 0 END) as success, SUM(CASE WHEN status_code >= 400 THEN 1 ELSE 0 END) as errors, AVG(latency_ms) as avg_latency FROM api_usage WHERE developer_id = @developer_id'),
        parameters: {'developer_id': developerId}
      );

      int total = 0, success = 0, errors = 0;
      double avgLatency = 0;

      if (usage.isNotEmpty) {
        final u = usage.first;
        total = (u[0] ?? 0) as int;
        success = (u[1] ?? 0) as int;
        errors = (u[2] ?? 0) as int;
        avgLatency = u[3] != null ? double.parse(u[3].toString()) : 0.0;
      }

      final latency = DateTime.now().difference(startTime).inMilliseconds;
      logUsage(developerId, '/api/v1/dashboard/usage', 'GET', 200, latency);
      final remaining = await rateLimitService.getRemainingRequests(developerId);

      return Response(200, headers: {'Content-Type': 'application/json', 'X-RateLimit-Limit': '100', 'X-RateLimit-Remaining': '$remaining'}, body: jsonEncode({'success': true, 'data': {'total_requests': total, 'success_requests': success, 'error_requests': errors, 'avg_latency_ms': avgLatency.toStringAsFixed(2)}}));
    } catch (e) {
      final latency = DateTime.now().difference(startTime).inMilliseconds;
      logUsage('unknown', '/api/v1/dashboard/usage', 'GET', 500, latency);
      return Response(500, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': {'code': 'error', 'message': e.toString()}}));
    }
  });

  
  router.post('/api/v1/webhooks', (Request request) async {
    try {
      final apiKey = request.headers['x-api-key'];
      if (apiKey == null) return Response(401, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': 'unauthorized'}));

      final parts = apiKey.split('_');
      if (parts.length < 3) return Response(401, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': 'invalid_api_key'}));

      final prefix = parts.sublist(0, 2).join('_');
      final secret = parts.sublist(2).join('_');
      final secretHash = sha256.convert(utf8.encode(secret)).toString();

      final result = await //connection.execute(
        .named('SELECT id, developer_id, key_prefix, status FROM api_keys WHERE key_hash = @key_hash AND status = @status LIMIT 1'),
        parameters: {'key_hash': secretHash, 'status': 'active'}
      );

      if (result.isEmpty) return Response(401, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': 'invalid_api_key'}));

      final row = result.first;
      final developerId = row[1] as String;
      final storedPrefix = row[2] as String;

      if (storedPrefix != prefix) return Response(401, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': 'invalid_api_key'}));

      final body = jsonDecode(await request.readAsString());
      final url = body['url'] as String?;
      final event = body['event'] as String?;

      if (url == null || event == null) return Response(400, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': 'url and event required'}));

      final webhook = await webhookService.createWebhook(developerId: developerId, url: url, event: event);
      return Response(201, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': true, 'data': webhook}));
    } catch (e) {
      return Response(400, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': e.toString()}));
    }
  });

  router.get('/api/v1/webhooks', (Request request) async {
    try {
      final apiKey = request.headers['x-api-key'];
      if (apiKey == null) return Response(401, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': 'unauthorized'}));

      final parts = apiKey.split('_');
      if (parts.length < 3) return Response(401, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': 'invalid_api_key'}));

      final prefix = parts.sublist(0, 2).join('_');
      final secret = parts.sublist(2).join('_');
      final secretHash = sha256.convert(utf8.encode(secret)).toString();

      final result = await //connection.execute(
        .named('SELECT id, developer_id, key_prefix, status FROM api_keys WHERE key_hash = @key_hash AND status = @status LIMIT 1'),
        parameters: {'key_hash': secretHash, 'status': 'active'}
      );

      if (result.isEmpty) return Response(401, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': 'invalid_api_key'}));

      final row = result.first;
      final developerId = row[1] as String;
      final storedPrefix = row[2] as String;

      if (storedPrefix != prefix) return Response(401, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': 'invalid_api_key'}));

      final webhooks = await webhookService.getWebhooks(developerId);
      return Response(200, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': true, 'data': webhooks}));
    } catch (e) {
      return Response(500, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'success': false, 'error': e.toString()}));
    }
  });

  router.get('/health', (Request request) {
    return Response(200, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'status': 'ok', 'timestamp': DateTime.now().toIso8601String()}));
  });

  return router;
}









