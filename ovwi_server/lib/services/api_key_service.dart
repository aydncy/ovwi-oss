import 'dart:convert';
import 'package:crypto/crypto.dart';

class APIKeyCredential {
  final String keyId;
  final String secret;
  final String scope;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool active;

  APIKeyCredential({
    required this.keyId,
    required this.secret,
    required this.scope,
    required this.createdAt,
    this.expiresAt,
    this.active = true,
  });

  bool isExpired() {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool isValid() => active && !isExpired();

  Map<String, dynamic> toJson() => {
    'keyId': keyId,
    'scope': scope,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
    'active': active,
  };
}

class APIKeyService {
  final Map<String, APIKeyCredential> _keys = {};

  String generateKeyId({required String prefix}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return '${prefix}_${timestamp}_${random}';
  }

  String generateSecret() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return sha256.convert(utf8.encode(random)).toString().substring(0, 32);
  }

  APIKeyCredential createAPIKey({
    required String scope,
    Duration? validFor,
  }) {
    final keyId = generateKeyId(prefix: 'key_live');
    final secret = generateSecret();
    final createdAt = DateTime.now();
    final expiresAt = validFor != null ? createdAt.add(validFor) : null;

    final credential = APIKeyCredential(
      keyId: keyId,
      secret: secret,
      scope: scope,
      createdAt: createdAt,
      expiresAt: expiresAt,
      active: true,
    );

    _keys[keyId] = credential;

    print('✅ API Key created: $keyId');
    print('🔐 Secret: $secret');
    print('📊 Scope: $scope');

    return credential;
  }

  APIKeyCredential? validateAPIKey(String keyId, String secret) {
    final credential = _keys[keyId];

    if (credential == null) {
      print('❌ API Key not found: $keyId');
      return null;
    }

    if (!credential.isValid()) {
      print('❌ API Key expired or inactive: $keyId');
      return null;
    }

    if (credential.secret != secret) {
      print('❌ Invalid secret for key: $keyId');
      return null;
    }

    print('✅ API Key validated: $keyId');
    return credential;
  }

  bool revokeAPIKey(String keyId) {
    if (_keys.containsKey(keyId)) {
      _keys[keyId]!.active == false;
      print('✅ API Key revoked: $keyId');
      return true;
    }
    return false;
  }

  List<APIKeyCredential> listAPIKeys() {
    return _keys.values.toList();
  }

  Map<String, dynamic> getAPIKeyStats(String keyId) {
    final credential = _keys[keyId];
    if (credential == null) return {};

    return {
      'keyId': keyId,
      'scope': credential.scope,
      'active': credential.active,
      'isExpired': credential.isExpired(),
      'createdAt': credential.createdAt.toIso8601String(),
      'expiresAt': credential.expiresAt?.toIso8601String(),
    };
  }
}
