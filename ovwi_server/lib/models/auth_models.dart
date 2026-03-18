class Developer {
  final String id;
  final String email;
  final String passwordHash;
  final String name;
  final bool isActive;
  final DateTime createdAt;

  Developer({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.name,
    required this.isActive,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final Developer developer;
  final DateTime expiresAt;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.developer,
    required this.expiresAt,
  });

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'developer': developer.toJson(),
    'expires_at': expiresAt.toIso8601String(),
  };
}








