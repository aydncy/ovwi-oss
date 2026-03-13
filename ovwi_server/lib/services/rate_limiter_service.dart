class RateLimitBucket {
  final String key;
  final int maxRequests;
  final Duration window;
  final List<DateTime> requestTimestamps = [];

  RateLimitBucket({
    required this.key,
    required this.maxRequests,
    required this.window,
  });

  bool allowRequest() {
    final now = DateTime.now();
    
    // Remove old timestamps outside the window
    requestTimestamps.removeWhere(
      (timestamp) => now.difference(timestamp) > window,
    );

    // Check if limit exceeded
    if (requestTimestamps.length >= maxRequests) {
      return false;
    }

    // Add new request
    requestTimestamps.add(now);
    return true;
  }

  int remainingRequests() {
    final now = DateTime.now();
    requestTimestamps.removeWhere(
      (timestamp) => now.difference(timestamp) > window,
    );
    return (maxRequests - requestTimestamps.length).clamp(0, maxRequests);
  }

  DateTime? resetTime() {
    if (requestTimestamps.isEmpty) return null;
    final oldestRequest = requestTimestamps.first;
    return oldestRequest.add(window);
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'maxRequests': maxRequests,
    'windowSeconds': window.inSeconds,
    'currentRequests': requestTimestamps.length,
    'remaining': remainingRequests(),
    'resetTime': resetTime()?.toIso8601String(),
  };
}

class RateLimiterService {
  final Map<String, RateLimitBucket> _buckets = {};
  
  // Default limits
  static const int defaultMaxRequests = 1000;
  static const Duration defaultWindow = Duration(hours: 1);

  void createLimit({
    required String apiKey,
    int maxRequests = defaultMaxRequests,
    Duration window = defaultWindow,
  }) {
    _buckets[apiKey] = RateLimitBucket(
      key: apiKey,
      maxRequests: maxRequests,
      window: window,
    );
    print('✅ Rate limit created: $apiKey ($maxRequests req/$window)');
  }

  bool checkLimit(String apiKey) {
    final bucket = _buckets[apiKey];
    
    if (bucket == null) {
      // Create default limit if not exists
      createLimit(apiKey: apiKey);
      return _buckets[apiKey]!.allowRequest();
    }

    final allowed = bucket.allowRequest();
    
    if (!allowed) {
      print('⚠️ Rate limit exceeded: $apiKey');
      print('   Reset at: ${bucket.resetTime()}');
    }

    return allowed;
  }

  Map<String, dynamic> getLimitStatus(String apiKey) {
    final bucket = _buckets[apiKey];
    if (bucket == null) {
      return {'status': 'no_limit_set', 'apiKey': apiKey};
    }
    return bucket.toJson();
  }

  Map<String, dynamic> getAllLimits() {
    return {
      for (var entry in _buckets.entries)
        entry.key: entry.value.toJson(),
    };
  }

  void resetLimit(String apiKey) {
    final bucket = _buckets[apiKey];
    if (bucket != null) {
      bucket.requestTimestamps.clear();
      print('✅ Rate limit reset: $apiKey');
    }
  }

  void setCustomLimit({
    required String apiKey,
    required int maxRequests,
    required Duration window,
  }) {
    _buckets[apiKey] = RateLimitBucket(
      key: apiKey,
      maxRequests: maxRequests,
      window: window,
    );
    print('✅ Custom limit set: $apiKey ($maxRequests req/$window)');
  }

  // Tiered limits based on plan
  void setTieredLimit(String apiKey, String plan) {
    switch (plan) {
      case 'free':
        setCustomLimit(
          apiKey: apiKey,
          maxRequests: 100,
          window: Duration(hours: 1),
        );
      case 'pro':
        setCustomLimit(
          apiKey: apiKey,
          maxRequests: 10000,
          window: Duration(hours: 1),
        );
      case 'enterprise':
        setCustomLimit(
          apiKey: apiKey,
          maxRequests: 100000,
          window: Duration(hours: 1),
        );
      default:
        createLimit(apiKey: apiKey);
    }
  }
}
