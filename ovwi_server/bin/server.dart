import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';
import '../lib/router/app_router.dart';
import '../lib/middleware/api_key_auth_middleware.dart';
import '../lib/middleware/usage_tracking_middleware.dart';

void main() async {
  final env = DotEnv()..load();
  late Connection connection;
  
  try {
    connection = await Connection.open(
      Endpoint(
        host: env['DB_HOST'] ?? 'localhost',
        port: int.parse(env['DB_PORT'] ?? '5432'),
        database: env['DB_NAME'] ?? 'ovwi_dev',
        username: env['DB_USER'] ?? 'postgres',
        password: env['DB_PASSWORD'] ?? 'postgres'
      ),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );
    print('✅ PostgreSQL connected');
  } catch (e) {
    print('❌ Database connection failed: $e');
    return;
  }

  final router = await buildRouter(connection);
  final authMiddleware = ApiKeyAuthMiddleware(connection: connection);
  final usageMiddleware = UsageTrackingMiddleware(connection: connection);

  final protectedHandler = Pipeline()
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
  print('✅ OVWI PLATFORM RUNNING on http://localhost:$port');
}
