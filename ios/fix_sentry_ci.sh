#!/bin/bash

# Direct fix script for Sentry in CI environments
# This script is specifically designed to fix C++ compatibility issues in CI builds

echo "🔧 Applying direct CI Sentry fix..."

# Locate Sentry pods
SENTRY_DIR="Pods/Sentry"
if [ ! -d "$SENTRY_DIR" ]; then
  echo "Error: Sentry directory not found at $SENTRY_DIR"
  exit 1
fi

# Replace CPPException.h with a stub that doesn't include any other headers
CPP_EXCEPTION_HEADER="$SENTRY_DIR/Sources/SentryCrash/Recording/Monitors/SentryCrashMonitor_CPPException.h"
if [ -f "$CPP_EXCEPTION_HEADER" ]; then
  echo "Replacing CPPException.h with a stub that has no dependencies"
  cat > "$CPP_EXCEPTION_HEADER" << 'EOL'
/* Stub for SentryCrashMonitor_CPPException.h with no dependencies */
#ifndef HDR_SentryCrashMonitor_CPPException_h
#define HDR_SentryCrashMonitor_CPPException_h

/* We avoid including any other headers */
#ifdef __cplusplus
extern "C" {
#endif

/* Empty API function declarations */
void* sentrycrashcm_cppexception_getAPI(void);
void sentrycrashcm_register_cpp_exception_handler(void);
void sentrycrashcm_deregister_cpp_exception_handler(void);

#ifdef __cplusplus
}
#endif

#endif /* HDR_SentryCrashMonitor_CPPException_h */
EOL
  echo "✅ CPPException.h replaced with stub"
else
  echo "⚠️ CPPException.h not found"
fi

# Create a special header to completely disable CPP exception monitoring
DISABLE_CPP_HEADER="$SENTRY_DIR/Sources/SentryCrash/Recording/Monitors/SentryCrashMonitor_CPPException_Disable.h"
echo "Creating special header to disable CPP exception monitoring"
cat > "$DISABLE_CPP_HEADER" << 'EOL'
#ifndef HDR_SentryCrashMonitor_CPPException_Disable_h
#define HDR_SentryCrashMonitor_CPPException_Disable_h

// This header completely disables C++ exception monitoring in Sentry
// to avoid C++ compatibility issues in iOS 18.4 SDK with Xcode 16.3

// Force disable C++ exception monitoring
#undef SentryCrashMonitorTypeCPPException
#define SentryCrashMonitorTypeCPPException 0

#endif /* HDR_SentryCrashMonitor_CPPException_Disable_h */
EOL

# Completely replace CPPException.cpp with an extremely minimal stub
CPP_EXCEPTION_FILE="$SENTRY_DIR/Sources/SentryCrash/Recording/Monitors/SentryCrashMonitor_CPPException.cpp"
if [ -f "$CPP_EXCEPTION_FILE" ]; then
  echo "Creating minimal CPPException.cpp stub without any header dependencies"
  cat > "$CPP_EXCEPTION_FILE" << 'EOL'
/* Empty stub for SentryCrashMonitor_CPPException.cpp */
/* We avoid including any headers at all to prevent compilation issues */

/* Define necessary symbols */
void* sentrycrashcm_cppexception_getAPI(void) { return 0; }
void sentrycrashcm_register_cpp_exception_handler(void) {}
void sentrycrashcm_deregister_cpp_exception_handler(void) {}
void sentrycrashcm_handleException(int unused) {}
EOL
  echo "✅ CPPException.cpp replaced with minimal stub"
else
  echo "⚠️ CPPException.cpp not found"
fi

# Also patch SentryCrashMonitorType.h to include our disable header
MONITOR_TYPE_FILE="$SENTRY_DIR/Sources/SentryCrash/Recording/Monitors/SentryCrashMonitorType.h"
if [ -f "$MONITOR_TYPE_FILE" ]; then
  echo "Patching SentryCrashMonitorType.h to disable C++ exception monitoring"
  
  # Make a backup
  cp "$MONITOR_TYPE_FILE" "${MONITOR_TYPE_FILE}.bak"
  
  # Insert our include at the beginning
  sed -i.tmp '/#ifndef HDR_SentryCrashMonitorType_h/a\
#include "SentryCrashMonitor_CPPException_Disable.h"
' "$MONITOR_TYPE_FILE"
  
  echo "✅ SentryCrashMonitorType.h patched"
else
  echo "⚠️ SentryCrashMonitorType.h not found"
fi

# Disable thread profiling by modifying SentryProfilingConditionals.h
PROFILING_CONDITIONALS="$SENTRY_DIR/Sources/Sentry/Public/SentryProfilingConditionals.h"
if [ -f "$PROFILING_CONDITIONALS" ]; then
  echo "Modifying profiling conditionals to disable thread profiling"
  cat > "$PROFILING_CONDITIONALS" << 'EOL'
