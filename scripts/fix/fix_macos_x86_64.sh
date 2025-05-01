#!/bin/bash

# Advanced fix for macOS build with architecture-specific exclusion
echo "Fixing macOS build with x86_64 architecture issues..."

# Clean the project
echo "Cleaning project..."
flutter clean

# Get dependencies to regenerate symlinks
echo "Getting dependencies..."
flutter pub get

# Check what's generated
if [ -f "macos/Flutter/GeneratedPluginRegistrant.swift" ]; then
  echo "GeneratedPluginRegistrant.swift exists."
  
  # Make file writable
  chmod +w macos/Flutter/GeneratedPluginRegistrant.swift
  
  # Create backup
  cp macos/Flutter/GeneratedPluginRegistrant.swift macos/Flutter/GeneratedPluginRegistrant.swift.bak
  
  # Remove cryptography_flutter lines
  echo "Removing cryptography_flutter references..."
  sed -i '' '/import cryptography_flutter/d' macos/Flutter/GeneratedPluginRegistrant.swift
  sed -i '' '/CryptographyFlutterPlugin/d' macos/Flutter/GeneratedPluginRegistrant.swift
else
  echo "GeneratedPluginRegistrant.swift doesn't exist yet."
fi

# Update Podfile to exclude x86_64 architecture
echo "Updating Podfile to exclude x86_64 architecture..."
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

# Run pod install
echo "Installing pods..."
cd macos
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..

# Force Flutter not to regenerate the GeneratedPluginRegistrant.swift
echo "Making GeneratedPluginRegistrant.swift read-only..."
chmod -w macos/Flutter/GeneratedPluginRegistrant.swift

# Create a build wrapper script
echo "Creating a build wrapper script..."
cat > build_macos.sh << 'EOF'
#!/bin/bash

# Fix GeneratedPluginRegistrant.swift
if [ -f "macos/Flutter/GeneratedPluginRegistrant.swift" ]; then
  echo "Fixing GeneratedPluginRegistrant.swift..."
  chmod +w macos/Flutter/GeneratedPluginRegistrant.swift
  sed -i '' '/import cryptography_flutter/d' macos/Flutter/GeneratedPluginRegistrant.swift
  sed -i '' '/CryptographyFlutterPlugin/d' macos/Flutter/GeneratedPluginRegistrant.swift
  chmod -w macos/Flutter/GeneratedPluginRegistrant.swift
fi

# Build with architecture-specific settings
echo "Building macOS app..."
flutter build macos --debug --no-tree-shake-icons
EOF

chmod +x build_macos.sh

echo "Fix completed!"
echo "Run ./build_macos.sh to build the macOS app"