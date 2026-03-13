import 'dart:convert';
import 'package:postgres/postgres.dart';

class PostgresDB {
  late Connection connection;

  Future<void> connect(String host, int port, String database, String user, String password) async {
    try {
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
      print('[DB] Connected to PostgreSQL: ' + host + ':' + port.toString() + '/' + database);
    } catch (e) {
      print('[DB ERROR] ' + e.toString());
      rethrow;
    }
  }

  Future<void> createTables() async {
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS anchor_blocks (
        id TEXT PRIMARY KEY,
        previous_hash TEXT NOT NULL,
        data_hash TEXT NOT NULL,
        sequence INTEGER NOT NULL UNIQUE,
        timestamp TIMESTAMPTZ NOT NULL,
        signature TEXT NOT NULL,
        metadata JSONB,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS api_keys (
        key_id TEXT PRIMARY KEY,
        active BOOLEAN DEFAULT true,
        rate_limit INTEGER NOT NULL,
        tier TEXT NOT NULL,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS domain_events (
        id TEXT PRIMARY KEY,
        event_type TEXT NOT NULL,
        aggregate_id TEXT NOT NULL,
        data JSONB NOT NULL,
        timestamp TIMESTAMPTZ DEFAULT NOW()
      );

      CREATE INDEX IF NOT EXISTS idx_timestamp ON anchor_blocks(timestamp DESC);
      CREATE INDEX IF NOT EXISTS idx_sequence ON anchor_blocks(sequence DESC);
      CREATE INDEX IF NOT EXISTS idx_event_type ON domain_events(event_type);
    ''');
    print('[DB] Tables created');
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

  Future<void> insertEvent(String eventId, String eventType, String aggregateId, Map<String, dynamic> data) async {
    await connection.execute(
      Sql.named('''
        INSERT INTO domain_events (id, event_type, aggregate_id, data)
        VALUES (@id, @type, @agg_id, @data)
      '''),
      parameters: {
        'id': eventId,
        'type': eventType,
        'agg_id': aggregateId,
        'data': jsonEncode(data),
      },
    );
  }

  Future<void> close() async => await connection.close();
}
