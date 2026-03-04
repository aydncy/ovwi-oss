import 'package:shelf/shelf.dart';

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

      if (apiKey == demoKey || apiKey == secretKey) {
        return innerHandler(request);
      }

      return Response(401, body: "Invalid API key");
    };
  };
}
