import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';

class IntegrityEngine {
  final Ed25519 _algorithm = Ed25519();
  final File _store = File("keys.json");

  SimpleKeyPair? _keyPair;
  SimplePublicKey? _publicKey;
  String? _kid;

  Future<void> _init() async {
    if (_keyPair != null) return;

    if (_store.existsSync()) {
      final data = jsonDecode(_store.readAsStringSync());
      _kid = data["kid"];
      final seed = base64Decode(data["private"]);
      _keyPair = await _algorithm.newKeyPairFromSeed(seed);
    } else {
      _keyPair = await _algorithm.newKeyPair();
      final seed = await _keyPair!.extractPrivateKeyBytes();
      _kid = "ovwi-${DateTime.now().millisecondsSinceEpoch}";
      _store.writeAsStringSync(jsonEncode({
        "kid": _kid,
        "private": base64Encode(seed)
      }));
    }

    _publicKey = await _keyPair!.extractPublicKey();
  }

  Future<List<Map<String, dynamic>>> getJwks() async {
    await _init();
    return [
      {
        "kty": "OKP",
        "crv": "Ed25519",
        "x": base64UrlEncode(_publicKey!.bytes).replaceAll('=', ''),
        "use": "sig",
        "alg": "EdDSA",
        "kid": _kid
      }
    ];
  }

  Future<String> issueJwt(String subject) async {
    await _init();

    final header = {
      "alg": "EdDSA",
      "typ": "JWT",
      "kid": _kid
    };

    final payload = {
      "iss": "ovwi",
      "sub": subject,
      "iat": DateTime.now().millisecondsSinceEpoch ~/ 1000
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
      keyPair: _keyPair!,
    );

    final encodedSignature =
        base64UrlEncode(signature.bytes)
            .replaceAll('=', '');

    return "$signingInput.$encodedSignature";
  }

  Future<Map<String, dynamic>> verifyJwt(String token) async {
    await _init();

    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception("Invalid JWT");
    }

    final signingInput = "${parts[0]}.${parts[1]}";
    final signatureBytes =
        base64Url.decode(base64Url.normalize(parts[2]));

    final isValid = await _algorithm.verify(
      utf8.encode(signingInput),
      signature: Signature(signatureBytes,
          publicKey: _publicKey!),
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
    _store.deleteSync();
    _keyPair = null;
    await _init();
    return _kid!;
  }

  Future<void> revokeKey(String kid) async {
    if (_kid == kid) {
      await rotateKey();
    }
  }
}








