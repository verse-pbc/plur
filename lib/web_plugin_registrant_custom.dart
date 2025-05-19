// Simplified web plugin registrant file to handle platform-specific plugin initialization
// @dart = 2.13
// ignore_for_file: type=lint

import 'package:flutter/foundation.dart' show kIsWeb;

// Platform-aware plugin registration
void registerPlugins([final dynamic pluginRegistrar]) {
  print('Web plugin registrant: registerPlugins called');
  // No-op function to avoid "Bad state: Could not find summary for library" error
  // This empty implementation allows the app to avoid dependency errors 
  // while maintaining compatibility with web platforms
}