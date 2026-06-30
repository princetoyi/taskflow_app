import 'package:dio/dio.dart';
import '../errors/app_exception.dart';
import '../services/logger_service.dart';
import 'api_service.dart';

/// High-level wrapper around Dio for making API calls with consistent error handling
/// 
/// Provides a cleaner interface compared to using Dio directly:
/// - Automatic error mapping
/// - Consistent request/response handling
/// - Built-in logging
/// - Type safety
class ApiClient {
  final ApiService _apiService;

  const ApiClient({required ApiService apiService}) : _apiService = apiService;

  /// Gets the underlying Dio instance for direct access if needed
  Dio get dio => _apiService.client;

  /// Makes a GET request
  /// 
  /// Parameters:
  ///   - [path]: Endpoint path (without base URL)
  ///   - [queryParameters]: Query string parameters
  ///   - [options]: Optional Dio request options
  /// 
  /// Returns: Response data as [T]
  /// Throws: [AppException] on error
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      LoggerService.debug('GET $path');
      final response = await _apiService.client.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  /// Makes a POST request
  /// 
  /// Parameters:
  ///   - [path]: Endpoint path
  ///   - [data]: Request body
  ///   - [queryParameters]: Query parameters (optional)
  ///   - [options]: Dio options (optional)
  /// 
  /// Returns: Response data as [T]
  /// Throws: [AppException] on error
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      LoggerService.debug('POST $path');
      final response = await _apiService.client.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  /// Makes a PUT request
  /// 
  /// Parameters:
  ///   - [path]: Endpoint path
  ///   - [data]: Request body
  ///   - [queryParameters]: Query parameters (optional)
  ///   - [options]: Dio options (optional)
  /// 
  /// Returns: Response data as [T]
  /// Throws: [AppException] on error
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      LoggerService.debug('PUT $path');
      final response = await _apiService.client.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  /// Makes a PATCH request
  /// 
  /// Parameters:
  ///   - [path]: Endpoint path
  ///   - [data]: Request body
  ///   - [queryParameters]: Query parameters (optional)
  ///   - [options]: Dio options (optional)
  /// 
  /// Returns: Response data as [T]
  /// Throws: [AppException] on error
  Future<T> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      LoggerService.debug('PATCH $path');
      final response = await _apiService.client.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  /// Makes a DELETE request
  /// 
  /// Parameters:
  ///   - [path]: Endpoint path
  ///   - [queryParameters]: Query parameters (optional)
  ///   - [options]: Dio options (optional)
  /// 
  /// Returns: Response data as [T]
  /// Throws: [AppException] on error
  Future<T> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      LoggerService.debug('DELETE $path');
      final response = await _apiService.client.delete<dynamic>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  /// Makes a HEAD request
  /// 
  /// Parameters:
  ///   - [path]: Endpoint path
  ///   - [queryParameters]: Query parameters (optional)
  ///   - [options]: Dio options (optional)
  /// 
  /// Returns: Response metadata
  /// Throws: [AppException] on error
  Future<Response<T>> head<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      LoggerService.debug('HEAD $path');
      return await _apiService.client.head<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  /// Uploads file with multipart form data
  /// 
  /// Parameters:
  ///   - [path]: Endpoint path
  ///   - [files]: Map of field name to file path
  ///   - [fields]: Additional form fields
  ///   - [onSendProgress]: Progress callback
  /// 
  /// Returns: Response data as [T]
  /// Throws: [AppException] on error
  Future<T> upload<T>(
    String path, {
    required Map<String, String> files,
    Map<String, String>? fields,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      LoggerService.debug('UPLOAD $path');
      
      final formData = FormData();
      
      // Add files
      for (final entry in files.entries) {
        formData.files.add(
          MapEntry(
            entry.key,
            await MultipartFile.fromFile(entry.value),
          ),
        );
      }
      
      // Add fields
      if (fields != null) {
        for (final entry in fields.entries) {
          formData.fields.add(MapEntry(entry.key, entry.value));
        }
      }
      
      final response = await _apiService.client.post<dynamic>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );
      
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  /// Downloads file to specified path
  /// 
  /// Parameters:
  ///   - [url]: URL to download from
  ///   - [savePath]: Local path to save file
  ///   - [onReceiveProgress]: Progress callback
  /// 
  /// Throws: [AppException] on error
  Future<void> download(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      LoggerService.debug('DOWNLOAD $url');
      await _apiService.client.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  /// Handles response data extraction and type casting
  T _handleResponse<T>(Response<dynamic> response) {
    final data = response.data;
    
    // If T is String, return data as-is if it's already a String
    if (T == String && data is String) {
      return data as T;
    }
    
    // If T is Map or dynamic, return data as-is
    if (T == dynamic || T == Map || data == null) {
      return data as T;
    }
    
    // For complex types, return the data (caller should handle parsing)
    return data as T;
  }

  /// Maps DioException to AppException
  AppException _mapException(DioException error) {
    if (error.error is AppException) {
      return error.error as AppException;
    }
    
    final statusCode = error.response?.statusCode;
    
    if (error.type == DioExceptionType.connectionTimeout) {
      return AppException(
        'Connection timeout. Please check your internet connection.',
        statusCode: statusCode,
      );
    }
    
    if (error.type == DioExceptionType.sendTimeout) {
      return AppException(
        'Request timeout. Please try again.',
        statusCode: statusCode,
      );
    }
    
    if (error.type == DioExceptionType.receiveTimeout) {
      return AppException(
        'Response timeout. Please try again.',
        statusCode: statusCode,
      );
    }
    
    if (error.type == DioExceptionType.connectionError) {
      return AppException(
        'Network error. Please check your connection.',
        statusCode: statusCode,
      );
    }
    
    if (statusCode == 401) {
      return AppException(
        'Unauthorized. Please log in again.',
        statusCode: statusCode,
      );
    }
    
    if (statusCode == 403) {
      return AppException(
        'Access denied.',
        statusCode: statusCode,
      );
    }
    
    if (statusCode == 404) {
      return AppException(
        'Resource not found.',
        statusCode: statusCode,
      );
    }
    
    if (statusCode == 429) {
      return AppException(
        'Too many requests. Please try again later.',
        statusCode: statusCode,
      );
    }
    
    if (statusCode != null && statusCode >= 500) {
      return AppException(
        'Server error. Please try again later.',
        statusCode: statusCode,
      );
    }
    
    return AppException(
      'An error occurred. Please try again.',
      statusCode: statusCode,
      originalError: error,
    );
  }
}
