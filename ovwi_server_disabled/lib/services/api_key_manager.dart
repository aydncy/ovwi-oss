import 'dart:math';

class ApiKeyService {
  static final List<String> _keys = [];

  static String generateKey() {
    final rand = Random.secure();
    final values = List<int>.generate(32, (_) => rand.nextInt(256));
    final key = values.map((e) => e.toRadixString(16).padLeft(2,'0')).join();
    final apiKey = "ovwi_" + key;
    _keys.add(apiKey);
    return apiKey;
  }

  static List<String> listKeys() {
    return _keys;
  }

  static bool revokeKey(String key) {
    return _keys.remove(key);
  }

  static bool isValid(String key) {
    return _keys.contains(key);
  }
}








