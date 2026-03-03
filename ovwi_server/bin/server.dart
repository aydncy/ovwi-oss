import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import '../lib/integrity_engine.dart';

void main() async {
  final integrityEngine = IntegrityEngine();

  final router = Router();

  // Health check
  router.get('/', (Request request) {
    return Response.ok('OVWI Server Running');
  });

  // Append event
  router.post('/api/v1/workflows', (Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);

    final workflowId = data["workflow_id"];
    final eventId = data["event_id"];

    if (workflowId == null || eventId == null) {
      return Response(400, body: "workflow_id and event_id required");
    }

    final event = integrityEngine.appendEvent(
      workflowId,
      eventId,
      data,
    );

    return Response.ok(
      jsonEncode(event.toJson()),
      headers: {"Content-Type": "application/json"},
    );
  });

  // Get chain
  router.get('/api/v1/chain/<workflowId>',
      (Request request, String workflowId) {
    final chain = integrityEngine.getChain(workflowId);

    return Response.ok(
      jsonEncode(chain),
      headers: {"Content-Type": "application/json"},
    );
  });

  // Verify chain
  router.get('/api/v1/verify/<workflowId>',
      (Request request, String workflowId) {
    final valid = integrityEngine.verifyChain(workflowId);

    return Response.ok(
      jsonEncode({
        "workflow_id": workflowId,
        "chain_valid": valid
      }),
      headers: {"Content-Type": "application/json"},
    );
  });

  // Proof (signed + git anchored)
  router.get('/api/v1/proof/<workflowId>',
      (Request request, String workflowId) async {
    final proof = await integrityEngine.generateProof(workflowId);

    return Response.ok(
      jsonEncode(proof),
      headers: {"Content-Type": "application/json"},
    );
  });

  // Proof Pack (human readable + machine readable)
  router.get('/api/v1/proof-pack/<workflowId>',
      (Request request, String workflowId) async {
    final proof = await integrityEngine.generateProof(workflowId);

    final summary = """
OVWI PROOF PACK
====================

Workflow ID: ${proof["workflow_id"]}
Event Count: ${proof["event_count"]}
Chain Valid: ${proof["chain_valid"]}
Root Hash: ${proof["root_hash"]}
Proof Hash: ${proof["proof_hash"]}
Git Commit: ${proof["git_commit_hash"]}
Signature: ${proof["signature"]}
Generated At: ${proof["generated_at"]}

====================
EVENT TIMELINE
====================
""";

    final events = (proof["chain"] as List)
        .map((e) =>
            "- ${e["timestamp"]} | ${e["event_id"]} | hash=${e["hash"]}")
        .join("\n");

    final pack = {
      "proof": proof,
      "human_readable_summary": summary + events
    };

    return Response.ok(
      jsonEncode(pack),
      headers: {"Content-Type": "application/json"},
    );
  });

  final handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(router);

  final server = await io.serve(handler, '0.0.0.0', 8080);
  print('OVWI Server listening on port ${server.port}');
}