import 'package:equatable/equatable.dart';

enum UserRole { manager, employee, admin }

class AuthUser extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final UserRole? role;
  final bool isActive;

  const AuthUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.role,
    this.isActive = true,
  });

  /// Check if user is a manager
  bool get isManager => role == UserRole.manager;
  
  /// Check if user is an employee
  bool get isEmployee => role == UserRole.employee;
  
  /// Check if user is an admin
  bool get isAdmin => role == UserRole.admin;

  @override
  List<Object?> get props => [uid, email, displayName, role, isActive];
}
