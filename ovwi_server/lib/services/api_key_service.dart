import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../models/api_key_model.dart';
import 'package:postgres/postgres.dart';

class ApiKeyService {
  final Connection connection;

  ApiKeyService({required this.connection});

  String _generateSecret() {
    const uuid = Uuid();
    return uuid.v4().replaceAll('-', '').substring(0, 20);
  }

  String generateApiKey({String prefix = 'ovwi_live'}) {
    final secret = _generateSecret();
    return '${prefix}_${secret}';
  }

  String _hashSecret(String secret) {
    return sha256.convert(utf8.encode(secret)).toString();
  }

  String _extractSecret(String fullKey) {
    final parts = fullKey.split('_');
    return parts.last;
  }

  Future<Map<String, dynamic>> createApiKey({required String developerId, required String? keyName, String environment = 'live'}) async {
    try {
      final prefix = environment == 'test' ? 'ovwi_test' : 'ovwi_live';
      final fullKey = generateApiKey(prefix: prefix);
      final secret = _extractSecret(fullKey);
      final secretHash = _hashSecret(secret);

      final result = await connection.execute(
        Sql.named('INSERT INTO api_keys (id, developer_id, key_prefix, key_hash, name, environment, status, created_at) VALUES (gen_random_uuid(), @developer_id, @key_prefix, @key_hash, @name, @environment, @status, NOW()) RETURNING id, created_at'),
        parameters: {
          'developer_id': developerId,
          'key_prefix': prefix,
          'key_hash': secretHash,
          'name': keyName ?? 'Default Key',
          'environment': environment,
          'status': 'active',
        }
      );

      final row = result.first;
      return {
        'id': row[0] as String,
        'api_key': fullKey,
        'key_prefix': prefix,
        'name': keyName ?? 'Default Key',
        'environment': environment,
        'status': 'active',
        'created_at': (row[1] as DateTime).toIso8601String()
      };
    } catch (e) {
      throw Exception('Failed to create API key: $e');
    }
  }

  Future<(bool, ApiKey?, String?)> validateApiKey(String fullKey) async {
    try {
      if (fullKey.isEmpty) return (false, null, null);

      final secret = _extractSecret(fullKey);
      final secretHash = _hashSecret(secret);

      final result = await connection.execute(
        Sql.named('SELECT id, developer_id, key_prefix, key_hash, name, environment, status, last_used_at, created_at, revoked_at FROM api_keys WHERE key_hash = @key_hash LIMIT 1'),
        parameters: {'key_hash': secretHash}
      );

      if (result.isEmpty) return (false, null, null);

      final row = result.first;
      final apiKey = ApiKey(
        id: row[0] as String,
        developerId: row[1] as String,
        keyPrefix: row[2] as String,
        keyHash: row[3] as String,
        name: row[4] as String?,
        environment: row[5] as String? ?? 'live',
        status: row[6] as String,
        lastUsedAt: row[7] != null ? row[7] as DateTime : null,
        createdAt: row[8] as DateTime,
        revokedAt: row[9] != null ? row[9] as DateTime : null
      );

      if (apiKey.status != 'active') return (false, null, null);

      await connection.execute(
        Sql.named('UPDATE api_keys SET last_used_at = NOW() WHERE id = @id'),
        parameters: {'id': apiKey.id}
      ).catchError((e) => print('Error updating last_used: $e'));

      return (true, apiKey, apiKey.developerId);
    } catch (e) {
      print('API key validation error: $e');
      return (false, null, null);
    }
  }

  Future<List<Map<String, dynamic>>> listDeveloperKeys(String developerId) async {
    try {
      final result = await connection.execute(
        Sql.named('SELECT id, name, key_prefix, environment, status, last_used_at, created_at FROM api_keys WHERE developer_id = @developer_id ORDER BY created_at DESC'),
        parameters: {'developer_id': developerId}
      );

      return result.map((row) => {
        'id': row[0] as String,
        'name': row[1] as String?,
        'key_prefix': row[2] as String,
        'environment': row[3] as String,
        'status': row[4] as String,
        'last_used_at': row[5] != null ? (row[5] as DateTime).toIso8601String() : null,
        'created_at': (row[6] as DateTime).toIso8601String()
      }).toList();
    } catch (e) {
      throw Exception('Failed to list API keys: $e');
    }
  }
}
