Map<String, dynamic> buildJwks(String publicKeyBase64Url, String keyId) {
  return {
    "keys": [
      {
        "kty": "OKP",
        "crv": "Ed25519",
        "use": "sig",
        "alg": "EdDSA",
        "kid": keyId,
        "x": publicKeyBase64Url,
      }
    ]
  };
}
