import 'dart:convert';

Map<String, dynamic> buildJwks(List<int> publicKey, String kid) {

  final x = base64UrlEncode(publicKey).replaceAll("=", "");

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
