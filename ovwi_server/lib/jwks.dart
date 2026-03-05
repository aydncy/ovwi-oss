import 'dart:convert';
import 'package:shelf/shelf.dart';

Response jwksHandler(Request request) {
  final jwks = {
    "keys": [
      {
        "kty": "OKP",
        "crv": "Ed25519",
        "use": "sig",
        "alg": "EdDSA",
        "kid": "ovwi-key-1",
        "x": "vd6T3Ck3bV9GvFvX7n8P3gGxqXW6nB9H7d6R5zK1q2U"
      }
    ]
  };

  return Response.ok(
    jsonEncode(jwks),
    headers: {"content-type": "application/json"},
  );
}
