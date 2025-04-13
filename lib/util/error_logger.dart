import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/component/styled_bot_toast.dart';

/// A comprehensive error logger for flutter applications
/// Provides detailed error traces and allows for custom error handling
class ErrorLogger {
  // Keep track of the last time we showed an error toast
  // to avoid flooding the user with error messages
  static DateTime _lastErrorToastTime = DateTime.now();
  static const Duration _errorToastThrottleTime = Duration(seconds: 2);
  
  /// Initializes the global error handling
  static void init() {
    // Set up global error handling
    FlutterError.onError = _handleFlutterError;
    
    // Catch errors that happen outside of the Flutter framework
    PlatformDispatcher.instance.onError = _handlePlatformError;
    
    // Register a periodic cleanup for toasts
    Timer.periodic(const Duration(minutes: 5), (_) {
      StyledBotToast.cleanUp();
    });
    
    developer.log('ErrorLogger initialized successfully', name: 'ErrorLogger');
  }
  
  /// Handle errors from the Flutter framework
  static void _handleFlutterError(FlutterErrorDetails details) {
    // Check if this is an image encoding error that we want to suppress
    final errorMessage = details.exception.toString();
    bool isImageError = errorMessage.contains("EncodingError") || 
                        errorMessage.contains("source image cannot be decoded");
    
    // Always log but with different verbosity based on error type
    if (isImageError) {
      // For image errors, use a quieter log level without full stack trace
      developer.log(
        'IMAGE FLUTTER ERROR: ${details.exception}',
        name: 'ErrorLogger',
        error: details.exception,
      );
    } else {
      // Normal errors get full logging
      developer.log(
        'FLUTTER ERROR: ${details.exception}',
        name: 'ErrorLogger',
        error: details.exception,
        stackTrace: details.stack,
      );
    }
    
    // Show a toast notification in debug mode, but only for non-image errors
    if (kDebugMode && !isImageError) {
      _showErrorToast('Flutter Error: ${details.exception}');
    }
    
    // Forward to Flutter's default error handler
    FlutterError.presentError(details);
  }
  
  /// Handle errors from outside the Flutter framework
  static bool _handlePlatformError(Object error, StackTrace stack) {
    // Check if this is an image encoding error that we want to suppress
    final errorMessage = error.toString();
    bool isImageError = errorMessage.contains("EncodingError") || 
                        errorMessage.contains("source image cannot be decoded");
    
    // Always log but with different verbosity based on error type
    if (isImageError) {
      // For image errors, use a quieter log level without full stack trace
      developer.log(
        'IMAGE PLATFORM ERROR: $error',
        name: 'ErrorLogger',
        error: error,
      );
    } else {
      // Normal errors get full logging
      developer.log(
        'PLATFORM ERROR: $error',
        name: 'ErrorLogger',
        error: error,
        stackTrace: stack,
      );
    }
    
    // Show a toast notification in debug mode, but only for non-image errors
    if (kDebugMode && !isImageError) {
      _showErrorToast('Platform Error: $error');
    }
    
    // Return true to prevent the error from propagating
    return true;
  }
  
  /// Log a custom error with full stack trace
  static void logError(String message, dynamic error, StackTrace? stackTrace) {
    // Truncate extremely long error messages
    String truncatedMessage = message;
    if (truncatedMessage.length > 500) {
      truncatedMessage = '${truncatedMessage.substring(0, 500)}...';
    }
    
    // Check if this is an image encoding error that we want to suppress
    final errorMessage = error?.toString() ?? '';
    bool isImageError = errorMessage.contains("EncodingError") || 
                        errorMessage.contains("source image cannot be decoded");
    
    // Always log to developer tools but with different verbosity
    if (isImageError) {
      // For image errors, use a quieter log level
      developer.log(
        'IMAGE ERROR: $truncatedMessage',
        name: 'ErrorLogger',
        error: error,
      );
    } else {
      // Normal errors get full stack trace logging
      developer.log(
        'APP ERROR: $truncatedMessage',
        name: 'ErrorLogger',
        error: error,
        stackTrace: stackTrace ?? StackTrace.current,
      );
    }
    
    // Show a toast notification in debug mode, but only for non-image errors
    if (kDebugMode && !isImageError) {
      _showErrorToast('Error: $truncatedMessage');
    }
  }
  