#ifndef SentryProfilingConditionals_h
#define SentryProfilingConditionals_h

// Forcibly disable profiling to avoid C++ compatibility issues
#define SENTRY_TARGET_PROFILING_SUPPORTED 0

#endif /* SentryProfilingConditionals_h */
EOL
  echo "✅ SentryProfilingConditionals.h fixed"
else
  echo "⚠️ SentryProfilingConditionals.h not found"
fi

# Patch ThreadMetadataCache.hpp to remove const issues
THREAD_METADATA_CACHE_HPP="$SENTRY_DIR/Sources/Sentry/include/SentryThreadMetadataCache.hpp"
if [ -f "$THREAD_METADATA_CACHE_HPP" ]; then
  echo "Checking if ThreadMetadataCache.hpp needs patching"
  
  # Make a backup
  cp "$THREAD_METADATA_CACHE_HPP" "${THREAD_METADATA_CACHE_HPP}.bak"
  
  # Replace 'const ThreadHandleMetadataPair' with 'ThreadHandleMetadataPair'
  sed -i.tmp 's/const ThreadHandleMetadataPair/ThreadHandleMetadataPair/g' "$THREAD_METADATA_CACHE_HPP"
  echo "✅ ThreadMetadataCache.hpp fixed"
else
  echo "⚠️ ThreadMetadataCache.hpp not found"
fi

# Create a unified patcher to ensure proper C++ setup
CPP_PATCH_HEADER="$SENTRY_DIR/Sources/Sentry/include/SentryCppCompat.h"
echo "Creating C++ compatibility header"
cat > "$CPP_PATCH_HEADER" << 'EOL'
#ifndef HDR_SentryCppCompat_h
#define HDR_SentryCppCompat_h

// This header ensures C++ compatibility with iOS 18.4 SDK and C++17

// Force disable thread profiling
#define SENTRY_TARGET_PROFILING_SUPPORTED 0

// Force disable C++ exceptions
#define SENTRY_NO_CPP_EXCEPTIONS 1

#endif /* HDR_SentryCppCompat_h */
EOL

# Add our compat header to Sentry.h
SENTRY_MAIN_HEADER="$SENTRY_DIR/Sources/Sentry/include/Sentry.h"
if [ -f "$SENTRY_MAIN_HEADER" ]; then
  echo "Patching main Sentry header with compatibility header"
  # Make a backup
  cp "$SENTRY_MAIN_HEADER" "${SENTRY_MAIN_HEADER}.bak"
  
  # Insert our include at the beginning if it's not already there
  if ! grep -q "SentryCppCompat.h" "$SENTRY_MAIN_HEADER"; then
    sed -i.tmp '1i\
#include "SentryCppCompat.h"
' "$SENTRY_MAIN_HEADER"
  fi
  echo "✅ Sentry.h patched"
else
  echo "⚠️ Sentry.h not found"
fi

# Another approach: Modify the Podfile to add compiler flags for all targets
PODFILE="../Podfile"
if [ -f "$PODFILE" ]; then
  echo "Checking if Podfile needs additional compiler flags"
  
  # Use grep to check if our flags are already present
  if ! grep -q "GCC_PREPROCESSOR_DEFINITIONS.*SENTRY_NO_EXCEPTIONS" "$PODFILE"; then
    echo "Adding global Sentry compiler flags to Podfile"
    
    # Create a temporary file
    TEMP_FILE=$(mktemp)
    
    # Use awk to find the right spot and insert our code
    awk '
    /post_install do \|installer\|/ {
      print $0
      print "  # Global compiler flags to disable problematic Sentry features"
      print "  installer.pods_project.targets.each do |target|"
      print "    target.build_configurations.each do |config|"
      print "      config.build_settings[\"GCC_PREPROCESSOR_DEFINITIONS\"] ||= [\"$(inherited)\"]"
      print "      config.build_settings[\"GCC_PREPROCESSOR_DEFINITIONS\"] << \"SENTRY_NO_EXCEPTIONS=1\""
      print "      config.build_settings[\"GCC_PREPROCESSOR_DEFINITIONS\"] << \"SENTRY_NO_THREAD_PROFILING=1\""
      print "      config.build_settings[\"GCC_PREPROCESSOR_DEFINITIONS\"] << \"SENTRY_TARGET_PROFILING_SUPPORTED=0\""
      print "    end"
      print "  end"
      next
    }
    { print }
    ' "$PODFILE" > "$TEMP_FILE"
    
    # Replace the original file
    mv "$TEMP_FILE" "$PODFILE"
    
    echo "✅ Added global compiler flags to Podfile"
  else
    echo "Sentry compiler flags already present in Podfile"
  fi
else
  echo "⚠️ Podfile not found"
fi

echo "✅ Comprehensive Sentry fixes applied for CI environment"