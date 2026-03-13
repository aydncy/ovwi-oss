import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class JwtVerifyService {
  final SimplePublicKey publicKey;

  JwtVerifyService(this.publicKey);

  Future<Map<String, dynamic>> verify(String token) async {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid JWT format');
    }

    final headerBytes =
        base64Url.decode(base64Url.normalize(parts[0]));
    final payloadBytes =
        base64Url.decode(base64Url.normalize(parts[1]));
    final signatureBytes =
        base64Url.decode(base64Url.normalize(parts[2]));

    final message = utf8.encode('${parts[0]}.${parts[1]}');

    final algorithm = Ed25519();

    final isValid = await algorithm.verify(
      message,
      signature: Signature(
        signatureBytes,
        publicKey: publicKey,
      ),
    );

    if (!isValid) {
      throw Exception('Invalid signature');
    }

    return jsonDecode(utf8.decode(payloadBytes));
  }
}
