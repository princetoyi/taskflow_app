import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/data/repositories/user_repository.dart';
import '../../../auth/models/user_model.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UserRepository userRepository;

  ProfileBloc({required this.userRepository}) : super(const ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfileRequested>(_onUpdateProfile);
    on<ChangePasswordRequested>(_onChangePassword);
  }

  UserModel? get _currentProfile {
    final current = state;
    if (current is ProfileLoaded) return current.profile;
    if (current is ProfileActionSuccess) return current.profile;
    if (current is ProfileError) return current.profile;
    return null;
  }

  Future<void> _onLoadProfile(LoadProfile event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    try {
      final profile = await userRepository.getCurrentUserProfile();
      emit(ProfileLoaded(profile));
    } catch (error) {
      emit(ProfileError(_mapError(error)));
    }
  }

  Future<void> _onUpdateProfile(UpdateProfileRequested event, Emitter<ProfileState> emit) async {
    final current = _currentProfile;
    if (current == null) return;
    try {
      final updated = await userRepository.updateProfile(
        current.copyWith(
          displayName: event.displayName,
          firstName: event.firstName,
          lastName: event.lastName,
          phoneNumber: event.phoneNumber,
        ),
      );
      emit(ProfileActionSuccess('Profile updated', updated));
    } catch (error) {
      emit(ProfileError(_mapError(error), profile: current));
    }
  }

  Future<void> _onChangePassword(ChangePasswordRequested event, Emitter<ProfileState> emit) async {
    final current = _currentProfile;
    try {
      await userRepository.changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      if (current != null) {
        emit(ProfileActionSuccess('Password changed successfully', current));
      }
    } catch (error) {
      emit(ProfileError(_mapError(error), profile: current));
    }
  }

  String _mapError(Object error) {
    return error is Exception
        ? error.toString().replaceFirst('Exception: ', '')
        : 'Something went wrong. Please try again.';
  }
}
