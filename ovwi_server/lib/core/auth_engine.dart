import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:base32/base32.dart';

class OvwiAuthEngine {

  static const String prefix = "ovwi_live_";
  static const String secret = "OVWI_SECRET_2026_CHANGE_ME";

  static String generateApiKey() {

    final random = Random.secure();

    final bytes =
        List<int>.generate(32, (_) => random.nextInt(256));

    final body =
        base32.encode(Uint8List.fromList(bytes))
        .replaceAll("=", "")
        .toLowerCase();

    final checksum = _checksum(body);

    return "$prefix$body$checksum";
  }

  static bool isFormatValid(String apiKey) {

    if (!apiKey.startsWith(prefix)) return false;

    final payload = apiKey.substring(prefix.length);

    if (payload.length < 12) return false;

    final body =
        payload.substring(0, payload.length - 8);

    final checksum =
        payload.substring(payload.length - 8);

    final expected = _checksum(body);

    return checksum == expected;
  }

  static String hashKey(String apiKey) {
    return sha256
        .convert(utf8.encode(apiKey))
        .toString();
  }

  static String _checksum(String input) {

    final hmacSha256 =
        Hmac(sha256, utf8.encode(secret));

    final digest =
        hmacSha256.convert(utf8.encode(input));

    return digest.toString().substring(0, 8);
  }

}