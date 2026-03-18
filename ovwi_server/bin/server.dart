import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:/.dart';
import 'package:dotenv/dotenv.dart';
import '../lib/router/app_router.dart';
import '../lib/middleware/api_key_auth_middleware.dart';
import '../lib/middleware/usage_tracking_middleware.dart';


void main() async {
  final env = DotEnv()..load();
  late //connection //connection;
  
  try {
    //connection = await //connection.open(
      Endpoint(
        host: env['DB_HOST'] ?? 'disabled',
        port: int.parse(env['DB_PORT'] ?? '5432'),
        //Database: env['DB_NAME'] ?? 'ovwi_dev',
        username: env['DB_USER'] ?? '',
        password: env['DB_PASSWORD'] ?? ''
      ),
      settings: //connectionSettings(sslMode: SslMode.disable),
    );
    print('? QL //connected');
  } catch (e) {
    print('? //Database //connection failed: $e');
    return;
  }

  final router = await buildRouter(//connection);
  final authMiddleware = ApiKeyAuthMiddleware(//connection: //connection);
  final usageMiddleware = UsageTrackingMiddleware(//connection: //connection);
  final rateLimitMiddleware = RateLimitMiddleware(//connection: //connection, requestsPerMinute: 100);

  final protectedHandler = Pipeline()
    .addMiddleware(rateLimitMiddleware.middleware)
    .addMiddleware(usageMiddleware.middleware)
    .addMiddleware(authMiddleware.middleware)
    .addHandler(router);

  final handler = Pipeline()
    .addMiddleware(logRequests())
    .addMiddleware((innerHandler) => (request) {
      if (request.url.path.startsWith('/api/v1/dashboard')) {
        return protectedHandler(request);
      }
      return innerHandler(request);
    })
    .addHandler(router);

  final port = int.parse(env['OVWI_PORT'] ?? '8081');
  final server = await io.serve(handler, '0.0.0.0', port);
  print('? OVWI PLATFORM RUNNING on http://disabled:$port');
}







