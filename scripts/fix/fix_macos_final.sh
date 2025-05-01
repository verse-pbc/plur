#!/bin/bash

# Final approach to fix macOS build by ensuring plugin symlinks are properly generated
echo "Fixing macOS build with cryptography_flutter workaround..."

# Clean the project first
echo "Cleaning project..."
flutter clean

# Get dependencies to regenerate symlinks
echo "Getting dependencies..."
flutter pub get

# Make sure GeneratedPluginRegistrant.swift is writable
chmod +w macos/Flutter/GeneratedPluginRegistrant.swift

# Remove cryptography_flutter references using sed
echo "Removing cryptography_flutter references..."
sed -i '' '/import cryptography_flutter/d' macos/Flutter/GeneratedPluginRegistrant.swift
sed -i '' '/CryptographyFlutterPlugin/d' macos/Flutter/GeneratedPluginRegistrant.swift

# Update Podfile to manually exclude cryptography_flutter
echo "Updating Podfile to exclude cryptography_flutter..."
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

  # Use flutter_install_all_ios_pods without crypto
  # Get all plugins and manually exclude cryptography_flutter
  all_pods = Dir.glob(File.join('.symlinks', 'plugins', '*', 'macos'))
  all_pods.each do |plugin_path|
    plugin_name = File.basename(File.dirname(plugin_path))
    next if plugin_name == 'cryptography_flutter'
    
    podspec_path = File.join(plugin_path, "#{plugin_name}.podspec")
    if File.exists?(podspec_path)
      pod plugin_name, :path => plugin_path
    end
  end
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

# Install pods with the updated Podfile
echo "Installing pods..."
cd macos
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..

# Create a simple script that can be run before each build
echo "Creating a reusable script for future builds..."
cat > macos_pre_build.sh << 'EOF'
#!/bin/bash
# Run this script before building for macOS to prevent cryptography_flutter issues

echo "Applying pre-build fixes for macOS..."
chmod +w macos/Flutter/GeneratedPluginRegistrant.swift
sed -i '' '/import cryptography_flutter/d' macos/Flutter/GeneratedPluginRegistrant.swift
sed -i '' '/CryptographyFlutterPlugin/d' macos/Flutter/GeneratedPluginRegistrant.swift
echo "Fixed! Now run 'flutter build macos'"
EOF
chmod +x macos_pre_build.sh

echo "Fix completed!"
echo ""
echo "To build for macOS, run:"
echo "  ./macos_pre_build.sh && flutter build macos"
echo ""
echo "If you update your dependencies, run this script again."