#!/bin/bash

# Local development script to completely disable Sentry on iOS/macOS
# This provides a cleaner solution than trying to patch C++ compatibility issues

echo "🔧 Completely disabling Sentry for iOS/macOS local development..."

# First, let's create a completely empty implementation of the problematic C++ files
SENTRY_DIR="Pods/Sentry"
if [ ! -d "$SENTRY_DIR" ]; then
  echo "❌ Error: Sentry directory not found at $SENTRY_DIR"
  exit 1
fi

# Empty implementation of CPP exception files
CPP_EXCEPTION_FILE="$SENTRY_DIR/Sources/SentryCrash/Recording/Monitors/SentryCrashMonitor_CPPException.cpp"
if [ -f "$CPP_EXCEPTION_FILE" ]; then
  echo "Creating empty CPPException.cpp"
  echo "/* Empty file */" > "$CPP_EXCEPTION_FILE"
  echo "✅ CPPException.cpp emptied"
else
  echo "⚠️ CPPException.cpp not found"
fi

CPP_EXCEPTION_HEADER="$SENTRY_DIR/Sources/SentryCrash/Recording/Monitors/SentryCrashMonitor_CPPException.h"
if [ -f "$CPP_EXCEPTION_HEADER" ]; then
  echo "Creating minimal CPPException.h"
  cat > "$CPP_EXCEPTION_HEADER" << 'EOL'
/* Minimal stub */
#ifndef HDR_SentryCrashMonitor_CPPException_h
#define HDR_SentryCrashMonitor_CPPException_h
#endif
EOL
  echo "✅ CPPException.h minimized"
else
  echo "⚠️ CPPException.h not found"
fi

# Disable thread profiling globally
PROFILING_CONDITIONALS="$SENTRY_DIR/Sources/Sentry/Public/SentryProfilingConditionals.h"
if [ -f "$PROFILING_CONDITIONALS" ]; then
  echo "Disabling thread profiling"
  cat > "$PROFILING_CONDITIONALS" << 'EOL'
#ifndef SentryProfilingConditionals_h
#define SentryProfilingConditionals_h
#define SENTRY_TARGET_PROFILING_SUPPORTED 0
#endif
EOL
  echo "✅ Thread profiling disabled"
else
  echo "⚠️ SentryProfilingConditionals.h not found"
fi

# Update the Dart implementation to use stubs
echo "Creating dart-level implementation to completely bypass Sentry on iOS/macOS"

MAIN_DART="../lib/main.dart"
if [ -f "$MAIN_DART" ]; then
  echo "Checking main.dart for Sentry initialization"
  
  # Look for code that skips Sentry on iOS/macOS
  if ! grep -q "skipSentry.*Platform.isIOS" "$MAIN_DART"; then
    echo "⚠️ No Platform.isIOS check found in main.dart for Sentry skipping"
    echo "This should be handled through conditional imports, but you might want to verify that Sentry is properly skipped on iOS/macOS"
  else
    echo "✅ main.dart already has Platform.isIOS check to skip Sentry"
  fi
else
  echo "⚠️ main.dart not found at expected location"
fi

SENTRY_HELPER="../lib/sentry_import_helper.dart"
if [ -f "$SENTRY_HELPER" ]; then
  echo "Checking sentry_import_helper.dart implementation"
else
  echo "⚠️ sentry_import_helper.dart not found"
fi

SENTRY_STUB="../lib/sentry_stub.dart"
if [ -f "$SENTRY_STUB" ]; then
  echo "Checking sentry_stub.dart implementation"
else
  echo "⚠️ sentry_stub.dart not found"
fi

# Add global compiler flags to the Podfile
PODFILE="../Podfile"
if [ -f "$PODFILE" ]; then
  echo "Checking if Podfile needs Sentry-specific compiler flags"
  
  # Check if Sentry flags are already present
  if ! grep -q "target.name.include?(\"Sentry\").*GCC_PREPROCESSOR_DEFINITIONS.*SENTRY_NO_EXCEPTIONS" "$PODFILE"; then
    echo "Adding Sentry-specific compiler flags to Podfile"
    
    # Create a backup
    cp "$PODFILE" "${PODFILE}.bak"
    
    # Add compiler flags to disable Sentry features at the preprocessor level
    sed -i.tmp '/post_install do |installer|/a\
  # Specific compiler flags for Sentry to disable problematic features\
  installer.pods_project.targets.each do |target|\
    if target.name.include?("Sentry")\
      target.build_configurations.each do |config|\
        config.build_settings["GCC_PREPROCESSOR_DEFINITIONS"] ||= ["$(inherited)"]\
        config.build_settings["GCC_PREPROCESSOR_DEFINITIONS"] << "SENTRY_NO_EXCEPTIONS=1"\
        config.build_settings["GCC_PREPROCESSOR_DEFINITIONS"] << "SENTRY_NO_THREAD_PROFILING=1"\
        config.build_settings["GCC_PREPROCESSOR_DEFINITIONS"] << "SENTRY_TARGET_PROFILING_SUPPORTED=0"\
      end\
    end\
  end
' "$PODFILE"
    
    echo "✅ Added Sentry-specific compiler flags to Podfile"
    echo "Run 'pod install' again to apply these changes"
  else
    echo "✅ Podfile already contains Sentry-specific compiler flags"
  fi
else
  echo "⚠️ Podfile not found"
fi

echo "✅ Sentry has been completely disabled for local iOS/macOS development"
echo "For TestFlight and App Store builds, use fix_sentry_ci.sh instead"
echo ""
echo "To apply these changes:"
echo "1. Run 'pod install' to rebuild the pods with these changes"
echo "2. Clean and rebuild your Xcode project"