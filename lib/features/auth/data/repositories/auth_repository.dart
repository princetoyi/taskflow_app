import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/storage_service.dart';
import '../models/auth_user_model.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService authService;
  final ApiClient apiClient;
  final StorageService storageService;
  final ConnectivityService connectivityService;

  AuthRepository({
    required this.authService,
    required this.apiClient,
    required this.storageService,
    required this.connectivityService,
  });

  Future<AuthUserModel> login({
    required String email,
    required String password,
  }) async {
    if (!await connectivityService.hasConnection) {
      throw AppException('No internet connection. Please try again when you are online.');
    }

    try {
      final user = await authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final idToken = await authService.getFirebaseIdToken();
      await storageService.saveToken(idToken);

      await apiClient.get('/auth/me');
      return AuthUserModel.fromFirebaseUser(user);
    } on DioException catch (e) {
      final message = _extractDioMessage(e);
      throw AppException(message);
    } on AppException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Login failure: $e');
      throw AppException('Login failed. Please try again.');
    }
  }

  Future<AuthUserModel> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    if (!await connectivityService.hasConnection) {
      throw AppException('No internet connection. Please try again when you are online.');
    }

    try {
      final user = await authService.signUpWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
      );

      final idToken = await authService.getFirebaseIdToken();
      await storageService.saveToken(idToken);

      await apiClient.get('/auth/me');
      return AuthUserModel.fromFirebaseUser(user);
    } on DioException catch (e) {
      final message = _extractDioMessage(e);
      throw AppException(message);
    } on AppException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Signup failure: $e');
      throw AppException('Registration failed. Please try again.');
    }
  }

  Future<AuthUserModel?> checkAuthStatus() async {
    final token = await storageService.getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      await apiClient.get('/auth/me');
      final firebaseUser = authService.getCurrentUser();
      if (firebaseUser == null) {
        await logout();
        return null;
      }
      return AuthUserModel.fromFirebaseUser(firebaseUser);
    } on DioException {
      await logout();
      return null;
    } on Exception catch (e) {
      debugPrint('Auth status check failed: $e');
      await logout();
      return null;
    }
  }

  Future<void> logout() async {
    final token = await storageService.getToken();
    try {
      if (token != null && token.isNotEmpty) {
        await apiClient.post('/auth/logout');
      }
    } catch (_) {
      // ignore backend logout errors and continue clearing local state
    }
    await authService.signOut();
    await storageService.clearAll();
  }

  String _extractDioMessage(DioException error) {
    if (error.error is AppException) {
      return (error.error as AppException).message;
    }
    return error.response?.data?['detail']?.toString() ?? error.message ?? 'An unexpected error occurred.';
  }
}
