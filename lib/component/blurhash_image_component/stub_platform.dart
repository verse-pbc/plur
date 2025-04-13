// Platform utility for consistent platform checks
// This allows a single interface to be used across all platforms

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;

class SafePlatform {
  // Safe check for web platform
  static bool isWeb() {
    return kIsWeb;
  }
  
  // Safe check for iOS platform
  static bool isIOS() {
    if (kIsWeb) return false;
    try {
      return io.Platform.isIOS;
    } catch (e) {
      return false;
    }
  }
  
  // Safe check for macOS platform
  static bool isMacOS() {
    if (kIsWeb) return false;
    try {
      return io.Platform.isMacOS;
    } catch (e) {
      return false;
    }
  }
  
  // Safe check for android platform
  static bool isAndroid() {
    if (kIsWeb) return false;
    try {
      return io.Platform.isAndroid;
    } catch (e) {
      return false;
    }
  }
  
  // Safe check for Windows platform
  static bool isWindows() {
    if (kIsWeb) return false;
    try {
      return io.Platform.isWindows;
    } catch (e) {
      return false;
    }
  }
  
  // Safe check for Linux platform
  static bool isLinux() {
    if (kIsWeb) return false;
    try {
      return io.Platform.isLinux;
    } catch (e) {
      return false;
    }
  }
}

// Stub Platform implementation for web
// This is kept for backward compatibility
class Platform {
  static bool get isIOS => false;
  static bool get isMacOS => false;
  static bool get isAndroid => false;
  static bool get isLinux => false;
  static bool get isWindows => false;
  static bool get isFuchsia => false;
}