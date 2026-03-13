import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';

Future<void> main() async {
  final base64Key =
      (await File('ovwi_ed25519.key').readAsString()).trim();

  final privateKeyBytes = base64Decode(base64Key);

  if (privateKeyBytes.length != 32) {
    print('Private key is not 32-byte seed. Found: ${privateKeyBytes.length}');
    return;
  }

  final algorithm = Ed25519();

  final keyPair = await algorithm.newKeyPairFromSeed(privateKeyBytes);
  final publicKey = await keyPair.extractPublicKey();

  await File('ovwi_ed25519.pub')
      .writeAsBytes(publicKey.bytes);

  print('Public key extracted successfully.');
}
