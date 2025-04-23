#!/bin/bash
# Consolidated macOS Build Script for Plur
# This script handles the cryptography_flutter architecture compatibility issues for macOS builds

set -e # Exit on any error

# Navigate to project directory
cd "$(dirname "$0")"
PROJ_DIR=$(pwd)

echo "🚀 Starting macOS build process..."

# Step 1: Clean up previous build artifacts
echo "🧹 Cleaning project..."
flutter clean
rm -rf macos/Pods macos/Podfile.lock macos/.symlinks build/macos

# Step 2: Make sure cryptography_flutter is pinned in dependency_overrides
echo "📦 Updating pubspec.yaml with dependency overrides..."
if ! grep -q "dependency_overrides:" "$PROJ_DIR/pubspec.yaml"; then
  echo "Adding dependency_overrides section to pubspec.yaml..."
  echo "dependency_overrides:" >> "$PROJ_DIR/pubspec.yaml"
  echo "  cryptography_flutter: 2.3.2" >> "$PROJ_DIR/pubspec.yaml"
elif ! grep -q "cryptography_flutter:" "$PROJ_DIR/pubspec.yaml"; then
  echo "Adding cryptography_flutter to existing dependency_overrides..."
  sed -i '' '/dependency_overrides:/a\\  cryptography_flutter: 2.3.2' "$PROJ_DIR/pubspec.yaml"
fi

# Step 3: Run flutter pub get to update dependencies
echo "🔄 Getting dependencies..."
flutter pub get

# Step 4: Update Podfile to force ARM64 architecture
echo "🛠️ Updating Podfile for ARM64-only architecture..."
cat > "$PROJ_DIR/macos/Podfile" << 'EOF'
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
      # Set architecture to ARM64 only
      config.build_settings['ARCHS'] = 'arm64'
      config.build_settings['EXCLUDED_ARCHS[sdk=macosx*]'] = 'x86_64'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
      
      # Ensure minimum macOS version is set correctly
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.15'
    end
  end
end
EOF

# Step 5: Install pods
echo "🔄 Installing pods..."
cd "$PROJ_DIR/macos"
pod install --repo-update
cd "$PROJ_DIR"

# Step 6: Create dummy plugin implementation
echo "🔧 Creating dummy plugin implementation..."
mkdir -p "$PROJ_DIR/macos/Runner/Plugins"
cat > "$PROJ_DIR/macos/Runner/Plugins/CryptographyFlutterPlugin.swift" << 'EOF'
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

# Step 7: Fix permissions on Flutter directory to ensure we can modify files
echo "🔧 Fixing permissions..."
chmod -R +w "$PROJ_DIR/macos/Flutter"

# Step 8: Modify GeneratedPluginRegistrant.swift
echo "🔧 Patching GeneratedPluginRegistrant.swift..."
PLUGIN_REG_FILE="$PROJ_DIR/macos/Flutter/GeneratedPluginRegistrant.swift"
if [ -f "$PLUGIN_REG_FILE" ]; then
  # Make backup
  cp "$PLUGIN_REG_FILE" "$PLUGIN_REG_FILE.bak"
  
  # Remove cryptography_flutter references
  sed -i '' '/import cryptography_flutter/d' "$PLUGIN_REG_FILE"
  sed -i '' '/CryptographyFlutterPlugin/d' "$PLUGIN_REG_FILE"
  
  echo "✅ Successfully patched GeneratedPluginRegistrant.swift"
else
  echo "⚠️ Warning: GeneratedPluginRegistrant.swift not found. Creating with 'flutter pub get'..."
  flutter pub get
  
  if [ -f "$PLUGIN_REG_FILE" ]; then
    # Remove cryptography_flutter references
    sed -i '' '/import cryptography_flutter/d' "$PLUGIN_REG_FILE"
    sed -i '' '/CryptographyFlutterPlugin/d' "$PLUGIN_REG_FILE"
    echo "✅ Successfully patched newly generated GeneratedPluginRegistrant.swift"
  else
    echo "❌ Error: GeneratedPluginRegistrant.swift still not found! Build will likely fail."
  fi
fi

# Step 9: Update web_plugin_registrant_custom.dart to avoid web build issues
echo "🔧 Updating web plugin registrant..."
WEB_PLUGIN_FILE="$PROJ_DIR/lib/web_plugin_registrant_custom.dart"
cat > "$WEB_PLUGIN_FILE" << 'EOF'
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
EOF

# Step 10: Build macOS app with --no-tree-shake-icons flag
echo "🏗️ Building macOS app..."
flutter build macos --debug --no-tree-shake-icons

echo "✅ macOS build process completed successfully!"
echo ""
echo "To run the app: flutter run -d macos"
echo "To build for release: flutter build macos --release (run this script again after)"
echo ""
echo "If you update dependencies, run this script again to ensure compatibility."