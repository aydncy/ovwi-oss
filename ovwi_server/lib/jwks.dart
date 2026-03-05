Map<String, dynamic> buildJwks(String? publicKey, String kid) {

  final key = publicKey ?? "";

  final x = key.replaceAll("=", "");

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
