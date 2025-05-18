import 'dart:async';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/util/app_logger.dart';

/// Styled toast widget that uses BotToast to show a toast message.
/// Includes better error handling to prevent app crashes.
class StyledBotToast {
  // Keep track of toast cancel functions to prevent the LateInitializationError
  static final Map<String, CancelFunc> _activeCancelFuncs = {};
  
  // Generate a unique ID for each toast
  static int _toastCounter = 0;
  static String _getNextToastId() => 'toast_${_toastCounter++}';
  
  /// Shows a toast message using BotToast
  /// Automatically handles errors and prevents crashes
  static void show(BuildContext context, {required String text}) {
    // Skip if text is empty
    if (text.isEmpty) return;
    
    // Skip showing toasts for encoding errors using our centralized logic
    if (_shouldSuppressMessage(text)) {
      logger.d("SUPPRESSED TOAST (show): $text");
      return;
    }
    
    // Safely check context to prevent issues
    if (context is StatefulElement && !context.state.mounted) return;
    
    try {
      // Get theme data
      final themeData = Theme.of(context).customColors;
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      
      // Use #98b9b4 for dark mode, otherwise use theme default
      final backgroundColor = isDarkMode 
        ? const Color(0xFF98B9B4) 
        : themeData.secondaryForegroundColor;
      
      // Use dark blue text for the teal background in dark mode
      final textColor = isDarkMode 
        ? const Color(0xFF181E26)
        : null; // Use default white for other themes
      
      // Show toast with proper error handling
      _safeShowToast(
        text,
        contentColor: backgroundColor,
        textColor: textColor,
      );
    } catch (e, stack) {
      // Log errors but don't crash the app
      logger.e('Error showing toast', e, stack);
      
      // Fall back to default toast (safer)
      _safeShowToast(text);
    }
  }
  
  /// Shows error toast with red background
  static void showError(BuildContext context, {required String text}) {
    // Skip if text is empty
    if (text.isEmpty) return;
    
    // Skip showing toasts for encoding errors using our centralized logic
    if (_shouldSuppressMessage(text)) {
      logger.d("SUPPRESSED ERROR TOAST (showError): $text");
      return;
    }
    
    try {
      _safeShowToast(
        text,
        contentColor: Colors.red.shade700,
      );
    } catch (e, stack) {
      // Log errors but don't crash the app
      logger.e('Error showing error toast', e, stack);
      
      // Fall back to default toast (safer)
      _safeShowToast(text);
    }
  }
  
  /// Shows success toast with green background
  static void showSuccess(BuildContext context, {required String text}) {
    // Skip if text is empty
    if (text.isEmpty) return;
    
    // Skip showing toasts for encoding errors using our centralized logic
    if (_shouldSuppressMessage(text)) {
      logger.d("SUPPRESSED SUCCESS TOAST (showSuccess): $text");
      return;
    }
    
    try {
      _safeShowToast(
        text,
        contentColor: Colors.green.shade700,
      );
    } catch (e, stack) {
      // Log errors but don't crash the app
      logger.e('Error showing success toast', e, stack);
      
      // Fall back to default toast (safer)
      _safeShowToast(text);
    }
  }
  
  /// Clean up any lingering toast cancel functions
  /// Call this periodically or when the app is in background to prevent memory leaks
  static void cleanUp() {
    try {
      // Close all active toasts
      for (final cancelFunc in _activeCancelFuncs.values) {
        try {
          cancelFunc();
        } catch (e) {
          // Ignore errors when canceling
        }
      }
      _activeCancelFuncs.clear();
    } catch (e, stack) {
      logger.e('Error cleaning up toasts', e, stack);
    }
  }
  
  /// Private method to safely call BotToast.showText with error handling
  static void _safeShowToast(String text, {Color? contentColor, Color? textColor}) {
    // Skip showing toasts for encoding errors
    if (_shouldSuppressMessage(text)) {
      logger.d("SUPPRESSED TOAST ERROR: $text");
      return;
    }
    
    // Generate a unique ID for this toast
    final toastId = _getNextToastId();
    
    try {
      // If we have too many active toasts, clean up old ones
      if (_activeCancelFuncs.length > 5) {
        final oldestToastIds = _activeCancelFuncs.keys.take(2).toList();
        for (final id in oldestToastIds) {
          final cancelFunc = _activeCancelFuncs[id];
          if (cancelFunc != null) {
            try {
              cancelFunc();
            } catch (e) {
              // Ignore errors when canceling
            }
            _activeCancelFuncs.remove(id);
          }
        }
      }
      
      // Create the toast and store its cancel function
      final cancelFunc = BotToast.showText(
        text: text,
        contentColor: contentColor ?? Colors.black87,
        textStyle: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: 14,
        ),
        borderRadius: BorderRadius.circular(8),
        duration: const Duration(seconds: 2),
        onlyOne: true,
        clickClose: true,
        crossPage: true,
        onClose: () {
          // Remove the toast from our tracking when it closes
          _activeCancelFuncs.remove(toastId);
        },
      );
      
      // Store the cancel function for later use
      _activeCancelFuncs[toastId] = cancelFunc;
      
      // Schedule automatic cleanup after toast duration
      Future.delayed(const Duration(seconds: 3), () {
        _activeCancelFuncs.remove(toastId);
      });
    } catch (e, stack) {
      // Log the error but don't crash the app
      logger.e('Error in _safeShowToast', e, stack);
      
      // Last resort: use native alert for critical messages
      if (text.isNotEmpty && kDebugMode) {
        logger.d("Toast fallback: $text");
      }
    }
  }
  
  /// Helper method to determine if a message should be suppressed
  static bool _shouldSuppressMessage(String message) {
    // List of patterns that should be suppressed
    final List<String> suppressPatterns = [
      "EncodingError", 
      "source image cannot be decoded",
      "Failed to decode image",
      "404",
      "nostr.download",
      "Could not create image",
      "Image provider exception"
    ];
    
    // Check if the message contains any of the patterns
    for (final pattern in suppressPatterns) {
      if (message.contains(pattern)) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Shows the toast using a fallback mechanism when the main method fails
  static void fallbackToast(String text) {
    if (text.isEmpty) return;
    
    // Use our centralized suppression logic
    if (_shouldSuppressMessage(text)) {
      // Just log silently but don't show to user
      logger.d("SUPPRESSED IMAGE ERROR TOAST: $text");
      return;
    }
    
    // Print to console as absolute fallback
    logger.i("TOAST: $text");
  }
}
