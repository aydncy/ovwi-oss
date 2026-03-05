import 'dart:convert';

Map<String, dynamic> buildJwks(String publicKey, String kid) {
  final keyBytes = base64Decode(publicKey);
  final x = base64UrlEncode(keyBytes).replaceAll("=", "");

  return {
    "keys": [
      {
        "kty": "OKP",
        "crv": "Ed25519",
        "use": "sig",
        "alg": "EdDSA",
        "kid": kid,
        "x": x
      }
    ]
  };
}
