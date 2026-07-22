import 'package:equatable/equatable.dart';
import '../../../auth/models/user_model.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final UserModel profile;

  const ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Transient state for a successful update/password-change — the listener
/// shows a snackbar for it, and the builder renders it identically to
/// [ProfileLoaded] so the form never flashes empty in between.
class ProfileActionSuccess extends ProfileState {
  final String message;
  final UserModel profile;

  const ProfileActionSuccess(this.message, this.profile);

  @override
  List<Object?> get props => [message, profile];
}

/// [profile] carries the last known-good data so a failed update/password
/// change doesn't blank out the form — only the initial load has no
/// profile to fall back on.
class ProfileError extends ProfileState {
  final String message;
  final UserModel? profile;

  const ProfileError(this.message, {this.profile});

  @override
  List<Object?> get props => [message, profile];
}
