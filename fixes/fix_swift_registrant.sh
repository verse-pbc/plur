#!/bin/bash
# Fix for GeneratedPluginRegistrant.swift

echo "🔧 Setting up GeneratedPluginRegistrant.swift..."

# Make Flutter directory and GeneratedPluginRegistrant.swift modifiable
mkdir -p macos/Flutter
mkdir -p macos/Runner/Plugins

# Make sure we have full permissions for flutter directories (debugging)
echo "📂 Ensuring appropriate permissions..."
chmod -R 755 macos/Flutter
chmod -R 755 macos/Runner/Plugins

# Make sure existing file is writable
if [ -f "macos/Flutter/GeneratedPluginRegistrant.swift" ]; then
  echo "🔓 Making existing GeneratedPluginRegistrant.swift writable..."
  chmod 644 macos/Flutter/GeneratedPluginRegistrant.swift
fi

# Get the list of plugins from pubspec.yaml but exclude cryptography_flutter
echo "📋 Creating GeneratedPluginRegistrant.swift..."
cat > macos/Flutter/GeneratedPluginRegistrant.swift << 'EOF'
//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import device_info_plus
import emoji_picker_flutter
import file_saver
import file_selector_macos
import firebase_core
import firebase_messaging
import flutter_image_compress_macos
import flutter_inappwebview_macos
import flutter_local_notifications
import flutter_secure_storage_macos
import local_auth_darwin
import media_kit_libs_macos_video
import media_kit_video
import package_info_plus
import path_provider_foundation
import photo_manager
import screen_brightness_macos
import screen_retriever
import sentry_flutter
import share_plus
import shared_preferences_foundation
import sqflite
import url_launcher_macos
import video_player_avfoundation
import wakelock_plus
import window_manager

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  // Using dummy CryptographyFlutterPlugin from Plugins directory
  CryptographyFlutterPlugin.register(with: registry.registrar(forPlugin: "CryptographyFlutterPlugin"))
  DeviceInfoPlusMacosPlugin.register(with: registry.registrar(forPlugin: "DeviceInfoPlusMacosPlugin"))
  EmojiPickerFlutterPlugin.register(with: registry.registrar(forPlugin: "EmojiPickerFlutterPlugin"))
  FileSaverPlugin.register(with: registry.registrar(forPlugin: "FileSaverPlugin"))
  FileSelectorPlugin.register(with: registry.registrar(forPlugin: "FileSelectorPlugin"))
  FLTFirebaseCorePlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseCorePlugin"))
  FLTFirebaseMessagingPlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseMessagingPlugin"))
  FlutterImageCompressMacosPlugin.register(with: registry.registrar(forPlugin: "FlutterImageCompressMacosPlugin"))
  InAppWebViewFlutterPlugin.register(with: registry.registrar(forPlugin: "InAppWebViewFlutterPlugin"))
  FlutterLocalNotificationsPlugin.register(with: registry.registrar(forPlugin: "FlutterLocalNotificationsPlugin"))
  FlutterSecureStoragePlugin.register(with: registry.registrar(forPlugin: "FlutterSecureStoragePlugin"))
  FLALocalAuthPlugin.register(with: registry.registrar(forPlugin: "FLALocalAuthPlugin"))
  MediaKitLibsMacosVideoPlugin.register(with: registry.registrar(forPlugin: "MediaKitLibsMacosVideoPlugin"))
  MediaKitVideoPlugin.register(with: registry.registrar(forPlugin: "MediaKitVideoPlugin"))
  FPPPackageInfoPlusPlugin.register(with: registry.registrar(forPlugin: "FPPPackageInfoPlusPlugin"))
  PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
  PhotoManagerPlugin.register(with: registry.registrar(forPlugin: "PhotoManagerPlugin"))
  ScreenBrightnessMacosPlugin.register(with: registry.registrar(forPlugin: "ScreenBrightnessMacosPlugin"))
  ScreenRetrieverPlugin.register(with: registry.registrar(forPlugin: "ScreenRetrieverPlugin"))
  SentryFlutterPlugin.register(with: registry.registrar(forPlugin: "SentryFlutterPlugin"))
  SharePlusMacosPlugin.register(with: registry.registrar(forPlugin: "SharePlusMacosPlugin"))
  SharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "SharedPreferencesPlugin"))
  SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin"))
  UrlLauncherPlugin.register(with: registry.registrar(forPlugin: "UrlLauncherPlugin"))
  FVPVideoPlayerPlugin.register(with: registry.registrar(forPlugin: "FVPVideoPlayerPlugin"))
  WakelockPlusMacosPlugin.register(with: registry.registrar(forPlugin: "WakelockPlusMacosPlugin"))
  WindowManagerPlugin.register(with: registry.registrar(forPlugin: "WindowManagerPlugin"))
}
EOF

# Create dummy CryptographyFlutterPlugin if it doesn't exist
if [ ! -f "macos/Runner/Plugins/CryptographyFlutterPlugin.swift" ]; then
  echo "📝 Creating dummy CryptographyFlutterPlugin..."
  cat > "macos/Runner/Plugins/CryptographyFlutterPlugin.swift" << 'EOF'
import FlutterMacOS
import Foundation

// Dummy implementation of the cryptography_flutter plugin to avoid build failures
public class CryptographyFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // No-op implementation for compatibility
    print("Dummy CryptographyFlutterPlugin registered for macOS")
  }
}
EOF
fi

# Make GeneratedPluginRegistrant.swift read-only to prevent Flutter from regenerating it
echo "🔒 Setting permissions to prevent Flutter from overwriting our files..."
chmod 444 "macos/Flutter/GeneratedPluginRegistrant.swift"
chmod 444 "macos/Runner/Plugins/CryptographyFlutterPlugin.swift"

# Make flutter_export_environment.sh writable (Flutter needs to update this file)
if [ -f "macos/Flutter/flutter_export_environment.sh" ]; then
  chmod 644 "macos/Flutter/flutter_export_environment.sh"
fi

# Make Generated.xcconfig writable (Flutter needs to update this file)
if [ -f "macos/Flutter/Generated.xcconfig" ]; then
  chmod 644 "macos/Flutter/Generated.xcconfig"
fi

echo "✅ Fixed GeneratedPluginRegistrant.swift successfully!"
echo "🚀 Now try building with: flutter build macos --debug --no-tree-shake-icons"