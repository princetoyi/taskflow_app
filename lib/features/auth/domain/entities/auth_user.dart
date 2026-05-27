import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  final String uid;
  final String email;
  final String displayName;

  const AuthUser({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  @override
  List<Object?> get props => [uid, email, displayName];
}
