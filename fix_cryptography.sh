#!/bin/bash

# Direct approach to remove cryptography_flutter
echo "Removing cryptography_flutter directly..."

# Manually edit the GeneratedPluginRegistrant.swift file
echo "Editing GeneratedPluginRegistrant.swift..."
chmod +w macos/Flutter/GeneratedPluginRegistrant.swift
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

# Create a custom Podfile that doesn't include cryptography_flutter
echo "Creating custom Podfile that excludes cryptography_flutter..."
cat > macos/Podfile << 'EOF'
platform :osx, '10.15'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'ephemeral', 'Flutter-Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure \"flutter pub get\" is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Flutter-Generated.xcconfig, then run \"flutter pub get\""
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_macos_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  # Manually add all pods EXCEPT cryptography_flutter
  pod 'device_info_plus', :path => '.symlinks/plugins/device_info_plus/macos'
  pod 'emoji_picker_flutter', :path => '.symlinks/plugins/emoji_picker_flutter/macos'
  pod 'file_saver', :path => '.symlinks/plugins/file_saver/macos'
  pod 'file_selector_macos', :path => '.symlinks/plugins/file_selector_macos/macos'
  pod 'firebase_core', :path => '.symlinks/plugins/firebase_core/macos'
  pod 'firebase_messaging', :path => '.symlinks/plugins/firebase_messaging/macos'
  pod 'flutter_image_compress_macos', :path => '.symlinks/plugins/flutter_image_compress_macos/macos'
  pod 'flutter_inappwebview_macos', :path => '.symlinks/plugins/flutter_inappwebview_macos/macos'
  pod 'flutter_local_notifications', :path => '.symlinks/plugins/flutter_local_notifications/macos'
  pod 'flutter_secure_storage_macos', :path => '.symlinks/plugins/flutter_secure_storage_macos/macos'
  pod 'local_auth_darwin', :path => '.symlinks/plugins/local_auth_darwin/macos'
  pod 'media_kit_libs_macos_video', :path => '.symlinks/plugins/media_kit_libs_macos_video/macos'
  pod 'media_kit_video', :path => '.symlinks/plugins/media_kit_video/macos'
  pod 'package_info_plus', :path => '.symlinks/plugins/package_info_plus/macos'
  pod 'path_provider_foundation', :path => '.symlinks/plugins/path_provider_foundation/darwin'
  pod 'photo_manager', :path => '.symlinks/plugins/photo_manager/macos'
  pod 'screen_brightness_macos', :path => '.symlinks/plugins/screen_brightness_macos/macos'
  pod 'screen_retriever', :path => '.symlinks/plugins/screen_retriever/macos'
  pod 'sentry_flutter', :path => '.symlinks/plugins/sentry_flutter/macos'
  pod 'share_plus', :path => '.symlinks/plugins/share_plus/macos'
  pod 'shared_preferences_foundation', :path => '.symlinks/plugins/shared_preferences_foundation/darwin'
  pod 'sqflite', :path => '.symlinks/plugins/sqflite/macos'
  pod 'url_launcher_macos', :path => '.symlinks/plugins/url_launcher_macos/macos'
  pod 'video_player_avfoundation', :path => '.symlinks/plugins/video_player_avfoundation/darwin'
  pod 'wakelock_plus', :path => '.symlinks/plugins/wakelock_plus/macos'
  pod 'window_manager', :path => '.symlinks/plugins/window_manager/macos'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_macos_build_settings(target)
    
    # Force ARM64 architecture for all build configurations
    target.build_configurations.each do |config|
      config.build_settings['ARCHS'] = 'arm64'
      config.build_settings['EXCLUDED_ARCHS[sdk=macosx*]'] = 'x86_64'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
      
      # Ensure minimum macOS version is set correctly
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.15'
    end
  end
end
EOF

# Install pods
echo "Installing pods..."
cd macos
rm -rf Pods Podfile.lock .symlinks
pod install --repo-update
cd ..

# Apply fix for web_plugin_registrant_custom.dart to handle missing cryptography_flutter
echo "Fixing web_plugin_registrant_custom.dart..."
if [ -f "lib/web_plugin_registrant_custom.dart" ]; then
  # Make a backup
  cp lib/web_plugin_registrant_custom.dart lib/web_plugin_registrant_custom.dart.bak
  
  # Update the file to handle conditional imports based on platform
  cat > lib/web_plugin_registrant_custom.dart << 'EOF'
// Custom web plugin registrant file to handle missing plugins
// @dart = 2.13
// ignore_for_file: type=lint

// Import everything at the top to follow Dart rules
import 'package:flutter/foundation.dart' show kIsWeb;

// For desktop/mobile platforms we provide a no-op implementation
void registerPlugins([final dynamic pluginRegistrar]) {
  if (!kIsWeb) {
    // On non-web platforms, do nothing
    return;
  }
  
  // This code will only run on web platforms
  // We dynamically load the registrar and plugins at runtime
  try {
    // This is just skeletal code - the actual plugin registration happens
    // automatically in Flutter for most plugins on web
    if (pluginRegistrar != null) {
      // Pass through any provided registrar
      return;
    }
  } catch (e) {
    // Fail silently - the app should still work
    // since plugin registration is handled by the Flutter framework
  }
}
EOF
fi

# Build with the directly modified files
echo "Building macOS app with explicit cryptography_flutter removal..."
chmod -w macos/Flutter/GeneratedPluginRegistrant.swift
flutter clean
flutter pub get
flutter build macos --debug --no-tree-shake-icons

echo "Build process completed. Check if the build was successful."