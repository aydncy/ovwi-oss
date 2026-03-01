import 'dart:convert';
import 'package:shelf/shelf.dart';

Future<Response> importWorkflow(Request request) async {
  final body = await request.readAsString();
  final data = jsonDecode(body);

  if (data["workflow_id"] == null) {
    return Response(400, body: "workflow_id missing");
  }

  return Response.ok(jsonEncode({
    "status": "received",
    "workflow_id": data["workflow_id"]
  }));
}