  /// Show an error message to the user
  static void _showErrorToast(String message) {
    // Skip encoding errors - these are common with image loading and we don't want to show them
    if (message.contains("EncodingError") || message.contains("source image cannot be decoded")) {
      // Just log silently but don't show to user
      debugPrint("SUPPRESSED IMAGE ERROR: $message");
      return;
    }
    
    // Avoid showing too many error toasts in quick succession
    final now = DateTime.now();
    if (now.difference(_lastErrorToastTime) < _errorToastThrottleTime) {
      // Just log to console if we're throttling
      debugPrint("THROTTLED ERROR: $message");
      return;
    }
    
    _lastErrorToastTime = now;
    
    // Truncate long messages to avoid UI issues
    String displayMessage = message;
    if (displayMessage.length > 200) {
      displayMessage = '${displayMessage.substring(0, 197)}...';
    }
    
    // We don't have a BuildContext here, so we use the fallback method
    StyledBotToast.fallbackToast(displayMessage);
    
    // Also always log to console in debug mode for visibility
    if (kDebugMode) {
      debugPrint("ERROR: $message");
    }
  }
  
  /// Show an error message to the user with context
  static void showErrorToast(BuildContext context, String message) {
    // Skip encoding errors - these are common with image loading and we don't want to show them
    if (message.contains("EncodingError") || message.contains("source image cannot be decoded")) {
      // Just log silently but don't show to user
      debugPrint("SUPPRESSED IMAGE ERROR: $message");
      return;
    }
    
    // Only show if we have a valid context
    if (context is! StatefulElement || context.state.mounted) {
      try {
        // Truncate long messages
        String displayMessage = message;
        if (displayMessage.length > 200) {
          displayMessage = '${displayMessage.substring(0, 197)}...';
        }
        
        // Use our improved StyledBotToast
        StyledBotToast.showError(context, text: displayMessage);
      } catch (e) {
        // Fallback to console
        debugPrint("ERROR (toast failed): $message");
      }
    } else {
      // Fallback to console for unmounted context
      debugPrint("ERROR (unmounted context): $message");
    }
  }
  
  /// Wrap a callback in a try-catch block with detailed logging
  static Future<T?> runWithCatch<T>(
    String operation,
    Future<T> Function() callback, {
    BuildContext? context,
  }) async {
    try {
      return await callback();
    } catch (e, stack) {
      // Log the error but handle image encoding errors specially
      final errorMessage = e.toString();
      bool isImageError = errorMessage.contains("EncodingError") || 
                          errorMessage.contains("source image cannot be decoded");
      
      // Always log internally but with different levels
      if (isImageError) {
        // Just log silently but don't show toast for image errors
        debugPrint("SUPPRESSED IMAGE ERROR during $operation: $e");
      } else {
        // Log normal errors with full details
        logError('Error during $operation', e, stack);
      }
      
      // Show a toast if context is provided AND not an image error
      if (context != null && !isImageError) {
        showErrorToast(context, 'Error during $operation: $e');
      }
      
      return null;
    }
  }
}

