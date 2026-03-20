import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:http/http.dart' as http;

Future<Response> handler(Request req) async {

  // HEALTH
  if (req.url.path == 'health') {
    return Response.ok('ok');
  }

  // GUMROAD WEBHOOK
  if (req.url.path == 'webhook/gumroad' && req.method == 'POST') {
    final body = await req.readAsString();
    final data = jsonDecode(body);

    final email = data['email'];

    final apiKey = 'ovwi_live_' + DateTime.now().millisecondsSinceEpoch.toString();

    // RESEND EMAIL
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
  }

  return Response.notFound('not found');
}

void main(List<String> args) async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await io.serve(handler, '0.0.0.0', port);
  print('Server running on port ${server.port}');
}
