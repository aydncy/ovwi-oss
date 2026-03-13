class DashboardStatsService {

  Future<Map<String, dynamic>> getDeveloperStats(int developerId) async {
    return {
      "developer_id": developerId,
      "total_requests": 0,
      "successful_requests": 0,
      "failed_requests": 0
    };
  }

  Future<List<Map<String, dynamic>>> getDailyUsage(int developerId, {int days = 30}) async {
    return [];
  }

  Future<List<Map<String, dynamic>>> getApiKeyStats(int developerId) async {
    return [];
  }

  Future<Map<String, dynamic>> getSystemHealth() async {
    return {
      "status": "ok",
      "uptime": 0
    };
  }
}
