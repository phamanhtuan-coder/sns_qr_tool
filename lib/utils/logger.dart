import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(),
);

void logError(String message, [dynamic error, StackTrace? stackTrace]) {
  logger.e(message, error: error, stackTrace: stackTrace);
}

void logInfo(String message) {
  logger.i(message);
}

void logWarning(String message) {
  logger.w(message);
}

void logDebug(String message) {
  logger.d(message);
}
