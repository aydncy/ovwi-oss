import 'package:dotenv/dotenv.dart';

class Env {
  static final DotEnv _env = DotEnv()..load();

  static String get dbHost => _env['DB_HOST'] ?? 'localhost';
  static int get dbPort => int.tryParse(_env['DB_PORT'] ?? '5432') ?? 5432;
  static String get dbName => _env['DB_NAME'] ?? 'railway';
  static String get dbUser => _env['DB_USER'] ?? 'postgres';
  static String get dbPassword => _env['DB_PASSWORD'] ?? '';
  static int get serverPort => int.tryParse(_env['PORT'] ?? '8081') ?? 8081;
}
