import 'package:postgres/postgres.dart';
import 'package:crypto/crypto.dart';
import '../db/db.dart';
import '../models/developer_model.dart';

class DeveloperService {
  
  Future<Developer?> createDeveloper(String email, String password) async {
    final conn = await DB.connection;
    final hash = sha256.convert(password.codeUnits).toString();
    final jwtSecret = _generateSecret();

    try {
      final result = await conn.execute(
        Sql.named('''
          INSERT INTO developers (email, password_hash, jwt_secret)
          VALUES (@email, @hash, @jwtSecret)
          RETURNING id, email, password_hash, jwt_secret, created_at
        '''),
        parameters: {
          'email': email,
          'hash': hash,
          'jwtSecret': jwtSecret,
        },
      );

      final row = result.first;
      return Developer(
        id: row[0],
        email: row[1],
        passwordHash: row[2],
        jwtSecret: row[3],
        createdAt: row[4],
      );
    } catch (e) {
      return null;
    }
  }

  Future<Developer?> authenticate(String email, String password) async {
    final conn = await DB.connection;
    final hash = sha256.convert(password.codeUnits).toString();

    final result = await conn.execute(
      Sql.named('''
        SELECT id, email, password_hash, jwt_secret, created_at
        FROM developers
        WHERE email = @email
      '''),
      parameters: {'email': email},
    );

    if (result.isEmpty) return null;

    final row = result.first;
    if (row[2] != hash) return null;

    return Developer(
      id: row[0],
      email: row[1],
      passwordHash: row[2],
      jwtSecret: row[3],
      createdAt: row[4],
    );
  }

  String _generateSecret() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = List.generate(32, (index) => chars[DateTime.now().millisecond % chars.length]);
    return random.join();
  }
}
