#!/bin/bash

# Script to completely disable Sentry in the Flutter app for iOS builds
# This is a more aggressive approach to fix build issues with Xcode 16.3 and iOS 18.4 SDK

echo "🔧 Completely disabling Sentry in the Flutter app..."

# Disable Sentry in the Podfile
PODFILE="Podfile"
if [ -f "$PODFILE" ]; then
  echo "Modifying Podfile to exclude Sentry"
  cp "$PODFILE" "${PODFILE}.bak"
  
  # Add Sentry exclusion to post_install
  sed -i.tmp '/post_install do |installer|/a\
  # Completely remove Sentry from the build\
  installer.pods_project.targets.each do |target|\
    if target.name.include?("Sentry")\
      target.build_configurations.each do |config|\
        config.build_settings["GCC_PREPROCESSOR_DEFINITIONS"] ||= ["$(inherited)"]\
        config.build_settings["GCC_PREPROCESSOR_DEFINITIONS"] << "SENTRY_NO_INIT=1"\
        config.build_settings["GCC_PREPROCESSOR_DEFINITIONS"] << "SENTRY_TARGET_PROFILING_SUPPORTED=0"\
        config.build_settings["EXCLUDED_SOURCE_FILE_NAMES"] = "*.cpp *.m *.mm"\
      end\
    end\
  end
' "$PODFILE"

  # Force specific Sentry version
  sed -i.tmp2 's/pod '\''Sentry'\'', '\''~> 8.15.0'\''/pod '\''Sentry'\'', '\''7.31.5'\''/g' "$PODFILE"
  
  echo "✅ Modified Podfile to disable Sentry"
fi

# Disable Sentry in Flutter code
MAIN_DART="../lib/main.dart"
if [ -f "$MAIN_DART" ]; then
  echo "Modifying main.dart to disable Sentry initialization"
  cp "$MAIN_DART" "${MAIN_DART}.bak"
  
  # Replace Sentry initialization with stub
  sed -i.tmp 's/Sentry.init/\/\/ Disabled: Sentry.init/g' "$MAIN_DART"
  
  echo "✅ Modified main.dart to disable Sentry initialization"
fi

# Create a completely empty Sentry stub
SENTRY_STUB="../lib/sentry_stub.dart"
echo "Creating empty Sentry stub implementation"
cat > "$SENTRY_STUB" << 'EOL'
// Empty Sentry stub that does nothing but maintains API compatibility
// This is used to disable Sentry when it causes build issues

class SentryStub {
  static Future<void> init(Function(dynamic options) callback) async {
    print('Sentry initialization disabled');
    // Do nothing - Sentry is disabled
  }
}

// Replace real Sentry with stub in imports
class Sentry {
  static Future<void> init(Function(dynamic options) callback) async {
    print('Sentry initialization disabled');
    // Do nothing - Sentry is disabled
  }
}
EOL

echo "✅ Created Sentry stub implementation"

# Create a script to patch the Flutter project
echo "Creating patch script for Flutter imports"
cat > "patch_flutter_sentry.sh" << 'EOL'
#!/bin/bash

# Find all Dart files that import Sentry
find ../lib -name "*.dart" -type f -exec grep -l "import 'package:sentry" {} \; | while read -r file; do
  echo "Patching $file to use stub Sentry"
  # Replace Sentry import with local stub
  sed -i.sentrybak "s|import 'package:sentry|import '../sentry_stub.dart' // Disabled: import 'package:sentry|g" "$file"
done

echo "✅ Patched all Sentry imports to use stub implementation"
EOL

chmod +x "patch_flutter_sentry.sh"

echo "✅ Sentry completely disabled in the Flutter app!"
echo "To apply these changes:"
echo "1. Run 'pod install' to update CocoaPods configuration"
echo "2. Run './patch_flutter_sentry.sh' to patch Flutter code (optional)"
echo "3. Build the app with 'flutter build ios --release'"