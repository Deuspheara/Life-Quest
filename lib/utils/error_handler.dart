import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class ErrorHandler {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  // Log error with message and exception
  static void logError(String message, dynamic error) {
    _logger.e('$message: ${error.toString()}', error: error, stackTrace: error is Error ? error.stackTrace : null);
    // Send to analytics service in production
    if (!kDebugMode) {
      // TODO: Implement analytics error reporting
    }
  }

  // Log warning message
  static void logWarning(String message) {
    _logger.w(message);
  }

  // Log info message
  static void logInfo(String message) {
    _logger.i(message);
  }

  // Format user-friendly error message
  static String formatErrorForUser(dynamic error) {
    if (error is Exception) {
      // Extract meaningful message from common exceptions
      final String errorString = error.toString().toLowerCase();

      if (errorString.contains('timeout')) {
        return 'The operation timed out. Please check your internet connection and try again.';
      } else if (errorString.contains('network') || errorString.contains('socket')) {
        return 'Network error. Please check your internet connection.';
      } else if (errorString.contains('permission') || errorString.contains('denied')) {
        return 'Permission denied. Please check app permissions.';
      } else if (errorString.contains('not found')) {
        return 'The requested resource was not found.';
      } else if (errorString.contains('already exists')) {
        return 'This item already exists.';
      } else if (errorString.contains('authentication') || errorString.contains('auth') || errorString.contains('401')) {
        return 'Authentication error. Please sign in again.';
      }
    }

    // Default generic message
    return 'Something went wrong. Please try again later.';
  }
}