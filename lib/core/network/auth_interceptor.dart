import 'package:dio/dio.dart';
import '../errors/app_exception.dart';
import '../services/storage_service.dart';
import '../services/logger_service.dart';

class AuthInterceptor extends Interceptor {
  final StorageService storageService;
  // Removed unused fields that were previously reserved for token refresh handling.

  AuthInterceptor({required this.storageService});

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Add Authorization header with Bearer token if available
    final token = await storageService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    // Ensure standard headers
    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';
    
    LoggerService.debug('Request: ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;

    // Handle 401 Unauthorized - Session expired
    if (statusCode == 401) {
      LoggerService.warn('Unauthorized (401) - Clearing session');
      
      // Clear authentication data
      await storageService.clearAll();
      
      // Reject with user-friendly error
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          error: AppException('Session expired. Please sign in again.'),
          type: DioExceptionType.unknown,
        ),
      );
      return;
    }

    // Log other errors for debugging
    if (statusCode != null && statusCode >= 400) {
      LoggerService.error(
        'HTTP Error $statusCode',
        err,
        StackTrace.current,
      );
    }

    // Pass to next interceptor (error handler)
    handler.next(err);
  }
}
