import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../constants/app_constants.dart';
import '../services/logger_service.dart';
import '../services/storage_service.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';

class ApiService {
  final Dio client;

  ApiService({required StorageService storageService}) : client = Dio(
          BaseOptions(
            baseUrl: _resolveBaseUrl(),
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        ) {
    client.interceptors.addAll(
      [
        AuthInterceptor(storageService: storageService),
        ErrorInterceptor(),
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          logPrint: (object) => LoggerService.info(object.toString()),
        ),
      ],
    );
  }

  static String _resolveBaseUrl() {
    if (kIsWeb) {
      return dotenv.env[AppConstants.baseUrlWebKey] ?? dotenv.env[AppConstants.baseUrlKey] ?? '';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return dotenv.env[AppConstants.baseUrlAndroidKey] ?? dotenv.env[AppConstants.baseUrlKey] ?? '';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return dotenv.env[AppConstants.baseUrlIosKey] ?? dotenv.env[AppConstants.baseUrlKey] ?? '';
      default:
        return dotenv.env[AppConstants.baseUrlKey] ?? '';
    }
  }
}
