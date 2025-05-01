#!/bin/bash

# Build macOS with ARM64-only configuration
# This script completely removes cryptography_flutter to make macOS builds work

# Exit on error
set -e

# Step 1: Show what we're doing
echo "🚀 Building macOS with ARM64-only configuration..."
echo "This script will:"
echo "1. Clean the Flutter project"
echo "2. Pin cryptography_flutter in dependency overrides"
echo "3. Configure Podfile for ARM64-only architecture"
echo "4. Create a dummy cryptography_flutter plugin"
echo "5. Use a custom GeneratedPluginRegistrant without cryptography_flutter"
echo ""

# Step 2: Clean the project
echo "🧹 Cleaning project..."
flutter clean
rm -rf macos/Pods macos/Podfile.lock macos/.symlinks build/macos

# Step 3: Pin cryptography_flutter in dependency overrides
echo "📦 Updating dependencies..."
if ! grep -q "cryptography_flutter:" pubspec.yaml ; then
  echo "Adding cryptography_flutter override to pubspec.yaml..."
  sed -i '' '/dependency_overrides:/a\
  cryptography_flutter: 2.3.2
' pubspec.yaml
fi

# Step 4: Get dependencies
flutter pub get

# Step 5: Create a dummy cryptography plugin
echo "🔧 Creating dummy plugin implementation..."
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

# Step 6: Create a fixed GeneratedPluginRegistrant.swift
echo "📄 Creating fixed GeneratedPluginRegistrant.swift..."
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

# Step 7: Update the Podfile to force ARM64 architecture
echo "🛠️ Updating Podfile..."
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

  # Loop through all plugins except cryptography_flutter
  all_plugins = Dir.glob(File.join('.symlinks', 'plugins', '*', 'macos')).map { |p| File.basename(File.dirname(p)) }
  all_plugins.each do |plugin_name|
    next if plugin_name == 'cryptography_flutter'
    plugin_path = File.expand_path("../.symlinks/plugins/#{plugin_name}/macos", __FILE__)
    
    if File.exist?(plugin_path)
      pod plugin_name, :path => plugin_path
    end
  end
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
      
      # Add a build flag to explicitly target ARM64 only
      config.build_settings['OTHER_LDFLAGS'] ||= '$(inherited)'
      config.build_settings['OTHER_LDFLAGS'] << ' -arch arm64'
    end
  end
end
EOF

# Step 8: Update xcodeproj file to exclude x86_64 architecture
echo "🔧 Updating Xcode project settings for ARM64-only build..."
PROJECT_FILE="macos/Runner.xcodeproj/project.pbxproj"
if [ -f "$PROJECT_FILE" ]; then
  # Make backup
  cp "$PROJECT_FILE" "${PROJECT_FILE}.bak"
  
  # Update architecture settings
  sed -i '' 's/ARCHS = "$(ARCHS_STANDARD)";/ARCHS = "arm64";/g' "$PROJECT_FILE"
  sed -i '' 's/VALID_ARCHS = ".*";/VALID_ARCHS = "arm64";/g' "$PROJECT_FILE"
  sed -i '' 's/EXCLUDED_ARCHS = ".*";/EXCLUDED_ARCHS = "x86_64";/g' "$PROJECT_FILE"
  sed -i '' 's/ONLY_ACTIVE_ARCH = NO;/ONLY_ACTIVE_ARCH = YES;/g' "$PROJECT_FILE"
fi

# Step 9: Run pod install with the updated Podfile
echo "🔄 Installing pods..."
cd macos
export ARCHS=arm64
pod install --repo-update
cd ..

# Step 10: Make GeneratedPluginRegistrant.swift read-only
echo "🔒 Making GeneratedPluginRegistrant.swift read-only..."
chmod -w macos/Flutter/GeneratedPluginRegistrant.swift

# Step 11: Build the app
echo "🏗️ Building macOS app with ARM64-only configuration..."
# We need to use --no-tree-shake-icons to prevent Flutter from regenerating the plugin registrant
ARCHS=arm64 flutter build macos --debug --no-tree-shake-icons

echo "✅ macOS build process completed! The app was built for ARM64 architecture only."
echo ""
echo "To run the app, use: flutter run -d macos"
echo "To build for release, use this script with: flutter build macos --release --no-tree-shake-icons"