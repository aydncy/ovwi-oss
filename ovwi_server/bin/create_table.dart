import 'package:postgres/postgres.dart';

Future<void> main() async {
  final conn = PostgreSQLConnection(
    'localhost', 5432, 'ovwi',
    username: 'postgres',
    password: 'yourpassword',
  );
  await conn.open();

  await conn.query('''
    CREATE TABLE IF NOT EXISTS api_keys (
      id SERIAL PRIMARY KEY,
      api_key TEXT UNIQUE NOT NULL,
      created_at TIMESTAMP DEFAULT now(),
      last_used TIMESTAMP,
      usage_count INT DEFAULT 0
    );
  ''');

  print('api_keys table created successfully');
  await conn.close();
}
