class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? phoneNumber;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phoneNumber,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      role: json['role'],
      phoneNumber: json['phoneNumber'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
      'phoneNumber': phoneNumber,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Role helpers
  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isWaiter => role.toLowerCase() == 'waiter';
  bool get isBartender => role.toLowerCase() == 'bartender';
}
