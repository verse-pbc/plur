#!/bin/bash

# One-click macOS build fix script
# This script fixes macOS builds by handling cryptography_flutter incompatibility

set -e # Exit on error

echo "🚀 Plur macOS Build Helper"
echo "-------------------------"
echo "This script will fix cryptography_flutter issues and build the macOS version."
echo ""

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if we're on macOS
if [[ "$(uname)" != "Darwin" ]]; then
  echo "❌ ERROR: This script needs to be run on macOS!"
  exit 1
fi

# Clean up everything
echo "🧹 Cleaning project..."
flutter clean
rm -rf macos/Pods
rm -rf macos/Podfile.lock
rm -rf macos/.symlinks
rm -rf build/macos

# Make sure the build_macos.sh script is executable
if [[ -f "build_macos.sh" ]]; then
  chmod +x build_macos.sh
else
  echo "❌ ERROR: build_macos.sh not found! Creating it..."
  
  # Create build_macos.sh if it doesn't exist
  cat > build_macos.sh << 'EOF'
#!/bin/bash

# build_macos.sh - Comprehensive script to fix architecture issues and build macOS app
# This script fixes the macOS build by handling cryptography_flutter incompatibility
# while ensuring other platforms continue to work properly.

set -e # Exit on any error

# Navigate to project directory
cd "$(dirname "$0")"
PROJ_DIR=$(pwd)

echo "🚀 Starting macOS build process..."

# Step 1: Make sure cryptography_flutter is pinned in dependency_overrides
echo "📦 Updating pubspec.yaml with dependency overrides..."
if ! grep -q "cryptography_flutter:" "$PROJ_DIR/pubspec.yaml" ; then
  # Add cryptography_flutter to dependency_overrides if not already there
  sed -i '' '/dependency_overrides:/a\
  cryptography_flutter: 2.3.2
' "$PROJ_DIR/pubspec.yaml"
fi

# Step 2: Run flutter pub get to update dependencies
echo "🔄 Getting dependencies..."
flutter pub get

# Step 3: Update Podfile to force ARM64 architecture and exclude cryptography_flutter
echo "🛠️ Updating Podfile configuration..."
cat > "$PROJ_DIR/macos/Podfile" << 'PODEOF'
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
PODEOF

# Step 4: Install pods
echo "🔄 Installing pods..."
cd "$PROJ_DIR/macos"
rm -rf Pods Podfile.lock .symlinks
pod install --repo-update
cd "$PROJ_DIR"

# Step 5: Make sure we have the dummy plugin files
echo "🔧 Creating dummy plugin files..."
mkdir -p "$PROJ_DIR/macos/Runner/Plugins"
cat > "$PROJ_DIR/macos/Runner/Plugins/CryptographyFlutterDummy.swift" << 'PLUGINEOF'
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
PLUGINEOF

# Step 6: Fix permissions on the Flutter directory
echo "🔧 Fixing permissions..."
sudo chown -R $(whoami) "$PROJ_DIR/macos/Flutter"

# Step 7: Modify GeneratedPluginRegistrant.swift to exclude cryptography_flutter
echo "🔧 Patching GeneratedPluginRegistrant.swift..."
PLUGIN_REG_FILE="$PROJ_DIR/macos/Flutter/GeneratedPluginRegistrant.swift"
if [ -f "$PLUGIN_REG_FILE" ]; then
  # Make backup
  cp "$PLUGIN_REG_FILE" "$PLUGIN_REG_FILE.bak"
  
  # Remove cryptography_flutter references
  chmod +w "$PLUGIN_REG_FILE"
  sed -i '' '/import cryptography_flutter/d' "$PLUGIN_REG_FILE"
  sed -i '' '/CryptographyFlutterPlugin/d' "$PLUGIN_REG_FILE"
  
  echo "✅ Successfully patched GeneratedPluginRegistrant.swift"
else
  echo "❌ Error: GeneratedPluginRegistrant.swift not found!"
  exit 1
fi

# Step 8: Build macOS app with --no-tree-shake-icons to avoid regenerating files
echo "🏗️ Building macOS app..."
flutter build macos --debug --no-tree-shake-icons

echo "✅ macOS build process completed!"
echo ""
echo "If you need to build for other platforms:"
echo "- iOS/Android: No special handling required"
echo "- Web: Use normal build process"
echo ""
echo "To run the macOS app: flutter run -d macos"
EOF
  
  chmod +x build_macos.sh
fi

# Update web_plugin_registrant_custom.dart
echo "🔄 Updating web_plugin_registrant_custom.dart..."
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

# Run the main build script
echo "🔧 Running build_macos.sh..."
./build_macos.sh

# Check if the build was successful
if [[ $? -eq 0 ]]; then
  echo ""
  echo "✅ Success! The macOS app has been built successfully."
  echo ""
  echo "You can now run the app with:"
  echo "  flutter run -d macos"
  echo ""
  echo "To distribute the app, use:"
  echo "  flutter build macos --release"
  echo "  (Run this script again afterward to fix any regenerated files)"
else
  echo ""
  echo "❌ Build failed. Please check the error messages above."
  echo ""
  echo "Common issues:"
  echo "  - Permission problems: The script might need sudo access"
  echo "  - Flutter plugins regeneration: Try running the script again"
  echo "  - Outdated dependencies: Try running 'flutter pub upgrade'"
  echo ""
  echo "For more details, see MACOS_BUILD_FIX.md"
fi