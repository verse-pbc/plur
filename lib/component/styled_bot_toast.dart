import 'dart:async';
import 'dart:developer' as developer;
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/util/theme_util.dart';

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
    
    // Safely check context to prevent issues
    if (context is StatefulElement && !context.state.mounted) return;
    
    try {
      // Get theme data
      final themeData = Theme.of(context).customColors;
      
      // Show toast with proper error handling
      _safeShowToast(
        text,
        contentColor: themeData.secondaryForegroundColor,
      );
    } catch (e) {
      // Log errors but don't crash the app
      developer.log(
        'Error showing toast: $e',
        name: 'StyledBotToast',
        error: e,
      );
      
      // Fall back to default toast (safer)
      _safeShowToast(text);
    }
  }
  
  /// Shows error toast with red background
  static void showError(BuildContext context, {required String text}) {
    // Skip if text is empty
    if (text.isEmpty) return;
    
    try {
      _safeShowToast(
        text,
        contentColor: Colors.red.shade700,
      );
    } catch (e) {
      // Log errors but don't crash the app
      developer.log(
        'Error showing error toast: $e',
        name: 'StyledBotToast',
        error: e,
      );
      
      // Fall back to default toast (safer)
      _safeShowToast(text);
    }
  }
  
  /// Shows success toast with green background
  static void showSuccess(BuildContext context, {required String text}) {
    // Skip if text is empty
    if (text.isEmpty) return;
    
    try {
      _safeShowToast(
        text,
        contentColor: Colors.green.shade700,
      );
    } catch (e) {
      // Log errors but don't crash the app
      developer.log(
        'Error showing success toast: $e',
        name: 'StyledBotToast',
        error: e,
      );
      
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
    } catch (e) {
      developer.log(
        'Error cleaning up toasts: $e',
        name: 'StyledBotToast',
        error: e,
      );
    }
  }
  
  /// Private method to safely call BotToast.showText with error handling
  static void _safeShowToast(String text, {Color? contentColor}) {
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
        textStyle: const TextStyle(
          color: Colors.white,
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
    } catch (e) {
      // Log the error but don't crash the app
      developer.log(
        'Error in _safeShowToast: $e',
        name: 'StyledBotToast',
        error: e,
      );
      
      // Last resort: use native alert for critical messages
      if (text.isNotEmpty && kDebugMode) {
        debugPrint("Toast fallback: $text");
      }
    }
  }
  
  /// Shows the toast using a fallback mechanism when the main method fails
  static void fallbackToast(String text) {
    if (text.isEmpty) return;
    
    // Print to console as absolute fallback
    debugPrint("TOAST: $text");
  }
}
