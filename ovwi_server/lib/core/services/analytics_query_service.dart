class AnalyticsQueryService {

  Future<Map<String, dynamic>> getSummary() async {
    return {
      "total_requests": 0,
      "errors": 0
    };
  }

  Future<List<Map<String, dynamic>>> getTopEndpoints({int limit = 10}) async {
    return [];
  }

  Future<List<Map<String, dynamic>>> getApiKeyUsage({int limit = 10}) async {
    return [];
  }

  Future<List<Map<String, dynamic>>> getErrors({int limit = 10}) async {
    return [];
  }
}
