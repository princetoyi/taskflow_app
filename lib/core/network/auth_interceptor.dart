import 'package:dio/dio.dart';
import '../errors/app_exception.dart';
import '../services/storage_service.dart';

class AuthInterceptor extends Interceptor {
  final StorageService storageService;

  AuthInterceptor({required this.storageService});

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storageService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await storageService.clearAll();
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          error: AppException('Session expired. Please sign in again.'),
        ),
      );
      return;
    }

    handler.next(err);
  }
}
