import 'package:postgres/postgres.dart';
import '../db/db.dart';

class DashboardStatsService {
  
  // Developer'ýn tüm key'lerinin toplam stats
  Future<Map<String, dynamic>> getDeveloperStats(int developerId) async {
    final conn = await DB.connection;

    final now = DateTime.now();
    final last30days = now.subtract(Duration(days: 30));

    final totalRequests = await conn.execute(
      Sql.named('''
        SELECT COUNT(*) as count
        FROM api_usage au
        INNER JOIN api_keys ak ON au.api_key = ak.api_key
        WHERE ak.developer_id = @developerId
        AND au.created_at >= @since
      '''),
      parameters: {
        'developerId': developerId,
        'since': last30days,
      },
    );

    final avgLatency = await conn.execute(
      Sql.named('''
        SELECT AVG(au.latency_ms) as avg_latency
        FROM api_usage au
        INNER JOIN api_keys ak ON au.api_key = ak.api_key
        WHERE ak.developer_id = @developerId
        AND au.created_at >= @since
      '''),
      parameters: {
        'developerId': developerId,
        'since': last30days,
      },
    );

    final errorRate = await conn.execute(
      Sql.named('''
        SELECT 
          COUNT(CASE WHEN status_code >= 400 THEN 1 END)::float / COUNT(*) * 100 as error_percentage
        FROM api_usage au
        INNER JOIN api_keys ak ON au.api_key = ak.api_key
        WHERE ak.developer_id = @developerId
        AND au.created_at >= @since
      '''),
      parameters: {
        'developerId': developerId,
        'since': last30days,
      },
    );

    final topEndpoints = await conn.execute(
      Sql.named('''
        SELECT endpoint, COUNT(*) as count
        FROM api_usage au
        INNER JOIN api_keys ak ON au.api_key = ak.api_key
        WHERE ak.developer_id = @developerId
        AND au.created_at >= @since
        GROUP BY endpoint
        ORDER BY count DESC
        LIMIT 5
      '''),
      parameters: {
        'developerId': developerId,
        'since': last30days,
      },
    );

    return {
      'total_requests': totalRequests.first[0],
      'avg_latency_ms': double.tryParse(avgLatency.first[0].toString()) ?? 0.0,
      'error_rate_percentage': double.tryParse(errorRate.first[0].toString()) ?? 0.0,
      'top_endpoints': topEndpoints.map((row) {
        return {
          'endpoint': row[0],
          'count': row[1],
        };
      }).toList(),
      'period_days': 30,
      'timestamp': now.toIso8601String(),
    };
  }

  // Daily usage breakdown
  Future<List<Map<String, dynamic>>> getDailyUsage(int developerId, {int days = 7}) async {
    final conn = await DB.connection;

    final now = DateTime.now();
    final since = now.subtract(Duration(days: days));

    final result = await conn.execute(
      Sql.named('''
        SELECT 
          DATE(au.created_at) as date,
          COUNT(*) as request_count,
          AVG(au.latency_ms) as avg_latency,
          COUNT(CASE WHEN au.status_code >= 400 THEN 1 END) as error_count
        FROM api_usage au
        INNER JOIN api_keys ak ON au.api_key = ak.api_key
        WHERE ak.developer_id = @developerId
        AND au.created_at >= @since
        GROUP BY DATE(au.created_at)
        ORDER BY date DESC
      '''),
      parameters: {
        'developerId': developerId,
        'since': since,
      },
    );

    return result.map((row) {
      return {
        'date': row[0].toString(),
        'request_count': row[1],
        'avg_latency_ms': double.tryParse(row[2].toString()) ?? 0.0,
        'error_count': row[3],
      };
    }).toList();
  }

  // API key performance
  Future<List<Map<String, dynamic>>> getApiKeyStats(int developerId) async {
    final conn = await DB.connection;

    final now = DateTime.now();
    final last30days = now.subtract(Duration(days: 30));

    final result = await conn.execute(
      Sql.named('''
        SELECT 
          ak.api_key,
          COUNT(*) as request_count,
          AVG(au.latency_ms) as avg_latency,
          COUNT(CASE WHEN au.status_code >= 400 THEN 1 END) as error_count,
          MAX(au.created_at) as last_used
        FROM api_usage au
        INNER JOIN api_keys ak ON au.api_key = ak.api_key
        WHERE ak.developer_id = @developerId
        AND au.created_at >= @since
        GROUP BY ak.api_key
        ORDER BY request_count DESC
      '''),
      parameters: {
        'developerId': developerId,
        'since': last30days,
      },
    );

    return result.map((row) {
      return {
        'api_key': row[0],
        'request_count': row[1],
        'avg_latency_ms': double.tryParse(row[2].toString()) ?? 0.0,
        'error_count': row[3],
        'last_used': row[4].toString(),
      };
    }).toList();
  }

  // Health check
  Future<Map<String, dynamic>> getSystemHealth() async {
    final conn = await DB.connection;

    final now = DateTime.now();
    final lastHour = now.subtract(Duration(hours: 1));

    final totalLatestHour = await conn.execute(
      Sql.named('''
        SELECT COUNT(*) as count FROM api_usage WHERE created_at >= @since
      '''),
      parameters: {'since': lastHour},
    );

    final errorLatestHour = await conn.execute(
      Sql.named('''
        SELECT COUNT(*) as count FROM api_usage 
        WHERE created_at >= @since AND status_code >= 400
      '''),
      parameters: {'since': lastHour},
    );

    final avgLatencyLatestHour = await conn.execute(
      Sql.named('''
        SELECT AVG(latency_ms) as avg FROM api_usage WHERE created_at >= @since
      '''),
      parameters: {'since': lastHour},
    );

    final totalCount = totalLatestHour.first[0] as int;
    final errorCount = errorLatestHour.first[0] as int;

    return {
      'status': 'healthy',
      'requests_last_hour': totalCount,
      'errors_last_hour': errorCount,
      'error_rate_percentage': totalCount > 0 ? (errorCount / totalCount * 100) : 0.0,
      'avg_latency_ms': double.tryParse(avgLatencyLatestHour.first[0].toString()) ?? 0.0,
      'timestamp': now.toIso8601String(),
    };
  }
}
