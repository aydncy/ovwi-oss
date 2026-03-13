import 'package:postgres/postgres.dart';
import '../db/db.dart';

class AnalyticsQueryService {
  
  Future<Map<String, dynamic>> getSummary() async {
    final conn = await DB.connection;

    final now = DateTime.now();
    final last24h = now.subtract(Duration(hours: 24));

    final totalRequests = await conn.execute(
      Sql.named('''
        SELECT COUNT(*) as count
        FROM api_usage
        WHERE created_at >= @since
      '''),
      parameters: {'since': last24h},
    );

    final totalByStatus = await conn.execute(
      Sql.named('''
        SELECT status_code, COUNT(*) as count
        FROM api_usage
        WHERE created_at >= @since
        GROUP BY status_code
        ORDER BY count DESC
      '''),
      parameters: {'since': last24h},
    );

    final avgLatency = await conn.execute(
      Sql.named('''
        SELECT AVG(latency_ms) as avg_latency
        FROM api_usage
        WHERE created_at >= @since
      '''),
      parameters: {'since': last24h},
    );

    return {
      'total_requests': totalRequests.first[0],
      'status_breakdown': totalByStatus.map((row) {
        return {
          'status_code': row[0],
          'count': row[1],
        };
      }).toList(),
      'avg_latency_ms': double.tryParse(avgLatency.first[0].toString()) ?? 0.0,
      'timestamp': now.toIso8601String(),
    };
  }

  Future<List<Map<String, dynamic>>> getTopEndpoints({int limit = 10}) async {
    final conn = await DB.connection;

    final now = DateTime.now();
    final last24h = now.subtract(Duration(hours: 24));

    final result = await conn.execute(
      Sql.named('''
        SELECT endpoint, method, COUNT(*) as count, AVG(latency_ms) as avg_latency
        FROM api_usage
        WHERE created_at >= @since
        GROUP BY endpoint, method
        ORDER BY count DESC
        LIMIT @limit
      '''),
      parameters: {
        'since': last24h,
        'limit': limit,
      },
    );

    return result.map((row) {
      return {
        'endpoint': row[0],
        'method': row[1],
        'request_count': row[2],
        'avg_latency_ms': double.tryParse(row[3].toString()) ?? 0.0,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getApiKeyUsage({int limit = 20}) async {
    final conn = await DB.connection;

    final now = DateTime.now();
    final last24h = now.subtract(Duration(hours: 24));

    final result = await conn.execute(
      Sql.named('''
        SELECT api_key, COUNT(*) as request_count, AVG(latency_ms) as avg_latency
        FROM api_usage
        WHERE created_at >= @since AND api_key IS NOT NULL
        GROUP BY api_key
        ORDER BY request_count DESC
        LIMIT @limit
      '''),
      parameters: {
        'since': last24h,
        'limit': limit,
      },
    );

    return result.map((row) {
      return {
        'api_key': row[0],
        'request_count': row[1],
        'avg_latency_ms': double.tryParse(row[2].toString()) ?? 0.0,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getErrors({int limit = 20}) async {
    final conn = await DB.connection;

    final now = DateTime.now();
    final last24h = now.subtract(Duration(hours: 24));

    final result = await conn.execute(
      Sql.named('''
        SELECT status_code, endpoint, COUNT(*) as count, MAX(created_at) as last_seen
        FROM api_usage
        WHERE created_at >= @since AND status_code >= 400
        GROUP BY status_code, endpoint
        ORDER BY count DESC
        LIMIT @limit
      '''),
      parameters: {
        'since': last24h,
        'limit': limit,
      },
    );

    return result.map((row) {
      return {
        'status_code': row[0],
        'endpoint': row[1],
        'count': row[2],
        'last_seen': row[3].toString(),
      };
    }).toList();
  }
}
