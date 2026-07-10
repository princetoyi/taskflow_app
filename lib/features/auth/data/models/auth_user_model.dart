import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.uid,
    required super.email,
    required super.displayName,
    super.role,
    super.isActive,
  });

  factory AuthUserModel.fromFirebaseUser(User user) {
    return AuthUserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      role: UserRole.employee,  // Default role
    );
  }

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    UserRole? role;
    final roleStr = json['role']?.toString().toLowerCase();
    if (roleStr == 'manager') {
      role = UserRole.manager;
    } else if (roleStr == 'admin') {
      role = UserRole.admin;
    } else if (roleStr == 'employee') {
      role = UserRole.employee;
    }

    return AuthUserModel(
      uid: json['uid']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? json['displayName']?.toString() ?? '',
      role: role ?? UserRole.employee,
      isActive: json['is_active'] ?? json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'display_name': displayName,
      'role': role?.toString().split('.').last.toLowerCase(),
      'is_active': isActive,
    };
  }
}
