import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/storage_service.dart';
import '../models/auth_user_model.dart';
import '../services/auth_service.dart';
import '../../domain/entities/auth_user.dart';

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

      // Fetch user profile from backend to get role
      final profileData = await apiClient.get<Map<String, dynamic>>('/auth/me');
      
      return AuthUserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        role: _parseRole(profileData['role']),
        isActive: profileData['is_active'] ?? true,
      );
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
    String role = 'employee',
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

      // Creates the Firestore profile with the chosen role — a no-op if it
      // somehow already exists (role is only ever set at creation time).
      final profileData = await apiClient.post<Map<String, dynamic>>(
        '/auth/complete-signup',
        data: {'role': role},
      );

      return AuthUserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? name,
        role: _parseRole(profileData['role']),
        isActive: profileData['is_active'] ?? true,
      );
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
      final profileData = await apiClient.get<Map<String, dynamic>>('/auth/me');
      final firebaseUser = authService.getCurrentUser();
      if (firebaseUser == null) {
        await logout();
        return null;
      }
      
      return AuthUserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? '',
        role: _parseRole(profileData['role']),
        isActive: profileData['is_active'] ?? true,
      );
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

  UserRole _parseRole(dynamic roleValue) {
    if (roleValue == null) return UserRole.employee;
    
    final roleStr = roleValue.toString().toLowerCase();
    switch (roleStr) {
      case 'manager':
        return UserRole.manager;
      case 'admin':
        return UserRole.admin;
      case 'employee':
      default:
        return UserRole.employee;
    }
  }
}
