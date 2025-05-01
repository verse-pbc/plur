#!/bin/bash

# Unified build fix for iOS and macOS on Apple Silicon machines
echo "🛠️ Universal Build Fix for iOS and macOS 🛠️"
echo "------------------------------------------"

# Clean everything
echo "Step 1: Cleaning project and derived data..."
flutter clean
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Get dependencies
echo "Step 2: Getting dependencies..."
flutter pub get

# Update Podfile with universal architecture settings
echo "Step 3: Updating Podfile with universal architecture settings..."
cat << 'EOF' > ios/Podfile
# Uncomment this line to define a global platform for your project
platform :ios, '15.5'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'
ENV['warn_for_unused_master_specs_repo'] = 'false'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Universal architecture settings
    target.build_configurations.each do |config|
      # Set deployment target to 15.5 for all configurations
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'
      
      # For physical iOS devices (arm64)
      if config.build_settings['SDKROOT'] == 'iphoneos'
        config.build_settings['ARCHS'] = 'arm64'
      end
      
      # For iOS simulator on Apple Silicon (x86_64 only)
      if config.build_settings['SDKROOT'] == 'iphonesimulator'
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
        config.build_settings['ARCHS[sdk=iphonesimulator*]'] = 'x86_64'
      end
      
      # Add permissions definitions for iOS
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
        'PERMISSION_PHOTOS=1',
        'PERMISSION_MICROPHONE=1',
        'PERMISSION_NOTIFICATIONS=1'
      ]
    end
  end
end
EOF

# Now do the same for macOS
echo "Step 4: Updating macOS Podfile..."
cat << 'EOF' > macos/Podfile
platform :osx, '10.14'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'
ENV['warn_for_unused_master_specs_repo'] = 'false'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'ephemeral', 'Flutter-Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure \"flutter pub get\" runs first"
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
    
    # macOS architecture settings - support both Apple Silicon and Intel
    target.build_configurations.each do |config|
      # Set universal binary for macOS (arm64 + x86_64)
      config.build_settings['ARCHS'] = 'arm64 x86_64'
      config.build_settings['VALID_ARCHS'] = 'arm64 x86_64'
      config.build_settings['EXCLUDED_ARCHS'] = ''
      
      # Don't build universal for debug on simulator due to a Flutter issue
      if config.name == 'Debug' && ENV['FLUTTER_SIMULATOR_ARCHS'] == 'x86_64'
        config.build_settings['EXCLUDED_ARCHS[sdk=*]'] = 'arm64'
      end
      
      # Use arm64 by default on Apple Silicon macs for release builds
      if ['Release', 'Profile'].include?(config.name) && !ENV['FLUTTER_SIMULATOR_ARCHS']
        config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
      end
    end
  end
end
EOF

# Create a custom xcconfig file for simulator
echo "Step 5: Creating custom xcconfig files..."
mkdir -p ios/Flutter/ArchConfig
cat << 'EOF' > ios/Flutter/ArchConfig/simulator_x86_64.xcconfig
# Force x86_64 for simulator on Apple Silicon
EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64
ARCHS[sdk=iphonesimulator*] = x86_64
ONLY_ACTIVE_ARCH = NO
FLUTTER_SIMULATOR_ARCHS = x86_64
EOF

cat << 'EOF' > ios/Flutter/ArchConfig/device_arm64.xcconfig
# Only arm64 for physical devices
ARCHS = arm64
ONLY_ACTIVE_ARCH = NO
EOF

cat << 'EOF' > ios/Flutter/ArchConfig/mac_universal.xcconfig
# Universal binary for macOS builds
ARCHS = arm64 x86_64
VALID_ARCHS = arm64 x86_64
EXCLUDED_ARCHS = 
ONLY_ACTIVE_ARCH = NO
MACOSX_DEPLOYMENT_TARGET = 10.14
EOF

# Update Debug.xcconfig to include our simulator config
echo "Step 6: Updating xcconfig files..."
echo "#include \"ArchConfig/simulator_x86_64.xcconfig\"" >> ios/Flutter/Debug.xcconfig
echo "#include \"ArchConfig/mac_universal.xcconfig\"" >> macos/Flutter/Debug.xcconfig
echo "#include \"ArchConfig/mac_universal.xcconfig\"" >> macos/Flutter/Release.xcconfig

# Reinstall pods
echo "Step 7: Reinstalling iOS pods..."
cd ios
rm -rf Pods
rm -f Podfile.lock
pod install --repo-update
cd ..

echo "Step 8: Reinstalling macOS pods..."
cd macos
rm -rf Pods
rm -f Podfile.lock
pod install --repo-update
cd ..

# Create helper scripts for specific targets
echo "Creating helper scripts for specific targets..."

# iOS Simulator script
cat << 'EOF' > run_ios_simulator.sh
#!/bin/bash
echo "Running app on iOS simulator (x86_64)..."
export FLUTTER_SIMULATOR_ARCHS=x86_64
flutter run -d "iPhone 16 Plus"
EOF
chmod +x run_ios_simulator.sh

# iOS Device script
cat << 'EOF' > run_ios_device.sh
#!/bin/bash
echo "Running app on iOS device (arm64)..."
flutter run -d "Rabble's iPhone"
EOF
chmod +x run_ios_device.sh

# macOS script
cat << 'EOF' > run_macos.sh
#!/bin/bash
echo "Running app on macOS (universal)..."
flutter run -d macos
EOF
chmod +x run_macos.sh

echo "✅ Setup complete!"
echo ""
echo "Use these scripts to run on different targets:"
echo "- ./run_ios_simulator.sh - Run on iOS simulator (x86_64)"
echo "- ./run_ios_device.sh - Run on iPhone/iPad (arm64)"
echo "- ./run_macos.sh - Run on macOS (universal binary)"
echo ""
echo "For App Store deployment, use Xcode for final signing and distribution:"
echo "1. open ios/Runner.xcworkspace"
echo "2. Select 'Any iOS Device (arm64)' as the build target"
echo "3. Create an archive with Product > Archive"