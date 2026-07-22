import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../constants/app_constants.dart';
import '../services/logger_service.dart';
import '../services/storage_service.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';
import 'request_retry_interceptor.dart';
import 'response_caching_interceptor.dart';

class ApiService {
  final Dio client;
  late final ResponseCachingInterceptor _cachingInterceptor;

  ApiService({required StorageService storageService})
      : client = Dio(
          BaseOptions(
            baseUrl: _resolveBaseUrl(),
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            validateStatus: (status) {
              // Don't throw on any status code; let interceptors handle it
              return status != null;
            },
          ),
        ) {
    _cachingInterceptor = ResponseCachingInterceptor();
    
    client.interceptors.addAll(
      [
        // Cache GET responses for offline availability
        _cachingInterceptor,
        // Retry failed requests with exponential backoff
        RequestRetryInterceptor(),
        // Attach JWT token to requests
        AuthInterceptor(storageService: storageService),
        // Map errors to user-friendly messages
        ErrorInterceptor(),
        // Log all requests and responses
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
          logPrint: (object) => LoggerService.info(object.toString()),
        ),
      ],
    );
    
    LoggerService.debug('ApiService initialized with base URL: ${client.options.baseUrl}');
  }

  /// Clears all cached API responses
  void clearCache() {
    _cachingInterceptor.clearCache();
  }

  /// Clears cache for a specific API path
  void clearCacheForPath(String path) {
    _cachingInterceptor.clearCacheForPath(path);
  }

  /// Gets cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return _cachingInterceptor.getCacheStats();
  }

  static String _resolveBaseUrl() {
    if (kIsWeb) {
      return dotenv.env[AppConstants.baseUrlWebKey] ??
          dotenv.env[AppConstants.baseUrlKey] ??
          '';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return dotenv.env[AppConstants.baseUrlAndroidKey] ??
            dotenv.env[AppConstants.baseUrlKey] ??
            '';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return dotenv.env[AppConstants.baseUrlIosKey] ??
            dotenv.env[AppConstants.baseUrlKey] ??
            '';
      default:
        return dotenv.env[AppConstants.baseUrlKey] ?? '';
    }
  }
}
