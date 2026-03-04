import 'package:sqlite3/sqlite3.dart';

final db = sqlite3.open('ovwi.db');

void initDb() {
  db.execute('''
    CREATE TABLE IF NOT EXISTS api_keys (
      key TEXT PRIMARY KEY,
      email TEXT,
      limit_count INTEGER,
      usage INTEGER,
      active INTEGER
    );
  ''');
}

void insertKey(String key, String email, int limit) {
  db.execute(
    'INSERT INTO api_keys (key, email, limit_count, usage, active) VALUES (?, ?, ?, 0, 1)',
    [key, email, limit],
  );
}

Map<String, dynamic>? getKey(String key) {
  final result = db.select(
    'SELECT * FROM api_keys WHERE key = ?',
    [key],
  );

  if (result.isEmpty) return null;

  final row = result.first;

  return {
    'key': row['key'],
    'email': row['email'],
    'limit': row['limit_count'],
    'usage': row['usage'],
    'active': row['active'] == 1,
  };
}

void incrementUsage(String key) {
  db.execute(
    'UPDATE api_keys SET usage = usage + 1 WHERE key = ?',
    [key],
  );
}
