import 'dart:io';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

String _generateApiKey() {
  final rand = (DateTime.now().microsecondsSinceEpoch ^ Random().nextInt(999999)).toString();
  return "ovwi_live_" + rand;
}

Map<String, List<int>> _rate = {};
void main() async {
  final handler = (Request req) async {
\n    final key = req.url.queryParameters['key'] ?? 'global';
    final now = DateTime.now().millisecondsSinceEpoch;
\n    _rate.putIfAbsent(key, () => []);
    _rate[key]!.removeWhere((t) => now - t > 60000);
    _rate[key]!.add(now);
\n    final limit = key.startsWith('ovwi_live_') ? 120 : 5;
    final rateLimited = _rate[key]!.length > limit;
\n    if (rateLimited) {
      return Response(302, headers: {'Location': 'https://gumroad.com/l/ovwi-pro'});
    }

    if (req.url.path == 'health') {
      return Response.ok('ok');
    }

    if (req.url.path == 'verify-key') {
      final key = req.url.queryParameters['key'] ?? '';
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

    return Response.notFound('not found');
  };

  final server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('Server running on ');
}

