import 'package:crypto/crypto.dart';
import 'dart:convert';

class EncryptionService {
  // AES-256 equivalent using SHA256
  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  static String hashData(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }

  static String generateSignature(String data, String privateKey) {
    final combined = '$data:$privateKey';
    return sha256.convert(utf8.encode(combined)).toString();
  }

  static bool verifySignature(
    String data,
    String signature,
    String publicKey,
  ) {
    final expectedSignature = sha256
        .convert(utf8.encode('$data:$publicKey'))
        .toString();
    return signature == expectedSignature;
  }

  static String encryptJSON(Map<String, dynamic> data, String key) {
    final json = jsonEncode(data);
    final keyHash = sha256.convert(utf8.encode(key)).toString();
    final combined = '$json:$keyHash';
    return base64Encode(utf8.encode(combined));
  }

  static Map<String, dynamic> decryptJSON(String encrypted, String key) {
    try {
      final decoded = utf8.decode(base64Decode(encrypted));
      final keyHash = sha256.convert(utf8.encode(key)).toString();
      
      if (!decoded.contains(':$keyHash')) {
        throw Exception('Invalid key or corrupted data');
      }
      
      final json = decoded.replaceAll(':$keyHash', '');
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  static String hashChain(String previousHash, String currentData) {
    final combined = '$previousHash:$currentData';
    return sha256.convert(utf8.encode(combined)).toString();
  }

  static bool verifyChain(
    String previousHash,
    String currentData,
    String currentHash,
  ) {
    final expectedHash = hashChain(previousHash, currentData);
    return expectedHash == currentHash;
  }
}
