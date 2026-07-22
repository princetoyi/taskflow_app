import 'package:dio/dio.dart';
import '../services/logger_service.dart';

/// Model to store cached response with metadata
class _CacheEntry {
  final Response<dynamic> response;
  final DateTime timestamp;
  final Duration ttl; // Time to live

  _CacheEntry({
    required this.response,
    required this.ttl,
  }) : timestamp = DateTime.now();

  bool get isExpired {
    return DateTime.now().difference(timestamp) > ttl;
  }

  @override
  String toString() => 'CacheEntry(key: ${response.requestOptions.path}, '
      'expired: $isExpired, ttl: $ttl)';
}

/// Interceptor that caches GET request responses for offline availability
/// 
/// Features:
/// - Automatically caches successful GET responses
/// - Configurable TTL (Time To Live) per request
/// - Returns cached data if network request fails
/// - Respects Cache-Control headers from server
class ResponseCachingInterceptor extends Interceptor {
  /// Internal cache storage: path -> CacheEntry
  final Map<String, _CacheEntry> _cache = {};

  /// Default cache duration for GET requests
  static const Duration defaultCacheDuration = Duration(minutes: 5);

  /// Maximum cache size (entries)
  static const int maxCacheEntries = 100;

  /// Paths that should not be cached
  static const Set<String> nonCacheablePaths = {
    '/auth/login',
    '/auth/logout',
    '/auth/refresh',
    '/users/profile/change-password',
  };

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Only cache GET requests
    if (options.method.toUpperCase() != 'GET') {
      return handler.next(options);
    }

    // Skip non-cacheable paths
    if (_isNonCacheable(options.path)) {
      return handler.next(options);
    }

    // Check if we have a valid cached response
    final cacheKey = _generateCacheKey(options);
    final cachedEntry = _cache[cacheKey];

    if (cachedEntry != null && !cachedEntry.isExpired) {
      LoggerService.debug('Using cached response for: ${options.path}');
      return handler.resolve(cachedEntry.response);
    }

    // Remove expired cache entry
    if (cachedEntry != null && cachedEntry.isExpired) {
      _cache.remove(cacheKey);
      LoggerService.debug('Cache expired for: ${options.path}');
    }

    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    // Only cache successful GET responses
    if (response.requestOptions.method.toUpperCase() != 'GET') {
      return handler.next(response);
    }

    if (response.statusCode == null || response.statusCode! >= 400) {
      return handler.next(response);
    }

    // Skip non-cacheable paths
    if (_isNonCacheable(response.requestOptions.path)) {
      return handler.next(response);
    }

    // Determine cache duration from response headers or use default
    final cacheDuration = _parseCacheDuration(response) ?? defaultCacheDuration;

    final cacheKey = _generateCacheKey(response.requestOptions);
    
    // Implement simple cache size limit (FIFO)
    if (_cache.length >= maxCacheEntries) {
      // Remove oldest entry
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
      LoggerService.debug('Cache limit reached, removing oldest entry: $oldestKey');
    }

    _cache[cacheKey] = _CacheEntry(
      response: response,
      ttl: cacheDuration,
    );

    LoggerService.debug(
      'Cached response for: ${response.requestOptions.path} '
      '(TTL: ${cacheDuration.inSeconds}s)',
    );

    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // On error, try to return cached response as fallback
    if (err.requestOptions.method.toUpperCase() == 'GET') {
      final cacheKey = _generateCacheKey(err.requestOptions);
      final cachedEntry = _cache[cacheKey];

      if (cachedEntry != null) {
        LoggerService.warn(
          'Request failed for ${err.requestOptions.path}, '
          'returning stale cache',
        );
        return handler.resolve(cachedEntry.response);
      }
    }

    handler.next(err);
  }

  /// Generates a unique cache key from request options
  String _generateCacheKey(RequestOptions options) {
    final buffer = StringBuffer(options.path);
    
    // Include query parameters in cache key
    if (options.queryParameters.isNotEmpty) {
      final params = options.queryParameters.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      buffer.write('?$params');
    }

    return buffer.toString();
  }

  /// Checks if a path should not be cached
  bool _isNonCacheable(String path) {
    return nonCacheablePaths.any((pattern) => path.contains(pattern));
  }

  /// Parses Cache-Control header to determine cache duration
  Duration? _parseCacheDuration(Response<dynamic> response) {
    final cacheControl = response.headers.value('cache-control');
    
    if (cacheControl == null) return null;

    // Look for max-age directive
    final maxAgeMatch = RegExp(r'max-age=(\d+)').firstMatch(cacheControl);
    if (maxAgeMatch != null) {
      final seconds = int.tryParse(maxAgeMatch.group(1) ?? '');
      if (seconds != null) {
        return Duration(seconds: seconds);
      }
    }

    // Check for no-cache or no-store directives
    if (cacheControl.contains('no-cache') || cacheControl.contains('no-store')) {
      return Duration.zero;
    }

    return null;
  }

  /// Clears all cached responses
  void clearCache() {
    _cache.clear();
    LoggerService.debug('Response cache cleared');
  }

  /// Clears cache entry for a specific path
  void clearCacheForPath(String path) {
    final keysToRemove = _cache.keys.where((k) => k.contains(path)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    LoggerService.debug('Cache cleared for path: $path');
  }

  /// Returns cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'size': _cache.length,
      'maxSize': maxCacheEntries,
      'entries': _cache.entries
          .map((e) => {
                'key': e.key,
                'expired': e.value.isExpired,
                'ttl': '${e.value.ttl.inSeconds}s',
                'age': '${DateTime.now().difference(e.value.timestamp).inSeconds}s',
              })
          .toList(),
    };
  }
}
