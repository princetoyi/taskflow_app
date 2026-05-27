import 'package:dio/dio.dart';
import '../errors/app_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    var message = 'Unable to process request right now.';

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      message = 'Request timed out. Please check your connection and try again.';
    } else if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.unknown) {
      message = 'Please check your internet connection and try again.';
    } else if (err.response != null) {
      final statusCode = err.response?.statusCode;
      if (statusCode == 400) {
        message = 'Invalid request. Please review your information and try again.';
      } else if (statusCode == 401) {
        message = 'Session expired. Please login again.';
      } else if (statusCode == 403) {
        message = 'You do not have permission to perform this action.';
      } else if (statusCode == 404) {
        message = 'Requested resource not found.';
      } else if (statusCode != null && statusCode >= 500) {
        message = 'Server is unavailable. Please try again later.';
      } else {
        message = err.response?.data?['detail']?.toString() ?? err.response?.statusMessage ?? message;
      }
    }

    if (err.error is AppException) {
      handler.reject(err);
    } else {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          error: AppException(message),
        ),
      );
    }
  }
}
