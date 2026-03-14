import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';
import '../lib/router/app_router.dart';
import '../lib/services/api_key_service.dart';

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
        password: env['DB_PASSWORD'] ?? 'postgres',
      ),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );
    print('✅ PostgreSQL connected');
  } catch (e) {
    print('❌ Database connection failed: $e');
    return;
  }

  final apiKeyService = ApiKeyService(connection: connection);
  final router = await buildRouter(connection);

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router);

  final port = int.parse(env['OVWI_PORT'] ?? '8081');
  final server = await io.serve(handler, '0.0.0.0', port);
  
  print('');
  print('╔═════════════════════════════════╗');
  print('║   🚀 OVWI PLATFORM RUNNING   ║');
  print('╠═════════════════════════════════╣');
  print('║ URL: http://localhost:$port       ║');
  print('║ Database: Connected ✅          ║');
  print('║ Auth: DB-backed API Keys ✅     ║');
  print('║ Logging: Active ✅              ║');
  print('╚═════════════════════════════════╝');
  print('');
}