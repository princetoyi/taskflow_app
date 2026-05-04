import 'package:dio/dio.dart';
import 'token_service.dart';

/// Intercepts every outgoing request and attaches the stored Firebase ID token
/// as a [Bearer] Authorization header.
///
/// If no token is found (user not logged in), the request proceeds without
/// the header — protected endpoints will return 401.
class AuthInterceptor extends Interceptor {
  final TokenService _tokenService;

  AuthInterceptor({TokenService? tokenService})
      : _tokenService = tokenService ?? TokenService.instance;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Log error details here if needed.
    // For 401s you could trigger a token refresh or force logout.
    return handler.next(err);
  }
}

/// Singleton Dio HTTP client pre-configured for the TaskFlow backend.
///
/// Usage:
///   final response = await ApiClient.instance.get('/tasks/');
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// Change this to your production URL before release.
  static const String _baseUrl = 'http://localhost:8000';

  late final Dio _dio = _buildDio();

  Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(AuthInterceptor());

    return dio;
  }

  // ── Convenience methods ───────────────────────────────────────────────────

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParams}) =>
      _dio.get<T>(path, queryParameters: queryParams);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> patch<T>(String path, {dynamic data}) =>
      _dio.patch<T>(path, data: data);

  Future<Response<T>> delete<T>(String path) => _dio.delete<T>(path);
}
