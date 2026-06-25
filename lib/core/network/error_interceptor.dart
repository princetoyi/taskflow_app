import 'package:dio/dio.dart';
import '../errors/app_exception.dart';
import '../services/logger_service.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    var message = _mapErrorToMessage(err);
    var statusCode = _extractStatusCode(err);
    var errorType = _categorizeError(err);

    // Log detailed error information
    LoggerService.error(
      'API Error: $errorType ($statusCode)',
      err,
      StackTrace.current,
      {
        'message': message,
        'path': err.requestOptions.path,
        'method': err.requestOptions.method,
        'responseBody': err.response?.data?.toString(),
      },
    );

    // If the error is already an AppException, pass it through
    if (err.error is AppException) {
      handler.reject(err);
      return;
    }

    // Create AppException with mapped message
    final appException = AppException(
      message,
      statusCode: statusCode,
      originalError: err,
    );

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        error: appException,
        type: err.type,
      ),
    );
  }

  /// Maps DioException to user-friendly message
  String _mapErrorToMessage(DioException err) {
    final statusCode = err.response?.statusCode;

    // Handle timeout errors
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return 'Request timed out. Please check your connection and try again.';
    }

    // Handle connection errors
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.unknown) {
      return 'Network connection failed. Please check your internet connection and try again.';
    }

    // Handle HTTP status codes
    if (err.response != null) {
      return _mapStatusCodeToMessage(statusCode);
    }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Maps HTTP status codes to specific messages
  String _mapStatusCodeToMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please review your information and try again.';
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 408:
        return 'Request timeout. Please try again.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
      case 503:
      case 504:
        return 'Service temporarily unavailable. Please try again later.';
      default:
        if (statusCode != null && statusCode >= 500) {
          return 'Server error. Please try again later.';
        }
        if (statusCode != null && statusCode >= 400) {
          return 'Request failed. Please try again.';
        }
        return 'Unable to process request right now.';
    }
  }

  /// Extracts the status code from the error
  int? _extractStatusCode(DioException err) {
    return err.response?.statusCode;
  }

  /// Categorizes the error type for logging
  String _categorizeError(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return 'TIMEOUT';
    }

    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.unknown) {
      return 'CONNECTION_ERROR';
    }

    final statusCode = err.response?.statusCode;
    if (statusCode != null && statusCode >= 500) {
      return 'SERVER_ERROR';
    }

    if (statusCode != null && statusCode >= 400) {
      return 'CLIENT_ERROR';
    }

    return 'UNKNOWN_ERROR';
  }
}
