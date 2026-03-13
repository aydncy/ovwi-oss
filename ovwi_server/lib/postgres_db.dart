import 'dart:convert';
import 'package:postgres/postgres.dart';

class PostgresDB {
  late Connection connection;

  Future<void> connect(String host, int port, String database, String user, String password) async {
    connection = await Connection.open(
      Endpoint(
        host: host,
        port: port,
        database: database,
        username: user,
        password: password,
      ),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );
  }

  Future<void> createTables() async {
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS anchor_blocks (
        id TEXT PRIMARY KEY,
        previous_hash TEXT NOT NULL,
        data_hash TEXT NOT NULL,
        sequence INTEGER NOT NULL,
        timestamp TIMESTAMPTZ NOT NULL,
        signature TEXT NOT NULL,
        metadata JSONB,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS api_keys (
        key_id TEXT PRIMARY KEY,
        active BOOLEAN DEFAULT true,
        rate_limit INTEGER,
        tier TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );

      CREATE INDEX idx_timestamp ON anchor_blocks(timestamp DESC);
      CREATE INDEX idx_sequence ON anchor_blocks(sequence DESC);
    ''');
  }

  Future<void> insertBlock(Map<String, dynamic> block) async {
    await connection.execute(
      Sql.named('''
        INSERT INTO anchor_blocks (id, previous_hash, data_hash, sequence, timestamp, signature, metadata)
        VALUES (@id, @prev_hash, @data_hash, @seq, @ts, @sig, @meta)
      '''),
      parameters: {
        'id': block['id'],
        'prev_hash': block['previous_hash'],
        'data_hash': block['data_hash'],
        'seq': block['sequence'],
        'ts': block['timestamp'],
        'sig': block['signature'],
        'meta': jsonEncode(block['metadata']),
      },
    );
  }

  Future<List<Map>> getChain() async {
    final result = await connection.execute('SELECT * FROM anchor_blocks ORDER BY sequence ASC');
    return result.map((row) => row.toColumnMap()).toList();
  }

  Future<void> close() async => await connection.close();
}
