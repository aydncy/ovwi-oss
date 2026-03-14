class ApiKey {
  final String id;
  final String developerId;
  final String keyPrefix;
  final String keyHash;
  final String? name;
  final String environment;
  final String status;
  final DateTime? lastUsedAt;
  final DateTime createdAt;
  final DateTime? revokedAt;

  ApiKey({
    required this.id,
    required this.developerId,
    required this.keyPrefix,
    required this.keyHash,
    this.name,
    this.environment = 'live',
    this.status = 'active',
    this.lastUsedAt,
    required this.createdAt,
    this.revokedAt,
  });

  factory ApiKey.fromJson(Map<String, dynamic> json) {
    return ApiKey(
      id: json['id'] as String,
      developerId: json['developer_id'] as String,
      keyPrefix: json['key_prefix'] as String,
      keyHash: json['key_hash'] as String,
      name: json['name'] as String?,
      environment: json['environment'] as String? ?? 'live',
      status: json['status'] as String? ?? 'active',
      lastUsedAt: json['last_used_at'] != null ? DateTime.parse(json['last_used_at']) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      revokedAt: json['revoked_at'] != null ? DateTime.parse(json['revoked_at']) : null,
    );
  }
}