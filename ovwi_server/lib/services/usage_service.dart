import '../middleware/usage_tracking.dart';

Map<String, dynamic> usageSummary() {
  final result = <String, dynamic>{};

  apiKeyUsage.forEach((k, v) {
    result[k] = v;
  });

  return result;
}
