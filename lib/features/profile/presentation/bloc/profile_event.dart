import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  const LoadProfile();
}

class UpdateProfileRequested extends ProfileEvent {
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;

  const UpdateProfileRequested({
    this.displayName,
    this.firstName,
    this.lastName,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [displayName, firstName, lastName, phoneNumber];
}

class ChangePasswordRequested extends ProfileEvent {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordRequested({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword];
}
