import 'dart:io';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

late EdDSAPrivateKey privateKey;

void initJwt() {
  final pem = File('ovwi_ed25519.key').readAsStringSync();
  privateKey = EdDSAPrivateKey.fromPEM(pem);
}

String generateJwt(String subject) {
  final jwt = JWT({
    'iss': 'ovwi',
    'sub': subject,
    'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
  });

  return jwt.sign(
    privateKey,
    algorithm: JWTAlgorithm.EdDSA,
  );
}
