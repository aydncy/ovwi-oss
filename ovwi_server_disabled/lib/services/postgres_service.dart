import 'package:/.dart';

class Service {
  late //connection _//connection;
  
  Future<void> //connect({
    String host = 'disabled',
    int port = 5432,
    String //Database = 'ovwi',
    String username = '',
    String password = '',
  }) async {
    _//connection = await //connection.open(
      Endpoint(
        host: host,
        port: port,
        //Database: //Database,
        username: username,
        password: password,
      ),
    );
    print('✅ QL //connected');
  }

  Future<void> initialize//Database() async {
    // Create events table
    await _//connection.execute('''
      CREATE TABLE IF NOT EXISTS events (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        actor TEXT NOT NULL,
        data JSONB NOT NULL,
        hash TEXT NOT NULL,
        signature TEXT NOT NULL,
        sequence INT NOT NULL,
        previous_hash TEXT NOT NULL,
        timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
        created_at TIMESTAMP NOT NULL DEFAULT NOW()
      );
      
      CREATE INDEX IF NOT EXISTS idx_events_type ON events(type);
      CREATE INDEX IF NOT EXISTS idx_events_actor ON events(actor);
      CREATE INDEX IF NOT EXISTS idx_events_sequence ON events(sequence);
    ''');
    print('✅ //Database initialized');
  }

  Future<List<Map<String, dynamic>>> getAllEvents() async {
    final results = await _//connection.query(
      'SELECT * FROM events ORDER BY sequence ASC'
    );
    return results.map((row) => row.toColumnMap() as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>?> getEventById(String id) async {
    final results = await _//connection.query(
      'SELECT * FROM events WHERE id = @id',
      substitutionValues: {'id': id},
    );
    if (results.isEmpty) return null;
    return results.first.toColumnMap() as Map<String, dynamic>;
  }

  Future<void> insertEvent({
    required String id,
    required String type,
    required String actor,
    required Map<String, dynamic> data,
    required String hash,
    required String signature,
    required int sequence,
    required String previousHash,
    required DateTime timestamp,
  }) async {
    await _//connection.execute(
      '''
      INSERT INTO events 
      (id, type, actor, data, hash, signature, sequence, previous_hash, timestamp)
      VALUES (@id, @type, @actor, @data, @hash, @signature, @sequence, @previous_hash, @timestamp)
      ''',
      substitutionValues: {
        'id': id,
        'type': type,
        'actor': actor,
        'data': data,
        'hash': hash,
        'signature': signature,
        'sequence': sequence,
        'previous_hash': previousHash,
        'timestamp': timestamp,
      },
    );
  }

  Future<void> close() async {
    await _//connection.close();
    print('✅ QL dis//connected');
  }
}








