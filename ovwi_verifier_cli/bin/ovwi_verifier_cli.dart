import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';

String calculateHash(String data) {
  final bytes = utf8.encode(data);
  return sha256.convert(bytes).toString();
}

String canonicalJson(Map<String, dynamic> json) {
  final sortedKeys = json.keys.toList()..sort();
  final Map<String, dynamic> sortedMap = {};
  for (var key in sortedKeys) {
    sortedMap[key] = json[key];
  }
  return jsonEncode(sortedMap);
}

bool verifyChain(List<dynamic> chain) {
  if (chain.isEmpty) return true;

  for (int i = 1; i < chain.length; i++) {
    final current = chain[i];
    final previous = chain[i - 1];

    final recalculated = calculateHash(
        "${current["previous_hash"]}|${canonicalJson(Map<String, dynamic>.from(current["payload"]))}");

    if (current["previous_hash"] != previous["hash"] ||
        current["hash"] != recalculated) {
      return false;
    }
  }

  return true;
}

Future<bool> verifySignature(
    String proofHash,
    String signatureBase64,
    String publicKeyBase64) async {

  final algorithm = Ed25519();

  final signature = Signature(
    base64Decode(signatureBase64),
    publicKey: SimplePublicKey(
      base64Decode(publicKeyBase64),
      type: KeyPairType.ed25519,
    ),
  );

  return await algorithm.verify(
    utf8.encode(proofHash),
    signature: signature,
  );
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print("Usage: dart run bin/ovwi_verifier_cli.dart proof.json");
    exit(1);
  }

  final file = File(args[0]);

  if (!file.existsSync()) {
    print("Proof file not found.");
    exit(1);
  }

  final proof = jsonDecode(file.readAsStringSync());
  final chain = proof["chain"] as List<dynamic>;

  final hashableProof = {
    "protocol": proof["protocol"],
    "hash_algorithm": proof["hash_algorithm"],
    "workflow_id": proof["workflow_id"],
    "event_count": proof["event_count"],
    "root_hash": proof["root_hash"],
    "chain": chain
  };

  final canonical = jsonEncode(hashableProof);
  final recalculatedProofHash = calculateHash(canonical);

  final chainValid = verifyChain(chain);

  final signatureValid = await verifySignature(
    recalculatedProofHash,
    proof["signature"],
    proof["public_key"],
  );

  print("==== OVWI Proof Verification ====");
  print("Workflow ID: ${proof["workflow_id"]}");
  print("Chain Valid: $chainValid");
  print("Proof Hash Valid: ${proof["proof_hash"] == recalculatedProofHash}");
  print("Signature Valid: $signatureValid");
  print("Git Commit: ${proof["git_commit_hash"]}");
  print("");

  if (proof["proof_hash"] == recalculatedProofHash &&
      chainValid &&
      signatureValid) {
    print("STATUS: FULLY VALID (HASH + CHAIN + SIGNATURE)");
  } else {
    print("STATUS: INVALID");
  }
}







