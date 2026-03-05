import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

final Map<String, Map<String, dynamic>> _apiKeys = {
  'demo-public-key': {'active': true, 'usage': 0, 'limit': 100},
};

void incrementUsage(String key) {
  if (_apiKeys.containsKey(key)) {
    _apiKeys[key]!['usage'] = (_apiKeys[key]!['usage'] as int) + 1;
  }
}

Map<String, dynamic>? getKey(String key) {
  return _apiKeys[key];
}

Middleware logRequests() {
  return (Handler innerHandler) {
    return (Request request) async {
      print('${request.method} ${request.url}');
      final response = await innerHandler(request);
      print('=> ${response.statusCode}');
      return response;
    };
  };
}

void main() async {
  final router = Router();
  final port = int.parse(Platform.environment['OVWI_PORT'] ?? '8080');

  router.get('/health', (Request req) {
    return Response.ok(
      jsonEncode({'status': 'healthy', 'version': '0.2.0'}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.get('/', (Request req) {
    return Response.ok('OVWI running');
  });

  router.get('/api/v1/token/test', (Request req) {
    final apiKey = req.headers['x-api-key'];
    
    if (apiKey == null) {
      return Response.forbidden('Missing API key');
    }

    if (apiKey != 'demo-public-key') {
      final keyData = getKey(apiKey);
      if (keyData == null) {
        return Response.forbidden("Invalid API key");
      }
      if (keyData['active'] != true) {
        return Response.forbidden("API key disabled");
      }
      if ((keyData['usage'] as int) >= (keyData['limit'] as int)) {
        return Response.forbidden("Usage limit exceeded");
      }
      incrementUsage(apiKey);
    }

    final token = 'token-${DateTime.now().millisecondsSinceEpoch}';
    return Response.ok(
      jsonEncode({'token': token}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.post('/api/v1/register', (Request req) async {
    final body = await req.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    
    if (!data.containsKey('email')) {
      return Response.badRequest(body: 'Missing email');
    }

    return Response.ok(
      jsonEncode({'message': 'Registered', 'email': data['email']}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
}
