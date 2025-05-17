import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Global logger instance for the app
final logger = AppLogger();

/// Global logger class that provides structured logging capabilities
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  late final Logger _logger;

  /// Factory constructor to return the singleton instance
  factory AppLogger() {
    return _instance;
  }

  /// Private constructor for singleton pattern
  AppLogger._internal() {
    // Configure logger with custom settings
    _logger = Logger(
      filter: CustomLogFilter(),
      printer: PrettyPrinter(
        methodCount: kDebugMode ? 2 : 0, // Only show method count in debug mode
        errorMethodCount: kDebugMode ? 8 : 1, // More error context in debug mode
        lineLength: 80, // Shorter line length for better readability
        colors: kDebugMode, // Only use colors in debug mode
        printEmojis: kDebugMode, // Only use emojis in debug mode
        printTime: true, // Always print time
        noBoxingByDefault: true, // Disable boxing by default for cleaner output
      ),
      level: kDebugMode ? Level.verbose : Level.warning, // More verbose in debug mode
      output: MultiOutput([
        ConsoleOutput(),
        if (kDebugMode) MemoryOutput(), // Store logs in memory for debug mode
      ]),
    );
  }

  /// Log a verbose message
  void v(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.v('$message\nError: $error${stackTrace != null ? '\n$stackTrace' : ''}');
    } else {
      _logger.v(message);
    }
  }

  /// Log a debug message
  void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.d('$message\nError: $error${stackTrace != null ? '\n$stackTrace' : ''}');
    } else {
      _logger.d(message);
    }
  }

  /// Log an info message
  void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.i('$message\nError: $error${stackTrace != null ? '\n$stackTrace' : ''}');
    } else {
      _logger.i(message);
    }
  }

  /// Log a warning message
  void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.w('$message\nError: $error${stackTrace != null ? '\n$stackTrace' : ''}');
    } else {
      _logger.w(message);
    }
  }

  /// Log an error message
  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.e('$message\nError: $error${stackTrace != null ? '\n$stackTrace' : ''}');
    } else {
      _logger.e(message);
    }
  }

  /// Log a "What a Terrible Failure" message
  void wtf(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.f('$message\nError: $error${stackTrace != null ? '\n$stackTrace' : ''}');
    } else {
      _logger.f(message);
    }
  }

  /// Clean up resources
  void close() {
    _logger.close();
  }
}

/// Custom log filter to exclude noisy packages
class CustomLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (!kDebugMode) {
      return event.level.index >= Level.warning.index;
    }

    final message = event.message.toString().toLowerCase();
    
    // Add packages/classes to filter here
    final excludePatterns = [
      'providereventdispatcher',
      'providerscope',
      'navigator',  // Filter out some navigation noise
      // Add more patterns to filter as needed
    ];

    return !excludePatterns.any((pattern) => message.contains(pattern));
  }
} 