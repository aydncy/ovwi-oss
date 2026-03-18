class OAuth2Client {
  final String clientId;
  final String clientSecret;
  final List<String> redirectUris;
  final List<String> scopes;
  final DateTime createdAt;
  bool active;

  OAuth2Client({
    required this.clientId,
    required this.clientSecret,
    required this.redirectUris,
    required this.scopes,
    required this.createdAt,
    this.active = true,
  });

  Map<String, dynamic> toJson() => {
    'clientId': clientId,
    'redirectUris': redirectUris,
    'scopes': scopes,
    'createdAt': createdAt.toIso8601String(),
    'active': active,
  };
}

class OAuth2Token {
  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final int expiresIn;
  final List<String> grantedScopes;
  final DateTime issuedAt;

  OAuth2Token({
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn = 3600,
    required this.grantedScopes,
    required this.issuedAt,
  });

  bool isExpired() {
    return DateTime.now().difference(issuedAt).inSeconds > expiresIn;
  }

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'token_type': tokenType,
    'expires_in': expiresIn,
    'scope': grantedScopes.join(' '),
  };
}

class OAuth2Service {
  final Map<String, OAuth2Client> _clients = {};
  final Map<String, String> _authorizationCodes = {};
  final Map<String, OAuth2Token> _tokens = {};

  void registerClient({
    required String clientId,
    required String clientSecret,
    required List<String> redirectUris,
    required List<String> scopes,
  }) {
    final client = OAuth2Client(
      clientId: clientId,
      clientSecret: clientSecret,
      redirectUris: redirectUris,
      scopes: scopes,
      createdAt: DateTime.now(),
    );

    _clients[clientId] = client;
    print('✅ OAuth2 Client registered: $clientId');
    print('   Scopes: ${scopes.join(", ")}');
  }

  String? generateAuthorizationCode(
    String clientId,
    String redirectUri,
    List<String> requestedScopes,
  ) {
    final client = _clients[clientId];
    if (client == null || !client.active) {
      print('❌ Client not found or inactive: $clientId');
      return null;
    }

    if (!client.redirectUris.contains(redirectUri)) {
      print('❌ Invalid redirect URI: $redirectUri');
      return null;
    }

    final code = 'auth_code_${DateTime.now().millisecondsSinceEpoch}';
    _authorizationCodes[code] = clientId;
    print('✅ Authorization code generated: $code');
    return code;
  }

  OAuth2Token? exchangeCodeForToken(
    String code,
    String clientId,
    String clientSecret,
    List<String> requestedScopes,
  ) {
    final storedClientId = _authorizationCodes[code];
    if (storedClientId == null || storedClientId != clientId) {
      print('❌ Invalid authorization code: $code');
      return null;
    }

    final client = _clients[clientId];
    if (client == null || client.clientSecret != clientSecret) {
      print('❌ Client authentication failed: $clientId');
      return null;
    }

    final token = OAuth2Token(
      accessToken: 'access_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'refresh_${DateTime.now().millisecondsSinceEpoch}',
      grantedScopes: requestedScopes,
      issuedAt: DateTime.now(),
    );

    _tokens[token.accessToken] = token;
    _authorizationCodes.remove(code);

    print('✅ Token issued: ${token.accessToken}');
    print('   Scopes: ${requestedScopes.join(", ")}');
    return token;
  }

  OAuth2Token? validateToken(String accessToken) {
    final token = _tokens[accessToken];
    if (token == null || token.isExpired()) {
      print('❌ Invalid or expired token');
      return null;
    }
    print('✅ Token validated: $accessToken');
    return token;
  }

  Map<String, dynamic> getClientInfo(String clientId) {
    final client = _clients[clientId];
    if (client == null) return {};
    return client.toJson();
  }
}








