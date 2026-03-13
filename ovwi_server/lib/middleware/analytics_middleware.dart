import 'package:shelf/shelf.dart';
import 'package:postgres/postgres.dart';

Middleware analyticsMiddleware(Connection conn) {
  return (Handler innerHandler) {
    return (Request request) async {

      final start = DateTime.now();

      final response = await innerHandler(request);

      final latency =
          DateTime.now().difference(start).inMilliseconds;

      final apiKey = request.headers['x-api-key'];

      try {
        await conn.execute(
          Sql.named('''
          INSERT INTO api_usage
          (api_key, endpoint, method, status_code, latency_ms)
          VALUES (@k,@e,@m,@s,@l)
          '''),
          parameters: {
            'k': apiKey,
            'e': request.url.path,
            'm': request.method,
            's': response.statusCode,
            'l': latency
          },
        );
      } catch (_) {}

      return response;
    };
  };
}