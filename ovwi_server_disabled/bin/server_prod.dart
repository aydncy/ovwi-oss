import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:crypto/crypto.dart';

class AnchorBlock {
  final String id, previousHash, dataHash, signature;
  final int sequence;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  AnchorBlock({required this.id, required this.previousHash, required this.dataHash, required this.sequence, required this.timestamp, required this.metadata, required this.signature});

  Map<String, dynamic> toJson() => {'id': id, 'previous_hash': previousHash, 'data_hash': dataHash, 'sequence': sequence, 'timestamp': timestamp.toUtc().toIso8601String(), 'metadata': metadata, 'signature': signature};
}

class AnchorChainManager {
  final List<AnchorBlock> _chain = [];
  String _lastHash = '0' * 64;
  int _sequence = 0;

  Future<AnchorBlock> addEvent(String eventId, Map<String, dynamic> eventData, String signature) async {
    final dataHash = sha256.convert(utf8.encode(jsonEncode(eventData))).toString();
    final block = AnchorBlock(id: eventId, previousHash: _lastHash, dataHash: dataHash, sequence: _sequence++, timestamp: DateTime.now().toUtc(), metadata: {'event_count': _chain.length + 1, 'chain_height': _sequence, 'is_anchored': true}, signature: signature);
    _chain.add(block);
    _lastHash = sha256.convert(utf8.encode(block.previousHash + block.dataHash + block.sequence.toString())).toString();
    return block;
  }

  bool verifyChainIntegrity() {
    if (_chain.isEmpty) return true;
    for (int i = 0; i < _chain.length; i++) {
      final block = _chain[i];
      final expectedPreviousHash = i == 0 ? '0' * 64 : _chain[i - 1].previousHash;
      if (block.previousHash != expectedPreviousHash) return false;
    }
    return true;
  }

  List<AnchorBlock> getChain() => List.unmodifiable(_chain);
  AnchorBlock getBlock(String id) => _chain.firstWhere((b) => b.id == id);
}

class RateLimiter {
  final Map<String, List<int>> _requests = {};
  final int maxRequests;
  final Duration window;
  RateLimiter({this.maxRequests = 100, this.window = const Duration(minutes: 1)});

  bool isAllowed(String key) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final windowStart = now - window.inMilliseconds;
    _requests[key] ??= [];
    _requests[key]!.removeWhere((ts) => ts < windowStart);
    if (_requests[key]!.length >= maxRequests) return false;
    _requests[key]!.add(now);
    return true;
  }

  int getRemainingRequests(String key) => maxRequests - (_requests[key]?.length ?? 0);
}

class ApiKeyManager {
  final Map<String, Map<String, dynamic>> _keys = {'prod-api-key-001': {'active': true, 'rate_limit': 10000, 'created_at': DateTime.now().toIso8601String(), 'tier': 'enterprise'}};
  final Map<String, RateLimiter> _limiters = {};

  bool validateKey(String key) {
    final data = _keys[key];
    return data != null && data['active'] == true;
  }

  bool checkRateLimit(String key) {
    _limiters.putIfAbsent(key, () => RateLimiter(maxRequests: _keys[key]?['rate_limit'] ?? 100));
    return _limiters[key]!.isAllowed(key);
  }

  Map<String, dynamic> getKeyMetrics(String key) => {'key': key, 'valid': validateKey(key), 'remaining_requests': _limiters[key]?.getRemainingRequests(key) ?? 0, 'tier': _keys[key]?['tier'] ?? 'unknown'};
}

void main_DISABLED() async {
  final router = Router();
  final port = int.parse(Platform.environment['OVWI_PORT'] ?? '8081');
  final chainManager = AnchorChainManager();
  final apiKeyManager = ApiKeyManager();

  Middleware logRequests() => (Handler innerHandler) => (Request request) async {
    final timestamp = DateTime.now().toIso8601String();
    print('[' + timestamp + '] ' + request.method + ' ' + request.url.toString());
    final response = await innerHandler(request);
    print('  -> ' + response.statusCode.toString());
    return response;
  };

  Middleware authenticateApiKey() => (Handler innerHandler) => (Request request) async {
    final apiKey = request.headers['x-api-key'];
    if (apiKey == null) return Response.forbidden(jsonEncode({'error': 'Missing API key'}), headers: {'Content-Type': 'application/json'});
    if (!apiKeyManager.validateKey(apiKey)) return Response.forbidden(jsonEncode({'error': 'Invalid API key'}), headers: {'Content-Type': 'application/json'});
    if (!apiKeyManager.checkRateLimit(apiKey)) return Response(429, body: jsonEncode({'error': 'Rate limit exceeded'}), headers: {'Content-Type': 'application/json'});
    return innerHandler(request);
  };

  router.get('/health', (Request req) => Response.ok(jsonEncode({'status': 'healthy', 'version': '2.0.0', 'timestamp': DateTime.now().toUtc().toIso8601String(), 'chain_height': chainManager.getChain().length}), headers: {'Content-Type': 'application/json'}));

  router.get('/metrics', (Request req) {
    final apiKey = req.headers['x-api-key'] ?? 'unknown';
    return Response.ok(jsonEncode({'api_key_metrics': apiKeyManager.getKeyMetrics(apiKey), 'chain_stats': {'height': chainManager.getChain().length, 'integrity_valid': chainManager.verifyChainIntegrity()}}), headers: {'Content-Type': 'application/json'});
  });

  router.post('/api/v1/events', (Request req) async {
    try {
      final body = await req.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final eventId = data['id'] as String? ?? 'event-' + DateTime.now().millisecondsSinceEpoch.toString();
      final signature = data['signature'] as String? ?? 'unsigned';
      final block = await chainManager.addEvent(eventId, data, signature);
      return Response.ok(jsonEncode(block.toJson()), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.badRequest(body: jsonEncode({'error': e.toString()}), headers: {'Content-Type': 'application/json'});
    }
  });

  router.get('/api/v1/events/<id>', (Request req, String id) {
    try {
      final block = chainManager.getBlock(id);
      return Response.ok(jsonEncode(block.toJson()), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.notFound(jsonEncode({'error': 'Event not found'}), headers: {'Content-Type': 'application/json'});
    }
  });

  router.get('/api/v1/verify-chain', (Request req) => Response.ok(jsonEncode({'valid': chainManager.verifyChainIntegrity(), 'chain_length': chainManager.getChain().length, 'last_verified': DateTime.now().toUtc().toIso8601String()}), headers: {'Content-Type': 'application/json'}));

  router.get('/api/v1/chain', (Request req) => Response.ok(jsonEncode(chainManager.getChain().map((b) => b.toJson()).toList()), headers: {'Content-Type': 'application/json'}));

  final handler = Pipeline().addMiddleware(logRequests()).addMiddleware(authenticateApiKey()).addHandler(router.call);
  await io.serve(handler, InternetAddress.anyIPv4, port);
  print('OVWI Server v2.0 http://disabled:' + port.toString());
}








