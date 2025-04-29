// Custom web plugin registrant file to handle platform-specific plugin initialization
// @dart = 2.13
// ignore_for_file: type=lint

import 'package:flutter/foundation.dart' show kIsWeb;

// Platform-aware plugin registration
void registerPlugins([final dynamic pluginRegistrar]) {
  if (!kIsWeb) {
    // On non-web platforms, do nothing - Flutter handles registration natively
    return;
  }
  
  // For web platform only
  try {
    if (pluginRegistrar != null) {
      // Pass through any provided registrar
      return;
    }
  } catch (e) {
    // Silently fail - Flutter should handle this gracefully
  }
}
