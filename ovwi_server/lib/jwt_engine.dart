import 'dart:convert';
import 'dart:io';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

late List<int> privateKeyBytes;
late List<int> publicKeyBytes;

const String keyId = "ovwi-key-1";
const String issuer = "ovwi";
const String audience = "ovwi-api";

void initJwt() {
  final privateB64 = Platform.environment['OVWI_PRIVATE_KEY'];
  final publicB64 = Platform.environment['OVWI_PUBLIC_KEY'];

  if (privateB64 == null || publicB64 == null) {
    throw Exception("Missing OVWI key environment variables");
  }

  privateKeyBytes = base64Decode(privateB64);
  publicKeyBytes = base64Decode(publicB64);
}

String generateJwt(String subject) {
  final now = DateTime.now();
  final exp = now.add(const Duration(minutes: 5));

  final jwt = JWT(
    {
      'iss': issuer,
      'sub': subject,
      'aud': audience,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': exp.millisecondsSinceEpoch ~/ 1000,
    },
    header: {
      'alg': 'EdDSA',
      'kid': keyId,
      'typ': 'JWT'
    },
  );

  return jwt.sign(
    EdDSAPrivateKey(privateKeyBytes),
    algorithm: JWTAlgorithm.EdDSA,
  );
}

String getPublicKeyBase64Url() {
  return base64UrlEncode(publicKeyBytes).replaceAll('=', '');
}
