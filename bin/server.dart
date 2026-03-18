import 'dart:io';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

String _generateApiKey() {
  final rand = (DateTime.now().microsecondsSinceEpoch ^ Random().nextInt(999999)).toString();
  return "ovwi_live_" + rand;
}

final Map<String, List<int>> _rate = {};

bool isRateLimited(String key, int limit) {
  final now = DateTime.now().millisecondsSinceEpoch;

  _rate.putIfAbsent(key, () => []);
  _rate[key]!.removeWhere((t) => now - t > 60000);
  _rate[key]!.add(now);

  return _rate[key]!.length > limit;
}

void main() async {
  final handler = (Request req) async {

    final key = req.url.queryParameters['key'] ?? 'global';
    final limit = key.startsWith('ovwi_live_') ? 120 : 5;

    if (isRateLimited(key, limit)) {
      return Response(302, headers: {'Location': 'https://gumroad.com/l/ovwi-pro'});
    }

    if (req.url.path == 'health') {
      return Response.ok('ok');
    }

    if (req.url.path == 'verify-key') {
      if (!key.startsWith('ovwi_live_')) {
        return Response.forbidden('invalid');
      }
      return Response.ok('ok');
    }

    if (req.url.path == 'payment/success') {
      final token = req.url.queryParameters['token'] ?? '';
      if (token.isEmpty) {
        return Response(400, body: 'missing token');
      }

      final apiKey = _generateApiKey();

      return Response.ok(
        '{"ok":true,"api_key":"'+apiKey+'","plan":"pro"}',
        headers: {'Content-Type': 'application/json'},
      );
    }

    
if (req.url.path == 'gumroad/webhook' && req.method == 'POST') {
  final body = await req.readAsString();
  final data = Uri.splitQueryString(body);

  final apiKey = "ovwi_live_" + DateTime.now().microsecondsSinceEpoch.toString();

  return Response.ok(
    '<h1>Your API Key</h1><p style="font-size:20px;">' + apiKey + '</p>',
    headers: {'Content-Type': 'text/html'},
  );
}

return Response.notFound('not found');
  };

  final server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('Server running on ');
}



