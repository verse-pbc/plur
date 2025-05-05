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

# Fix CPPException.cpp with a properly implemented file that includes the right headers
CPP_EXCEPTION_FILE="$SENTRY_DIR/Sources/SentryCrash/Recording/Monitors/SentryCrashMonitor_CPPException.cpp"
if [ -f "$CPP_EXCEPTION_FILE" ]; then
  echo "Creating proper CPPException.cpp implementation"
  cat > "$CPP_EXCEPTION_FILE" << 'EOL'
// Fixed implementation to work with iOS 18.4 SDK and C++17
#include "SentryCrashMonitor_CPPException.h"
#include "SentryCrashMonitor.h"
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// The API structure matching the expected type in SentryCrashMonitor.h
static SentryCrashMonitorAPI api = {
    .setEnabled = NULL,
    .isEnabled = NULL,
    .addContextualInfoToEvent = NULL
};

void sentrycrashcm_register_cpp_exception_handler(void) {
    // Empty implementation
}

void sentrycrashcm_deregister_cpp_exception_handler(void) {
    // Empty implementation
}

void sentrycrashcm_handleException(bool isAsyncSafeEnvironment) {
    // Empty implementation
}

SentryCrashMonitorAPI* sentrycrashcm_cppexception_getAPI(void) {
    return &api;
}

#ifdef __cplusplus
}
#endif
EOL
  echo "✅ CPPException.cpp fixed"
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

echo "✅ Comprehensive Sentry fixes applied for CI environment"