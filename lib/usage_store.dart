class UsageStore {
  final Map<String, int> _usage = {};

  static const int demoLimit = 1000;

  bool checkAndIncrement(String apiKey) {
    _usage.putIfAbsent(apiKey, () => 0);
    _usage[apiKey] = _usage[apiKey]! + 1;

    if (apiKey == "demo-public-key") {
      return _usage[apiKey]! <= demoLimit;
    }

    // Paid keys unlimited
    return true;
  }

  int getUsage(String apiKey) {
    return _usage[apiKey] ?? 0;
  }
}
