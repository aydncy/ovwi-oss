import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';

class WorkflowEvent {
  final String workflowId;
  final String eventId;
  final String payload;
  final String previousHash;
  final String hash;
  final DateTime timestamp;

  WorkflowEvent({
    required this.workflowId,
    required this.eventId,
    required this.payload,
    required this.previousHash,
    required this.hash,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        "workflow_id": workflowId,
        "event_id": eventId,
        "payload": jsonDecode(payload),
        "previous_hash": previousHash,
        "hash": hash,
        "timestamp": timestamp.toIso8601String(),
      };

  static WorkflowEvent fromJson(Map<String, dynamic> json) {
    return WorkflowEvent(
      workflowId: json["workflow_id"],
      eventId: json["event_id"],
      payload: jsonEncode(json["payload"]),
      previousHash: json["previous_hash"],
      hash: json["hash"],
      timestamp: DateTime.parse(json["timestamp"]),
    );
  }
}

class IntegrityEngine {
  final Map<String, List<WorkflowEvent>> _chains = {};
  final Map<String, WorkflowEvent> _eventIndex = {};
  final File _storage = File("ovwi_chain.json");

  // 🔐 Signature layer
  final Ed25519 _algorithm = Ed25519();
  SimpleKeyPair? _keyPair;
  SimplePublicKey? _publicKey;

  IntegrityEngine() {
    _loadFromDisk();
  }

  // =========================
  // Key initialization
  // =========================

  Future<void> _initKeys() async {
    if (_keyPair == null) {
      _keyPair = await _algorithm.newKeyPair();
      _publicKey = await _keyPair!.extractPublicKey();
    }
  }

  // =========================
  // Storage
  // =========================

  void _loadFromDisk() {
    if (_storage.existsSync()) {
      final content = _storage.readAsStringSync();
      if (content.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(content);

        decoded.forEach((workflowId, events) {
          final List<WorkflowEvent> chain = [];
          for (var item in events) {
            final event = WorkflowEvent.fromJson(item);
            chain.add(event);
            _eventIndex[event.eventId] = event;
          }
          _chains[workflowId] = chain;
        });
      }
    }
  }

  void _persistToDisk() {
    final Map<String, dynamic> export = {};
    _chains.forEach((workflowId, chain) {
      export[workflowId] =
          chain.map((e) => e.toJson()).toList();
    });
    _storage.writeAsStringSync(jsonEncode(export));
  }

  // =========================
  // Hashing
  // =========================

  String _calculateHash(String data) {
    final bytes = utf8.encode(data);
    return sha256.convert(bytes).toString();
  }

  String _canonicalJson(Map<String, dynamic> json) {
    final sortedKeys = json.keys.toList()..sort();
    final Map<String, dynamic> sortedMap = {};
    for (var key in sortedKeys) {
      sortedMap[key] = json[key];
    }
    return jsonEncode(sortedMap);
  }

  String _getGitCommitHash() {
    try {
      final result = Process.runSync('git', ['rev-parse', 'HEAD']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (_) {}
    return "unknown";
  }

  // =========================
  // Core logic
  // =========================

  WorkflowEvent appendEvent(
    String workflowId,
    String eventId,
    Map<String, dynamic> json,
  ) {
    if (_eventIndex.containsKey(eventId)) {
      return _eventIndex[eventId]!;
    }

    final canonicalPayload = _canonicalJson(json);
    final chain = _chains.putIfAbsent(workflowId, () => []);

    final previousHash =
        chain.isEmpty ? "GENESIS" : chain.last.hash;

    final combined = "$previousHash|$canonicalPayload";
    final hash = _calculateHash(combined);

    final event = WorkflowEvent(
      workflowId: workflowId,
      eventId: eventId,
      payload: canonicalPayload,
      previousHash: previousHash,
      hash: hash,
      timestamp: DateTime.now().toUtc(),
    );

    chain.add(event);
    _eventIndex[eventId] = event;

    _persistToDisk();

    return event;
  }

  bool verifyChain(String workflowId) {
    final chain = _chains[workflowId];
    if (chain == null || chain.isEmpty) return true;

    for (int i = 1; i < chain.length; i++) {
      final current = chain[i];
      final previous = chain[i - 1];

      final recalculated =
          _calculateHash("${current.previousHash}|${current.payload}");

      if (current.previousHash != previous.hash ||
          current.hash != recalculated) {
        return false;
      }
    }
    return true;
  }

  List<Map<String, dynamic>> getChain(String workflowId) {
    final chain = _chains[workflowId] ?? [];
    return chain.map((e) => e.toJson()).toList();
  }

  // =========================
  // Proof generation
  // =========================

  Future<Map<String, dynamic>> generateProof(String workflowId) async {
    await _initKeys();

    final chain = getChain(workflowId);
    final isValid = verifyChain(workflowId);
    final rootHash =
        chain.isEmpty ? null : chain.last["hash"];

    final proof = {
      "protocol": "OVWI-1.0",
      "generated_at": DateTime.now().toUtc().toIso8601String(),
      "hash_algorithm": "SHA-256",
      "workflow_id": workflowId,
      "event_count": chain.length,
      "chain_valid": isValid,
      "root_hash": rootHash,
      "chain": chain
    };

    final hashableProof = {
      "protocol": "OVWI-1.0",
      "hash_algorithm": "SHA-256",
      "workflow_id": workflowId,
      "event_count": chain.length,
      "root_hash": rootHash,
      "chain": chain
    };

    final canonical = jsonEncode(hashableProof);
    final proofHash = _calculateHash(canonical);

    proof["proof_hash"] = proofHash;
    proof["git_commit_hash"] = _getGitCommitHash();

    // 🔐 Sign proof hash
    final signature = await _algorithm.sign(
      utf8.encode(proofHash),
      keyPair: _keyPair!,
    );

    proof["signature"] = base64Encode(signature.bytes);
    proof["public_key"] = base64Encode(_publicKey!.bytes);

    return proof;
  }
}