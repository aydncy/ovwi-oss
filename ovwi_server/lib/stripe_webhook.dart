import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'db.dart';

Future<Response> stripeWebhook(Request request) async {
  final body = await request.readAsString();
  final event = jsonDecode(body);

  final type = event['type'];

  if (type == 'checkout.session.completed') {
    final email = event['data']['object']['customer_details']['email'];
    final plan = event['data']['object']['metadata']['plan'];

    final newKey = "ovwi_${DateTime.now().millisecondsSinceEpoch}";
    int limit = plan == 'pro' ? 500000 : 50000;

    insertKey(newKey, email, limit);

    print("🔥 Created API key for $email → $newKey");
  }

  return Response.ok('ok');
}
