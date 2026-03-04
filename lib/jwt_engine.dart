import 'dart:io';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

late String privateKeyPem;

void initJwt() {
  privateKeyPem = File('ovwi_ed25519.key').readAsStringSync();
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
