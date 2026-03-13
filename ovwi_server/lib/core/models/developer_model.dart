class Developer {
  final int id;
  final String email;
  final String passwordHash;
  final String? jwtSecret;
  final DateTime createdAt;

  Developer({
    required this.id,
    required this.email,
    required this.passwordHash,
    this.jwtSecret,
    required this.createdAt,
  });
}
