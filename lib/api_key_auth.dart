import 'package:shelf/shelf.dart';
import 'usage_store.dart';

final usageStore = UsageStore();

Middleware apiKeyAuthMiddleware() {

  const demoKey = "demo-public-key";
  final secretKey = const String.fromEnvironment(
    "OVWI_API_SECRET",
    defaultValue: "",
  );

  return (Handler innerHandler) {
    return (Request request) async {

      final apiKey = request.headers["x-api-key"];

      if (apiKey == null) {
        return Response(401, body: "Missing API key");
      }

      if (apiKey != demoKey && apiKey != secretKey) {
        return Response(401, body: "Invalid API key");
      }

      final allowed = usageStore.checkAndIncrement(apiKey);

      if (!allowed) {
        return Response(429, body: "Demo usage limit exceeded");
      }

      return innerHandler(request);
    };
  };
}
