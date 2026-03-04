import 'dart:convert';
import 'dart:io';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

late List<int> privateKeyBytes;
late List<int> publicKeyBytes;

void initJwt() {
  final privateB64 =
      File('ovwi_server/private.b64').readAsStringSync().trim();
  final publicB64 =
      File('ovwi_server/public.b64').readAsStringSync().trim();

  privateKeyBytes = base64Decode(privateB64);
  publicKeyBytes = base64Decode(publicB64);
}

String generateJwt(String subject) {
  final jwt = JWT({
    'iss': 'ovwi',
    'sub': subject,
    'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
  });

  return jwt.sign(
    EdDSAPrivateKey(privateKeyBytes),
    algorithm: JWTAlgorithm.EdDSA,
  );
}

String getPublicKeyBase64Url() {
  return base64UrlEncode(publicKeyBytes).replaceAll('=', '');
}
