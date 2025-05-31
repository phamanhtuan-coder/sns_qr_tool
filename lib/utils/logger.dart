import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(),
);

void logError(String message, [dynamic error, StackTrace? stackTrace]) {
  logger.e(message, error: error, stackTrace: stackTrace);
}