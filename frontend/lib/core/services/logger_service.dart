import 'package:logger/logger.dart';

class LoggerService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0, errorMethodCount: 5),
  );

  static void info(String message) => _logger.i(message);
  static void error(String message) => _logger.e(message);
}
