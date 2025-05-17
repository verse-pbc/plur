import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:nostrmo/util/stack_trace_formatter.dart';

/// Global logger instance for the app
final logger = AppLogger();

/// Log categories for semantic filtering
enum LogCategory {
  /// Core application logic
  core,
  
  /// Network-related logs (API, relays)
  network,
  
  /// Database operations
  database,
  
  /// UI-related logs
  ui,
  
  /// Authentication-related logs
  auth,
  
  /// Community/groups related logs
  groups,
  
  /// Events feature logs
  events,
  
  /// Performance metrics
  performance,
}

/// Global logger class that provides structured logging capabilities
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  late final Logger _logger;
  
  /// Active categories for filtering (empty means all categories are active)
  final Set<LogCategory> _activeCategories = {};
  
  /// Additional tag-based filters
  final Set<String> _excludedTags = {
    'providereventdispatcher',
    'providerscope',
    'navigator',
  };
  
  /// Flag to enable all debug output regardless of filters
  bool _debugModeOverride = false;

  /// Factory constructor to return the singleton instance
  factory AppLogger() {
    return _instance;
  }

  /// Private constructor for singleton pattern
  AppLogger._internal() {
    _initializeLogger();
  }
  
  /// Initializes the logger with current settings
  void _initializeLogger() {
    _logger = Logger(
      filter: CustomLogFilter(this),
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
  
  /// Filter logs by category. Pass empty list to enable all categories.
  void filterByCategories(List<LogCategory> categories) {
    _activeCategories.clear();
    if (categories.isNotEmpty) {
      _activeCategories.addAll(categories);
    }
  }
  
  /// Add a category to the active filter
  void addCategory(LogCategory category) {
    _activeCategories.add(category);
  }
  
  /// Remove a category from the active filter
  void removeCategory(LogCategory category) {
    _activeCategories.remove(category);
  }
  
  /// Clear all category filters (show all categories)
  void clearCategoryFilters() {
    _activeCategories.clear();
  }
  
  /// Add a tag to exclude from logging
  void addExcludedTag(String tag) {
    _excludedTags.add(tag.toLowerCase());
  }
  
  /// Remove a tag from the exclusion list
  void removeExcludedTag(String tag) {
    _excludedTags.remove(tag.toLowerCase());
  }
  
  /// Get the current list of excluded tags
  List<String> getExcludedTags() {
    return _excludedTags.toList();
  }
  
  /// Check if a category is active
  bool isCategoryActive(LogCategory category) {
    return _activeCategories.isEmpty || _activeCategories.contains(category);
  }
  
  /// Enable debug mode override (show all logs)
  void enableDebugOverride(bool enable) {
    _debugModeOverride = enable;
  }
  
  /// Check if a log should be filtered based on tags
  bool shouldFilterByTag(String message) {
    final lowerMessage = message.toLowerCase();
    return _excludedTags.any((tag) => lowerMessage.contains(tag));
  }

  /// Format stack trace for better readability
  String _formatStackTrace(StackTrace? stackTrace) {
    if (stackTrace == null) return '';
    return StackTraceFormatter.format(
      stackTrace,
      compact: true,
      maxFrames: kDebugMode ? 20 : 8,
    );
  }

  /// Log a verbose message
  void v(dynamic message, [dynamic error, StackTrace? stackTrace, LogCategory category = LogCategory.core]) {
    if (!isCategoryActive(category)) return;
    
    if (error != null) {
      _logger.v('[$category] $message\nError: $error${stackTrace != null ? '\n${_formatStackTrace(stackTrace)}' : ''}');
    } else {
      _logger.v('[$category] $message');
    }
  }

  /// Log a debug message
  void d(dynamic message, [dynamic error, StackTrace? stackTrace, LogCategory category = LogCategory.core]) {
    if (!isCategoryActive(category)) return;
    
    if (error != null) {
      _logger.d('[$category] $message\nError: $error${stackTrace != null ? '\n${_formatStackTrace(stackTrace)}' : ''}');
    } else {
      _logger.d('[$category] $message');
    }
  }

  /// Log an info message
  void i(dynamic message, [dynamic error, StackTrace? stackTrace, LogCategory category = LogCategory.core]) {
    if (!isCategoryActive(category)) return;
    
    if (error != null) {
      _logger.i('[$category] $message\nError: $error${stackTrace != null ? '\n${_formatStackTrace(stackTrace)}' : ''}');
    } else {
      _logger.i('[$category] $message');
    }
  }

  /// Log a warning message
  void w(dynamic message, [dynamic error, StackTrace? stackTrace, LogCategory category = LogCategory.core]) {
    if (!isCategoryActive(category)) return;
    
    if (error != null) {
      _logger.w('[$category] $message\nError: $error${stackTrace != null ? '\n${_formatStackTrace(stackTrace)}' : ''}');
    } else {
      _logger.w('[$category] $message');
    }
  }

  /// Log an error message
  void e(dynamic message, [dynamic error, StackTrace? stackTrace, LogCategory category = LogCategory.core]) {
    if (!isCategoryActive(category)) return;
    
    if (error != null) {
      _logger.e('[$category] $message\nError: $error${stackTrace != null ? '\n${_formatStackTrace(stackTrace)}' : ''}');
    } else {
      _logger.e('[$category] $message');
    }
  }

  /// Log a "What a Terrible Failure" message
  void wtf(dynamic message, [dynamic error, StackTrace? stackTrace, LogCategory category = LogCategory.core]) {
    if (!isCategoryActive(category)) return;
    
    if (error != null) {
      _logger.f('[$category] $message\nError: $error${stackTrace != null ? '\n${_formatStackTrace(stackTrace)}' : ''}');
    } else {
      _logger.f('[$category] $message');
    }
  }

  /// Clean up resources
  void close() {
    _logger.close();
  }
}

/// Custom log filter to exclude noisy packages
class CustomLogFilter extends LogFilter {
  final AppLogger _appLogger;
  
  CustomLogFilter(this._appLogger);
  
  @override
  bool shouldLog(LogEvent event) {
    // Always log errors and warnings in production
    if (!kDebugMode && event.level.index >= Level.warning.index) {
      return true;
    }
    
    // Debug override shows all logs
    if (_appLogger._debugModeOverride) {
      return true;
    }
    
    final message = event.message.toString();
    
    // Filter by excluded tags
    if (_appLogger.shouldFilterByTag(message)) {
      return false;
    }
    
    return true;
  }
} 