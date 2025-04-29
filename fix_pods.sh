#!/bin/bash

# fix_pods.sh - Script to properly setup Pods for macOS and iOS builds
# This script follows the build instructions from CLAUDE.md

# Exit on any error
set -e

# Display what we're doing
echo "🚀 Setting up CocoaPods for macOS and iOS..."

# Step 1: Initialize rbenv (if it exists)
if command -v rbenv &> /dev/null; then
  echo "🔧 Initializing rbenv..."
  eval "$(rbenv init -)"
else
  echo "⚠️ rbenv not found, using system Ruby instead"
fi

# Step 2: Verify Ruby version (should be 3.2.2+)
ruby_version=$(ruby -v | awk '{print $2}')
echo "📋 Using Ruby version: $ruby_version"

# Step 3: Clean Flutter project
echo "🧹 Cleaning Flutter project..."
flutter clean
flutter pub get

# Step 4: Fix architecture issues with cryptography_flutter
echo "🔧 Fixing cryptography_flutter issues..."

# Create a GeneratedPluginRegistrant.swift file without cryptography_flutter
mkdir -p macos/Flutter
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

# Make the file read-only to prevent Flutter from modifying it
chmod -w macos/Flutter/GeneratedPluginRegistrant.swift

# Create a dummy implementation of cryptography_flutter
mkdir -p macos/Runner/Plugins
cat > macos/Runner/Plugins/CryptographyFlutterDummy.swift << 'EOF'
import FlutterMacOS
import Foundation

// This is a dummy implementation of the cryptography_flutter plugin
// to avoid build failures on macOS
public class CryptographyFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // No-op implementation
    print("Dummy CryptographyFlutterPlugin registered")
  }
}
EOF

# Create a fixed Podfile for macOS
cat > macos/Podfile << 'EOF'
platform :osx, '10.15'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

# Suppress warning about not specifying the CocoaPods master specs repo
install! 'cocoapods', :warn_for_unused_master_specs_repo => false

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

  flutter_install_all_macos_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_macos_build_settings(target)
    
    # Force ARM64 architecture for all build configurations
    target.build_configurations.each do |config|
      # Set architecture to ARM64 only and disable x86_64
      config.build_settings['ARCHS'] = 'arm64'
      config.build_settings['EXCLUDED_ARCHS[sdk=macosx*]'] = 'x86_64'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
      
      # Ensure minimum macOS version is set correctly
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.15'
    end
  end
end
EOF

# Setup directories for pod installation
mkdir -p macos/.symlinks/plugins

# Step 5: Install pods for macOS
echo "🔄 Installing pods for macOS..."
cd macos
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..

# Step 6: Install pods for iOS
echo "🔄 Installing pods for iOS..."
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..

echo "✅ CocoaPods setup complete!"
echo ""
echo "To build for macOS: flutter build macos --debug --no-tree-shake-icons"
echo "To build for iOS: flutter build ios --debug --no-codesign"