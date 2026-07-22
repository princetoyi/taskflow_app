import 'package:logger/logger.dart';

class LoggerService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      colors: true,
      printEmojis: true,
    ),
  );

  /// Log information message
  static void info(String message) => _logger.i(message);

  /// Log debug message
  static void debug(String message) => _logger.d(message);

  /// Log warning message
  static void warn(String message) => _logger.w(message);

  /// Log error message
  static void error(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalInfo,
  ]) {
    final buffer = StringBuffer(message);
    if (additionalInfo != null && additionalInfo.isNotEmpty) {
      buffer.write('\nDetails: ${additionalInfo.toString()}');
    }

    _logger.e(buffer.toString(), error, stackTrace);
  }

  /// Log verbose message
  static void verbose(String message) => _logger.v(message);
}
