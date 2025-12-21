class AuthResponse {
  final String userId;
  final String fullName;
  final String email;
  final String role;
  final String accessToken;

  AuthResponse({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.accessToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      userId: json['userId'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'Waiter',
      accessToken: json['accessToken'] ?? json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'role': role,
      'accessToken': accessToken,
    };
  }
}
