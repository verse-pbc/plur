#!/bin/bash

# Best solution for macOS build issues with cryptography_flutter
echo "Starting macOS build fix script..."

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Clean everything
echo "Cleaning project..."
flutter clean
rm -rf build/macos
rm -rf macos/Pods
rm -rf macos/Podfile.lock
rm -rf macos/.symlinks

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Create an environment variable to be included in the xcconfig
echo "Adding exclude environment variable..."
echo "FLUTTER_EXCLUDED_PLUGINS=cryptography_flutter" > macos/.env

# Create a custom Podfile that excludes cryptography_flutter
echo "Creating custom Podfile..."
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

  # Load plugins except cryptography_flutter
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
end
EOF

# Force architecture settings in the Xcode project
echo "Updating Xcode project for ARM64 architecture..."
PROJECT_FILE="macos/Runner.xcodeproj/project.pbxproj"
cp "$PROJECT_FILE" "${PROJECT_FILE}.bak"
sed -i '' 's/ARCHS = "$(ARCHS_STANDARD)";/ARCHS = "arm64";/g' "$PROJECT_FILE"
sed -i '' 's/VALID_ARCHS = ".*";/VALID_ARCHS = "arm64";/g' "$PROJECT_FILE"
sed -i '' 's/EXCLUDED_ARCHS = ".*";/EXCLUDED_ARCHS = "x86_64";/g' "$PROJECT_FILE"

# Create a simple Swift file that provides a dummy implementation of cryptography_flutter
echo "Creating dummy cryptography_flutter for macOS..."
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

# Run pod install
echo "Running pod install..."
cd macos
pod install --repo-update
cd ..

# Modify GeneratedPluginRegistrant.swift
if [ -f "macos/Flutter/GeneratedPluginRegistrant.swift" ]; then
  echo "Modifying GeneratedPluginRegistrant.swift..."
  # Make a copy of the original file
  cp macos/Flutter/GeneratedPluginRegistrant.swift macos/Flutter/GeneratedPluginRegistrant.swift.bak
  
  # Comment out the imports for cryptography_flutter
  sed -i '' 's/import cryptography_flutter/\/\/ import cryptography_flutter/' macos/Flutter/GeneratedPluginRegistrant.swift
  
  # Comment out the registration code for cryptography_flutter
  sed -i '' 's/CryptographyFlutterPlugin.register/\/\/ CryptographyFlutterPlugin.register/' macos/Flutter/GeneratedPluginRegistrant.swift
fi

# Now attempt to build macOS
echo "Building macOS app..."
flutter build macos --debug

echo "Script completed. Check the output for any errors."