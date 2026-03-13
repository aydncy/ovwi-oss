import 'package:shelf/shelf.dart';
import '../http/json_response.dart';

class _RateEntry {
  int count;
  DateTime windowStart;

  _RateEntry({
    required this.count,
    required this.windowStart,
  });
}

final Map<String, _RateEntry> _rateMap = {};

Middleware rateLimitMiddleware({
  int limit = 100,
  Duration window = const Duration(minutes: 1),
}) {
  return (Handler innerHandler) {
    return (Request request) async {
      final apiKey = request.headers['x-api-key'] ?? 'anonymous';
      final now = DateTime.now();

      final entry = _rateMap[apiKey];

      if (entry == null || now.difference(entry.windowStart) > window) {
        _rateMap[apiKey] = _RateEntry(
          count: 1,
          windowStart: now,
        );
        return innerHandler(request);
      }

      if (entry.count >= limit) {
        return jsonResponse(
          {
            'error': 'rate_limit_exceeded',
            'message': 'Too many requests',
          },
          statusCode: 429,
        );
      }

      entry.count += 1;
      return innerHandler(request);
    };
  };
}
