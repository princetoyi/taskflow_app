import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../core/services/notification_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<SignupRequested>(_onSignupRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.checkAuthStatus();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (error) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(Authenticated(user));
      // Register FCM token for this device with backend
      NotificationService().registerToken();
    } catch (error) {
      final message = _mapExceptionToMessage(error);
      emit(AuthError(message));
      emit(Unauthenticated());
    }
  }

  Future<void> _onSignupRequested(
    SignupRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signup(
        name: event.name,
        email: event.email,
        password: event.password,
        role: event.role,
      );
      emit(Authenticated(user));
      // Register FCM token after successful signup
      NotificationService().registerToken();
    } catch (error) {
      final message = _mapExceptionToMessage(error);
      emit(AuthError(message));
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.logout();
      emit(Unauthenticated());
    } catch (error) {
      final message = _mapExceptionToMessage(error);
      emit(AuthError(message));
      emit(Unauthenticated());
    }
  }

  String _mapExceptionToMessage(Object exception) {
    if (exception is FormatException) {
      return exception.message;
    }
    if (exception is Exception) {
      return exception.toString();
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
