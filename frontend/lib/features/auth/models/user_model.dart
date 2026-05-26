class UserModel {
  final String id;
  final String email;
  final String? displayName;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      displayName: map['displayName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
    };
  }
}
