import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:http/http.dart' as http;

Future<Response> handler(Request req) async {

  if (req.url.path == 'health') {
    return Response.ok('ok');
  }

  if (req.url.path == 'webhook/gumroad' && req.method == 'POST') {
    try {
      final body = await req.readAsString();
      final data = jsonDecode(body);

      final email = data['email'] ?? 'fallback@test.com';

      final apiKey = 'ovwi_live_' + DateTime.now().millisecondsSinceEpoch.toString();

      await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer re_cpdRkugz_Ph1E72bb94Nj1XCZe3YyioXS,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "from": "OVWI <onboarding@resend.dev>",
          "to": [email],
          "subject": "Your API Key",
          "html": "<strong>Your API Key:</strong><br><br>$apiKey"
        }),
      );

      return Response.ok(jsonEncode({"ok": true}), headers: {'Content-Type': 'application/json'});

    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  return Response.notFound('not found');
}

void main(List<String> args) async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await io.serve(handler, '0.0.0.0', port);
  print('Server running on port ${server.port}');
}
