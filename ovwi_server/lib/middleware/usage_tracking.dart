import 'dart:async';
import 'package:shelf/shelf.dart';

final Map<String, int> apiKeyUsage = {};

Middleware usageTrackingMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final apiKey = request.headers['x-api-key'] ?? 'anonymous';
      final endpoint = request.url.path;

      final key = '::';

      apiKeyUsage[key] = (apiKeyUsage[key] ?? 0) + 1;

      final start = DateTime.now();

      final response = await innerHandler(request);

      final latency = DateTime.now().difference(start).inMilliseconds;

      print(
          '[USAGE] key= endpoint= latency=ms');

      return response;
    };
  };
}
