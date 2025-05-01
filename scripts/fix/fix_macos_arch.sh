#!/bin/bash

# Script to fix architecture issues for macOS builds
echo "Starting macOS architecture fix script..."

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Step 1: Update pubspec and get dependencies
echo "Running flutter pub get..."
flutter pub get

# Step 2: Modify Podfile to ensure ARM64 architecture
echo "Updating Podfile for ARM64 architecture..."
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

  flutter_install_all_macos_pods File.dirname(File.realpath(__FILE__))
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
  
  # Additional settings for specific problematic pods if needed
  installer.pods_project.targets.each do |target|
    if ['cryptography_flutter', 'Pods-Runner'].include?(target.name)
      target.build_configurations.each do |config|
        # Force these specific pods to arm64 architecture
        config.build_settings['ARCHS'] = 'arm64'
        config.build_settings['VALID_ARCHS'] = 'arm64'
        config.build_settings['EXCLUDED_ARCHS[sdk=macosx*]'] = 'x86_64'
        config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
      end
    end
  end
end
EOF

# Step 3: Update Xcode project settings to force ARM64
echo "Updating Xcode project for ARM64 architecture..."
PROJECT_FILE="macos/Runner.xcodeproj/project.pbxproj"

# Backup the project file
cp "$PROJECT_FILE" "${PROJECT_FILE}.bak"

# Update the project file
sed -i '' 's/ARCHS = "$(ARCHS_STANDARD)";/ARCHS = "arm64";/g' "$PROJECT_FILE"
sed -i '' 's/VALID_ARCHS = ".*";/VALID_ARCHS = "arm64";/g' "$PROJECT_FILE"
sed -i '' 's/EXCLUDED_ARCHS = ".*";/EXCLUDED_ARCHS = "x86_64";/g' "$PROJECT_FILE"

# Create a modified version of GeneratedPluginRegistrant.swift without cryptography_flutter
echo "Creating modified GeneratedPluginRegistrant.swift..."
cat > macos/Flutter/GeneratedPluginRegistrant.swift << 'EOF'
//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

#if arch(arm64)
import cryptography_flutter
#endif
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
  #if arch(arm64)
  CryptographyFlutterPlugin.register(with: registry.registrar(forPlugin: "CryptographyFlutterPlugin"))
  #endif
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

# Step 4: Clean up and reinstall pods
echo "Cleaning up and reinstalling pods..."
rm -rf macos/Pods
rm -rf macos/Podfile.lock
rm -rf macos/.symlinks
rm -rf build/macos

# Step 5: Run pod install with architecture settings
echo "Running pod install..."
cd macos
export ARCHS=arm64
pod install --repo-update

echo "Script completed. Now try building for macOS with: flutter build macos"