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
    // Log the error to console with full details
    developer.log(
      'FLUTTER ERROR: ${details.exception}',
      name: 'ErrorLogger',
      error: details.exception,
      stackTrace: details.stack,
    );
    
    // Show a toast notification in debug mode
    if (kDebugMode) {
      _showErrorToast('Flutter Error: ${details.exception}');
    }
    
    // Forward to Flutter's default error handler
    FlutterError.presentError(details);
  }
  
  /// Handle errors from outside the Flutter framework
  static bool _handlePlatformError(Object error, StackTrace stack) {
    // Log the error to console with full details
    developer.log(
      'PLATFORM ERROR: $error',
      name: 'ErrorLogger',
      error: error,
      stackTrace: stack,
    );
    
    // Show a toast notification in debug mode
    if (kDebugMode) {
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
    
    developer.log(
      'APP ERROR: $truncatedMessage',
      name: 'ErrorLogger',
      error: error,
      stackTrace: stackTrace ?? StackTrace.current,
    );
    
    // Show a toast notification in debug mode
    if (kDebugMode) {
      _showErrorToast('Error: $truncatedMessage');
    }
  }
  
  /// Show an error message to the user
  static void _showErrorToast(String message) {
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
      logError('Error during $operation', e, stack);
      
      // Show a toast if context is provided
      if (context != null) {
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
      
      // Log to our error logger
      ErrorLogger.logError(
        'Widget error caught by boundary',
        details.exception,
        details.stack,
      );
      
      // Then handle it our way
      if (mounted) {
        setState(() {
          _error = details.exception;
          _stackTrace = details.stack;
        });
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
      // Log and capture the error
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