import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class StorageService {
  final FlutterSecureStorage _storage;

  StorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.unlocked),
        );

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.jwtTokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.jwtTokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.jwtTokenKey);
  }

  Future<void> saveThemeMode(String mode) async {
    await _storage.write(key: AppConstants.themeModeKey, value: mode);
  }

  Future<String?> getThemeMode() async {
    return await _storage.read(key: AppConstants.themeModeKey);
  }

  Future<void> saveFcmToken(String token) async {
    await _storage.write(key: AppConstants.fcmTokenKey, value: token);
  }

  Future<String?> getFcmToken() async {
    return await _storage.read(key: AppConstants.fcmTokenKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
