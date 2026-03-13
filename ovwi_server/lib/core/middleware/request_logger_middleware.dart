import "package:shelf/shelf.dart";

Middleware requestLoggerMiddleware() {
  return (Handler handler) {
    return (Request request) async {
      final start = DateTime.now();

      final response = await handler(request);

      final duration = DateTime.now().difference(start).inMilliseconds;

      print(
        "[${request.method}] ${request.requestedUri.path} "
        "› ${response.statusCode} (${duration}ms)"
      );

      return response;
    };
  };
}
