import 'dart:convert';
import 'dart:io';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

late String privateKeyPem;
late String publicKeyPem;

void initJwt() {
  privateKeyPem = File('ovwi_server/ovwi_ed25519.key').readAsStringSync();
  publicKeyPem = File('ovwi_server/ovwi_ed25519.pub').readAsStringSync();
}

String generateJwt(String subject) {
  final jwt = JWT({
    'iss': 'ovwi',
    'sub': subject,
    'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
  });

  return jwt.sign(
    EdDSAPrivateKey(privateKeyPem),
    algorithm: JWTAlgorithm.EdDSA,
  );
}

String getPublicKeyBase64Url() {
  final publicKey = EdDSAPublicKey(publicKeyPem);
  final raw = publicKey.bytes;
  return base64UrlEncode(raw).replaceAll('=', '');
}
