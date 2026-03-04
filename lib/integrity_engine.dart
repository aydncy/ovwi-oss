import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';

class IntegrityEngine {
  final File _keyFile = File("keys.json");
  final Ed25519 _algorithm = Ed25519();

  Map<String, SimpleKeyPair> _signingKeys = {};
  Map<String, SimplePublicKey> _publicKeys = {};
  String? _activeKid;

  Future<void> _loadKeys() async {
    if (_signingKeys.isNotEmpty) return;

    if (!_keyFile.existsSync()) {
      await _generateNewKey();
      return;
    }

    final data = jsonDecode(_keyFile.readAsStringSync());
    _activeKid = data["active_kid"];

    for (var k in data["keys"]) {
      final kid = k["kid"];
      final privateBytes = base64Decode(k["private"]);

      final keyPair =
          await _algorithm.newKeyPairFromSeed(privateBytes);

      final publicKey = await keyPair.extractPublicKey();

      _signingKeys[kid] = keyPair;
      _publicKeys[kid] = publicKey;
    }
  }

  Future<void> _generateNewKey() async {
    final keyPair = await _algorithm.newKeyPair();
    final privateBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();

    final kid =
        "ovwi-ed25519-${DateTime.now().millisecondsSinceEpoch}";

    _signingKeys[kid] = keyPair;
    _publicKeys[kid] = publicKey;
    _activeKid = kid;

    await _persistKeys();
  }

  Future<void> _persistKeys() async {
    final keys = [];

    for (var entry in _signingKeys.entries) {
      final privateBytes =
          await entry.value.extractPrivateKeyBytes();

      keys.add({
        "kid": entry.key,
        "private": base64Encode(privateBytes),
        "created_at":
            DateTime.now().millisecondsSinceEpoch ~/ 1000,
        "status": entry.key == _activeKid
            ? "active"
            : "deprecated"
      });
    }

    final data = {
      "active_kid": _activeKid,
      "keys": keys
    };

    _keyFile.writeAsStringSync(jsonEncode(data));
  }

  Future<List<Map<String, dynamic>>> getJwks() async {
    await _loadKeys();

    return _publicKeys.entries.map((entry) {
      return {
        "kty": "OKP",
        "crv": "Ed25519",
        "x": base64UrlEncode(entry.value.bytes)
            .replaceAll('=', ''),
        "use": "sig",
        "alg": "EdDSA",
        "kid": entry.key
      };
    }).toList();
  }

  Future<String> issueJwt(String subject) async {
    await _loadKeys();

    final now = DateTime.now().toUtc();
    final exp = now.add(Duration(hours: 1));

    final header = {
      "alg": "EdDSA",
      "typ": "JWT",
      "kid": _activeKid
    };

    final payload = {
      "iss": "ovwi",
      "sub": subject,
      "iat": now.millisecondsSinceEpoch ~/ 1000,
      "exp": exp.millisecondsSinceEpoch ~/ 1000,
    };

    final encodedHeader =
        base64UrlEncode(utf8.encode(jsonEncode(header)))
            .replaceAll('=', '');

    final encodedPayload =
        base64UrlEncode(utf8.encode(jsonEncode(payload)))
            .replaceAll('=', '');

    final signingInput =
        "$encodedHeader.$encodedPayload";

    final signature = await _algorithm.sign(
      utf8.encode(signingInput),
      keyPair: _signingKeys[_activeKid]!,
    );

    final encodedSignature =
        base64UrlEncode(signature.bytes)
            .replaceAll('=', '');

    return "$signingInput.$encodedSignature";
  }

  Future<Map<String, dynamic>> verifyJwt(String token) async {
    await _loadKeys();

    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception("Invalid JWT format");
    }

    final header = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[0])))
    );

    final kid = header['kid'];
    if (!_publicKeys.containsKey(kid)) {
      throw Exception("Unknown key id");
    }

    final signingInput = "${parts[0]}.${parts[1]}";
    final signatureBytes =
        base64Url.decode(base64Url.normalize(parts[2]));

    final publicKey = _publicKeys[kid]!;

    final isValid = await _algorithm.verify(
      utf8.encode(signingInput),
      signature: Signature(signatureBytes,
          publicKey: publicKey),
    );

    if (!isValid) {
      throw Exception("Invalid signature");
    }

    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
    );

    return payload;
  }

  Future<String> rotateKey() async {
    await _generateNewKey();
    return _activeKid!;
  }

  Future<void> revokeKey(String kid) async {
    _signingKeys.remove(kid);
    _publicKeys.remove(kid);

    if (_activeKid == kid) {
      await _generateNewKey();
    }

    await _persistKeys();
  }
}