/// Provides an error boundary widget that catches errors in the widget tree
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.errorBuilder,
  }) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;
  FlutterExceptionHandler? _originalOnError;

  @override
  void initState() {
    super.initState();
    
    // Store the original error handler
    _originalOnError = FlutterError.onError;
    
    // Set up our custom error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      // First call the original handler
      if (_originalOnError != null) {
        _originalOnError!(details);
      }
      
      // Check if this is an image encoding error that we want to handle specially
      final errorMessage = details.exception.toString();
      final isImageError = errorMessage.contains("EncodingError") || 
                           errorMessage.contains("source image cannot be decoded");
      
      // Log to our error logger with appropriate verbosity
      if (isImageError) {
        // For image errors, just log quietly without showing error UI
        debugPrint("SUPPRESSED IMAGE ERROR in boundary: ${details.exception}");
      } else {
        // For normal errors, do full logging and show error UI
        ErrorLogger.logError(
          'Widget error caught by boundary',
          details.exception,
          details.stack,
        );
        
        // Only update state to show error UI for non-image errors
        if (mounted) {
          setState(() {
            _error = details.exception;
            _stackTrace = details.stack;
          });
        }
      }
    };
    
    // Clean up any toast notifications
    try {
      StyledBotToast.cleanUp();
    } catch (e) {
      debugPrint("Error cleaning toasts during init: $e");
    }
  }
  
  // Add a method to manually capture errors that might happen during runtime
  void captureError(Object error, StackTrace stackTrace) {
    // Check if this is an image encoding error that we want to handle specially
    final errorMessage = error.toString();
    final isImageError = errorMessage.contains("EncodingError") || 
                         errorMessage.contains("source image cannot be decoded");
    
    if (isImageError) {
      // For image errors, just log quietly without showing error UI
      debugPrint("SUPPRESSED IMAGE ERROR in captureError: $error");
      
      // Don't update state for image errors - this prevents showing the error UI
      return;
    }
    
    // For normal errors, do full logging and show error UI
    ErrorLogger.logError('Runtime error caught by boundary', error, stackTrace);
    
    if (mounted) {
      setState(() {
        _error = error;
        _stackTrace = stackTrace;
      });
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Attempt to catch errors during dependency resolution
    try {
      // Additional dependency checks could go here
    } catch (e, stack) {
      captureError(e, stack);
    }
  }
  
  @override
  void dispose() {
    // Clean up toasts when this boundary is disposed
    try {
      StyledBotToast.cleanUp();
    } catch (e) {
      debugPrint("Error cleaning toasts during dispose: $e");
    }
    
    // Restore original error handler
    if (_originalOnError != null) {
      FlutterError.onError = _originalOnError;
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      // Check if this is an image encoding error before showing the error UI
      final errorMessage = _error.toString();
      final isImageError = errorMessage.contains("EncodingError") || 
                           errorMessage.contains("source image cannot be decoded");
      
      // For image errors, skip showing the error UI completely
      if (isImageError) {
        debugPrint("SUPPRESSED IMAGE ERROR UI: $_error");
        // Just return the child as if no error occurred
        try {
          return widget.child;
        } catch (e) {
          // In case the child is invalid, return empty widget
          return const SizedBox();
        }
      }
      
      // For non-image errors, show the error UI
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!, _stackTrace);
      }
      
      // Default error display
      return Material(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Error: ${_error.toString()}',
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _stackTrace = null;
                  });
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Wrap the child widget in a try-catch to handle runtime build errors
    try {
      return widget.child;
    } catch (error, stackTrace) {
      // Check if this is an image encoding error
      final errorMessage = error.toString();
      final isImageError = errorMessage.contains("EncodingError") || 
                           errorMessage.contains("source image cannot be decoded");
      
      if (isImageError) {
        // For image errors, just log quietly without showing error UI
        debugPrint("SUPPRESSED IMAGE ERROR in build: $error");
        
        // Return the simplest possible fallback without updating state
        return const SizedBox();
      }
      
      // For regular errors, proceed with normal error handling
      ErrorLogger.logError('Error during build', error, stackTrace);
      
      // Immediately update state to show error UI
      WidgetsBinding.instance.addPostFrameCallback((_) {
        captureError(error, stackTrace);
      });
      
      // Return a placeholder while we're updating the state
      return const Material(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }
}