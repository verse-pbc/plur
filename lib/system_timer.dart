import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';

import 'package:nostrmo/component/styled_bot_toast.dart';
import 'package:nostrmo/main.dart';

/// SystemTimer handles periodic background tasks in the app
/// Including cleaning up resources, checking for new data, and more
class SystemTimer {
  static int counter = 0;
  static Timer? timer;
  static Timer? toastCleanupTimer;

  /// Start all system timers
  static void run() {
    // Start the main timer
    _startMainTimer();
    
    // Start toast cleanup timer (runs less frequently)
    _startToastCleanupTimer();
  }

  /// Start the main periodic timer for app tasks
  static void _startMainTimer() {
    if (timer != null) {
      timer!.cancel();
    }
    timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      try {
        runTask();
        counter++;
      } catch (e, stack) {
        log('Error in SystemTimer.runTask: $e');
        if (kDebugMode) {
          log('Stack trace: $stack');
        }
      }
    });
    log('Main system timer started');
  }
  
  /// Start the toast cleanup timer
  static void _startToastCleanupTimer() {
    if (toastCleanupTimer != null) {
      toastCleanupTimer!.cancel();
    }
    
    // Clean up toast cancel functions every 2 minutes
    toastCleanupTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      try {
        StyledBotToast.cleanUp();
        if (kDebugMode) {
          log('Toast cleanup performed');
        }
      } catch (e) {
        log('Error cleaning up toasts: $e');
      }
    });
    log('Toast cleanup timer started');
  }

  /// Run scheduled periodic tasks
  static void runTask() {
    // log("SystemTimer runTask");
    if (nostr != null) {
      if (counter % 2 == 0) {
        // relayProvider.checkAndReconnect();
        if (counter > 8) {
          mentionMeNewProvider.queryNew();
          dmProvider.query();
        }
      } else {
        if (counter > 8) {
          followNewEventProvider.queryNew();
          giftWrapProvider.query();
        }
      }
    }

    if (counter % 10 == 0) {
      try {
        relayProvider.cleanTempRelays();
      } catch (e) {
        log('Error cleaning temp relays: $e');
      }
    }
  }

  /// Stop all system timers
  static void stopTask() {
    // Stop main timer
    if (timer != null) {
      timer!.cancel();
      timer = null;
    }
    
    // Stop toast cleanup timer
    if (toastCleanupTimer != null) {
      toastCleanupTimer!.cancel();
      toastCleanupTimer = null;
    }
    
    // Perform final cleanup
    try {
      StyledBotToast.cleanUp();
    } catch (e) {
      log('Error during final toast cleanup: $e');
    }
    
    log('All system timers stopped');
  }
}
