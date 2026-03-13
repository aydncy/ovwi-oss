import 'dart:async';
import 'package:shelf/shelf.dart';

final Map<String, List<DateTime>> _requests = {};

Middleware rateLimiter({int maxRequests = 5}) {
  return (Handler handler) {
    return (Request request) async {

      final apiKey = request.headers['x-api-key'] ?? 'anonymous';
      final now = DateTime.now();

      _requests.putIfAbsent(apiKey, () => []);

      _requests[apiKey]!.removeWhere(
        (t) => now.difference(t).inMinutes >= 1,
      );

      if (_requests[apiKey]!.length >= maxRequests) {
        return Response(
          429,
          body: '{"error":"rate limit exceeded"}',
          headers: {'content-type': 'application/json'},
        );
      }

      _requests[apiKey]!.add(now);

      return handler(request);
    };
  };
}

