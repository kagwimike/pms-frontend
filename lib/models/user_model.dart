import 'dart:convert';

class UserModel {
  final dynamic id;
  final String username;
  final String email;
  final String role;
  final String firstName;
  final String lastName;
  final bool isVerified;
  final bool isActive;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.firstName = '',
    this.lastName = '',
    this.isVerified = false,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'GUEST',
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      isVerified: json['is_verified'] ?? json['isVerified'] ?? false,
      isActive: json['is_active'] ?? json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'first_name': firstName,
      'last_name': lastName,
      'is_verified': isVerified,
      'is_active': isActive,
    };
  }

  String toRawJson() => json.encode(toJson());

  factory UserModel.fromRawJson(String str) => UserModel.fromJson(json.decode(str));
}
