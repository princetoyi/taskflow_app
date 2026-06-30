import 'package:equatable/equatable.dart';

enum UserRole {
  manager,
  employee,
  admin,
}

class UserModel extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? profileImageUrl;
  final UserRole? role;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.profileImageUrl,
    this.role,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a UserModel from JSON (API response)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['uid']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      displayName: json['displayName'] ?? json['display_name'] ?? json['name'],
      firstName: json['firstName'] ?? json['first_name'],
      lastName: json['lastName'] ?? json['last_name'],
      phoneNumber: json['phoneNumber'] ?? json['phone_number'],
      profileImageUrl: json['profileImageUrl'] ?? json['profile_image_url'] ?? json['photo_url'],
      role: _parseRole(json['role']),
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
    );
  }

  /// Converts UserModel to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'role': role?.name,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    }..removeWhere((key, value) => value == null);
  }

  /// Creates a UserModel from a Firestore map
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? map['display_name'],
      firstName: map['firstName'] ?? map['first_name'],
      lastName: map['lastName'] ?? map['last_name'],
      phoneNumber: map['phoneNumber'] ?? map['phone_number'],
      profileImageUrl:
          map['profileImageUrl'] ?? map['profile_image_url'],
      role: _parseRole(map['role']),
      isActive: map['isActive'] ?? map['is_active'] ?? true,
      createdAt: _parseDateTime(map['createdAt'] ?? map['created_at']),
      updatedAt: _parseDateTime(map['updatedAt'] ?? map['updated_at']),
    );
  }

  /// Converts UserModel to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'role': role?.name,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Returns the user's full name
  String get fullName {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    final parts = <String>[];
    if (firstName != null && firstName!.isNotEmpty) parts.add(firstName!);
    if (lastName != null && lastName!.isNotEmpty) parts.add(lastName!);
    if (parts.isNotEmpty) return parts.join(' ');
    return email;
  }

  /// Returns the user's initials for avatar
  String get initials {
    final name = fullName;
    if (name.isEmpty) return 'U';
    return name.split(' ').map((e) => e[0].toUpperCase()).join();
  }

  /// Checks if user is a manager
  bool get isManager => role == UserRole.manager;

  /// Checks if user is an admin
  bool get isAdmin => role == UserRole.admin;

  /// Checks if user is an employee
  bool get isEmployee => role == UserRole.employee;

  /// Creates a copy with modified fields
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImageUrl,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        firstName,
        lastName,
        phoneNumber,
        profileImageUrl,
        role,
        isActive,
        createdAt,
        updatedAt,
      ];

  /// Parses role string to enum
  static UserRole? _parseRole(dynamic value) {
    if (value == null) return null;
    if (value is UserRole) return value;
    if (value is String) {
      return UserRole.values.firstWhere(
        (e) => e.name == value,
        orElse: () => UserRole.employee,
      );
    }
    return null;
  }

  /// Parses datetime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
