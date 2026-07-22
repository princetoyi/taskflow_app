import 'package:dio/dio.dart';
import '../services/logger_service.dart';

/// Interceptor that automatically retries failed requests with exponential backoff
class RequestRetryInterceptor extends Interceptor {
  static const int _maxRetries = 3;
  static const int _initialDelayMs = 1000; // Start with 1 second

  /// HTTP status codes that should trigger a retry
  static const Set<int> _retryableStatusCodes = {
    408, // Request Timeout
    429, // Too Many Requests (Rate Limited)
    500, // Internal Server Error
    502, // Bad Gateway
    503, // Service Unavailable
    504, // Gateway Timeout
  };

  /// Request methods that are safe to retry
  static const Set<String> _retryableMethods = {
    'GET',
    'HEAD',
    'OPTIONS',
    'PUT', // Safe for idempotent operations
  };

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final method = err.requestOptions.method.toUpperCase();

    // Check if error is retryable
    final isRetryable = statusCode != null &&
        _retryableStatusCodes.contains(statusCode) &&
        _retryableMethods.contains(method);

    if (!isRetryable) {
      handler.next(err);
      return;
    }

    // Get current retry count from request extras
    final retryCount = (err.requestOptions.extra['_retry_count'] as int?) ?? 0;

    if (retryCount >= _maxRetries) {
      LoggerService.warn(
        'Max retries reached for $method ${err.requestOptions.path} '
        '(status: $statusCode, retries: $retryCount)',
      );
      handler.next(err);
      return;
    }

    // Calculate exponential backoff delay: 2^retryCount seconds (1s, 2s, 4s, 8s...)
    final delayMs = _initialDelayMs * (1 << retryCount); // 2^retryCount multiplication
    final nextRetry = retryCount + 1;

    LoggerService.debug(
      'Retrying $method ${err.requestOptions.path} '
      '(attempt $nextRetry/$_maxRetries, delay: ${delayMs}ms, status: $statusCode)',
    );

    // Wait before retrying
    await Future.delayed(Duration(milliseconds: delayMs));

    // Update retry count for next attempt
    err.requestOptions.extra['_retry_count'] = nextRetry;

    try {
      // Retry the request
      final response = await _retry(err.requestOptions);
      handler.resolve(response);
    } catch (e) {
      // If retry also fails, continue error handling
      handler.next(err);
    }
  }

  /// Retries a failed request by creating a new request with the same options
  Future<Response> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
      contentType: requestOptions.contentType,
      responseType: requestOptions.responseType,
      followRedirects: requestOptions.followRedirects,
      maxRedirects: requestOptions.maxRedirects,
      validateStatus: requestOptions.validateStatus,
      extra: requestOptions.extra,
    );

    // Use the Dio instance from the request
    final dio = Dio(BaseOptions(
      baseUrl: requestOptions.baseUrl,
      connectTimeout: requestOptions.connectTimeout,
      receiveTimeout: requestOptions.receiveTimeout,
      sendTimeout: requestOptions.sendTimeout,
    ));

    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
