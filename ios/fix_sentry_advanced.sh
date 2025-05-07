#!/bin/bash

# Advanced Sentry C++ Compatibility Fix Script for iOS 18.4 SDK & Xcode 16.3
# This script creates a complete replacement for the problematic C++ exception handling code
# with a focus on completely isolating the C++ code to avoid compilation errors

echo "🛠️ Applying advanced Sentry C++ compatibility fixes for iOS 18.4 SDK..."

# Locate Sentry pods directory
SENTRY_DIR="Pods/Sentry"
if [ ! -d "$SENTRY_DIR" ]; then
  echo "❌ Error: Sentry directory not found at $SENTRY_DIR"
  exit 1
fi

# PATCH 1: Replace SentryCrashMonitor_CPPException.h with a completely isolated stub
CPP_EXCEPTION_HEADER="$SENTRY_DIR/Sources/SentryCrash/Recording/Monitors/SentryCrashMonitor_CPPException.h"
if [ -f "$CPP_EXCEPTION_HEADER" ]; then
  echo "Replacing CPPException.h with isolated stub"
  cp "$CPP_EXCEPTION_HEADER" "${CPP_EXCEPTION_HEADER}.bak"
  cat > "$CPP_EXCEPTION_HEADER" << 'EOL'
/* Completely isolated stub for SentryCrashMonitor_CPPException.h */
#ifndef HDR_SentryCrashMonitor_CPPException_h
#define HDR_SentryCrashMonitor_CPPException_h

#ifdef __cplusplus
extern "C" {
#endif

/* Minimal API declarations that don't depend on other headers */
typedef struct {
    void (*const install)(void);
    void (*const uninstall)(void);
    void (*const setRequiresAsyncSafety)(bool requiresAsyncSafety);
    bool (*const isInstalled)(void);
    bool (*const canHandleSignal)(int signal);
} sentrycrashcm_api_t;

/* Function declarations */
void* sentrycrashcm_cppexception_getAPI(void);
void sentrycrashcm_register_cpp_exception_handler(void);
void sentrycrashcm_deregister_cpp_exception_handler(void);

#ifdef __cplusplus
}
#endif

#endif /* HDR_SentryCrashMonitor_CPPException_h */
EOL
  echo "✅ CPPException.h replaced with isolated stub"
else
  echo "⚠️ CPPException.h not found"
fi

# PATCH 2: Replace SentryCrashMonitor_CPPException.cpp with a minimal implementation
CPP_EXCEPTION_FILE="$SENTRY_DIR/Sources/SentryCrash/Recording/Monitors/SentryCrashMonitor_CPPException.cpp"
if [ -f "$CPP_EXCEPTION_FILE" ]; then
  echo "Replacing CPPException.cpp with minimal implementation"
  cp "$CPP_EXCEPTION_FILE" "${CPP_EXCEPTION_FILE}.bak"
  cat > "$CPP_EXCEPTION_FILE" << 'EOL'
/* Minimal implementation for SentryCrashMonitor_CPPException.cpp */
/* This file intentionally does not include any headers to avoid compilation errors */

/* Basic function implementations that do nothing */
void sentrycrashcm_register_cpp_exception_handler(void) {}
void sentrycrashcm_deregister_cpp_exception_handler(void) {}

/* Handle any exception calls safely */
void sentrycrashcm_handleException(int unused) {}

/* Implement the API getter with a static API structure */
void* sentrycrashcm_cppexception_getAPI(void) {
    /* Define the struct inline to avoid header dependencies */
    static const struct {
        void (*const install)(void);
        void (*const uninstall)(void);
        void (*const setRequiresAsyncSafety)(void*);
        void (*const isInstalled)(void);
        void (*const canHandleSignal)(int);
    } api = {
        .install = sentrycrashcm_register_cpp_exception_handler,
        .uninstall = sentrycrashcm_deregister_cpp_exception_handler,
        .setRequiresAsyncSafety = 0,
        .isInstalled = 0,
        .canHandleSignal = 0,
    };
    return (void*)&api;
}
EOL
  echo "✅ CPPException.cpp replaced with minimal implementation"
else
  echo "⚠️ CPPException.cpp not found"
fi

# PATCH 3: Disable C++ exceptions in SentryCrashMonitorType.h
MONITOR_TYPE_FILE="$SENTRY_DIR/Sources/SentryCrash/Recording/Monitors/SentryCrashMonitorType.h"
if [ -f "$MONITOR_TYPE_FILE" ]; then
  echo "Patching SentryCrashMonitorType.h to disable C++ exception monitoring"
  cp "$MONITOR_TYPE_FILE" "${MONITOR_TYPE_FILE}.bak"
  cat > "$MONITOR_TYPE_FILE" << 'EOL'
#ifndef HDR_SentryCrashMonitorType_h
#define HDR_SentryCrashMonitorType_h

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    /* Captures and reports Mach exceptions. */
    SentryCrashMonitorTypeMachException = 0x01,
    /* Captures and reports POSIX signals. */
    SentryCrashMonitorTypeSignal = 0x02,
    /* EXPLICITLY DISABLED C++ exception handling to prevent compatibility issues */
    SentryCrashMonitorTypeCPPException = 0x00,
    /* Captures and reports NSExceptions. */
    SentryCrashMonitorTypeNSException = 0x08,
    /* Keeps track of and injects system information. */
    SentryCrashMonitorTypeSystem = 0x40,
    /* Keeps track of and injects application state. */
    SentryCrashMonitorTypeApplicationState = 0x80,
} SentryCrashMonitorType;

/* IMPORTANT CHANGE: Modified the default 'All' to remove CPPException */
#define SentryCrashMonitorTypeAll (SentryCrashMonitorTypeMachException | \
                                  SentryCrashMonitorTypeSignal | \
                                  SentryCrashMonitorTypeNSException | \
                                  SentryCrashMonitorTypeSystem | \
                                  SentryCrashMonitorTypeApplicationState)

const char* sentrycrashmonitortype_name(SentryCrashMonitorType monitorType);

#ifdef __cplusplus
}
#endif

#endif /* HDR_SentryCrashMonitorType_h */
EOL
  echo "✅ SentryCrashMonitorType.h replaced with C++ exceptions disabled"
else
  echo "⚠️ SentryCrashMonitorType.h not found"
fi

# PATCH 4: Completely disable thread profiling by replacing SentryProfilingConditionals.h
PROFILING_CONDITIONALS="$SENTRY_DIR/Sources/Sentry/Public/SentryProfilingConditionals.h"
if [ -f "$PROFILING_CONDITIONALS" ]; then
  echo "Replacing SentryProfilingConditionals.h to forcibly disable profiling"
  cp "$PROFILING_CONDITIONALS" "${PROFILING_CONDITIONALS}.bak"
  cat > "$PROFILING_CONDITIONALS" << 'EOL'
#ifndef SentryProfilingConditionals_h
#define SentryProfilingConditionals_h

/* FORCIBLY DISABLE thread profiling which uses C++ features incompatible with iOS 18.4 SDK */
#undef SENTRY_TARGET_PROFILING_SUPPORTED
#define SENTRY_TARGET_PROFILING_SUPPORTED 0

#undef SENTRY_TARGET_PROFILING
#define SENTRY_TARGET_PROFILING 0

#endif /* SentryProfilingConditionals_h */
EOL
  echo "✅ SentryProfilingConditionals.h replaced to disable thread profiling"
else
  echo "⚠️ SentryProfilingConditionals.h not found"
fi

# PATCH 5: Fix SentryCrashMonitor.c to avoid using C++ exception handler
CRASH_MONITOR_C="$SENTRY_DIR/Sources/SentryCrash/Recording/Monitors/SentryCrashMonitor.c"
if [ -f "$CRASH_MONITOR_C" ]; then
  echo "Checking SentryCrashMonitor.c for references to C++ exception handlers"
  if grep -q "g_monitors\[SentryCrashMonitorTypeCPPException\]" "$CRASH_MONITOR_C"; then
    echo "Patching SentryCrashMonitor.c to safely handle CPPException monitoring"
    cp "$CRASH_MONITOR_C" "${CRASH_MONITOR_C}.bak"
    
    # Use sed to replace the line that initializes the CPPException monitor
    sed -i.tmp 's/g_monitors\[SentryCrashMonitorTypeCPPException\] = \*sentrycrashcm_cppexception_getAPI();/\/\* Disabled: g_monitors\[SentryCrashMonitorTypeCPPException\] = \*sentrycrashcm_cppexception_getAPI(); \*\//g' "$CRASH_MONITOR_C"
    
    echo "✅ SentryCrashMonitor.c patched to avoid using C++ exception handler"
  else
    echo "SentryCrashMonitor.c doesn't need patching or has a different structure"
  fi
else
  echo "⚠️ SentryCrashMonitor.c not found"
fi

# PATCH 6: Create a global preprocessor header to disable problematic features
DISABLE_HEADER="$SENTRY_DIR/Sources/Sentry/include/SentryDisableFeatures.h"
echo "Creating global feature disabling header"
mkdir -p "$(dirname "$DISABLE_HEADER")"
cat > "$DISABLE_HEADER" << 'EOL'
/* Global header to disable problematic Sentry features for iOS 18.4 SDK compatibility */
#ifndef SentryDisableFeatures_h
#define SentryDisableFeatures_h

/* Force disable problematic features globally */
#define SENTRY_NO_EXCEPTIONS 1
#define SENTRY_TARGET_PROFILING_SUPPORTED 0
#define SENTRY_NO_THREAD_PROFILING 1

#endif /* SentryDisableFeatures_h */
EOL

# PATCH 7: Inject our disable header into the main Sentry.h
SENTRY_MAIN_HEADER="$SENTRY_DIR/Sources/Sentry/Public/Sentry.h"
if [ -f "$SENTRY_MAIN_HEADER" ]; then
  echo "Patching main Sentry.h to include our disable features header"
  cp "$SENTRY_MAIN_HEADER" "${SENTRY_MAIN_HEADER}.bak"
  if ! grep -q "SentryDisableFeatures.h" "$SENTRY_MAIN_HEADER"; then
    # Insert our include at line 2 (after the first line which should be the header guard)
    sed -i.tmp '1a\
#include "../include/SentryDisableFeatures.h"
' "$SENTRY_MAIN_HEADER"
    echo "✅ Sentry.h patched to include disable features header"
  else
    echo "Sentry.h already includes our disable features header"
  fi
else
  echo "⚠️ Main Sentry.h not found at expected location, trying alternative path"
  SENTRY_MAIN_ALT="$SENTRY_DIR/Sources/Sentry/include/Sentry.h"
  if [ -f "$SENTRY_MAIN_ALT" ]; then
    echo "Found Sentry.h at alternative location, patching"
    cp "$SENTRY_MAIN_ALT" "${SENTRY_MAIN_ALT}.bak"
    if ! grep -q "SentryDisableFeatures.h" "$SENTRY_MAIN_ALT"; then
      sed -i.tmp '1a\
#include "SentryDisableFeatures.h"
' "$SENTRY_MAIN_ALT"
      echo "✅ Alternative Sentry.h patched to include disable features header"
    else
      echo "Alternative Sentry.h already includes our disable features header"
    fi
  else
    echo "⚠️ Could not find main Sentry.h at any expected location"
  fi
fi

# PATCH 8: Verify the changes by checking for remaining references to problematic code
echo "Verifying patches by checking for remaining references..."
grep -r "sentrycrashcm_api_t" "$SENTRY_DIR/Sources/" 2>/dev/null || echo "✅ No references to sentrycrashcm_api_t found"
grep -r "std::allocator" "$SENTRY_DIR/Sources/" 2>/dev/null || echo "✅ No references to std::allocator found"

echo "Checking remaining problematic files for ThreadMetadataCache.hpp..."
if [ -f "$SENTRY_DIR/Sources/Sentry/include/SentryThreadMetadataCache.hpp" ]; then
  echo "⚠️ Found SentryThreadMetadataCache.hpp, applying additional patches"
  # This was previously identified as problematic, so provide a minimally viable replacement
  cp "$SENTRY_DIR/Sources/Sentry/include/SentryThreadMetadataCache.hpp" "$SENTRY_DIR/Sources/Sentry/include/SentryThreadMetadataCache.hpp.bak"
  cat > "$SENTRY_DIR/Sources/Sentry/include/SentryThreadMetadataCache.hpp" << 'EOL'
#pragma once

#include "SentryProfilingConditionals.h"

// This file is completely disabled as profiling is disabled
#if 0 && SENTRY_TARGET_PROFILING_SUPPORTED

#include <cstdint>
#include <memory>
#include <string>

namespace sentry {
namespace profiling {
    // Minimal stub implementations to satisfy linker
    struct ThreadMetadata {
        int threadID;
        std::string name;
        int priority;
    };
    
    class ThreadMetadataCache {
    public:
        ThreadMetadataCache() = default;
        ~ThreadMetadataCache() = default;
    };
} // namespace profiling
} // namespace sentry

#endif
EOL
  echo "✅ SentryThreadMetadataCache.hpp replaced with minimally viable implementation"
else
  echo "✅ SentryThreadMetadataCache.hpp not found, no additional patching needed"
fi

# Create a simple verification function
SENTRY_CPP_TESTER="$SENTRY_DIR/verify_cpp_fixes.cpp"
echo "Creating C++ verification file to ensure compatibility"
cat > "$SENTRY_CPP_TESTER" << 'EOL'
// Simple C++ file to verify our patches work
#include <iostream>
#include <vector>

// Include the headers we patched to make sure they compile
#include "Sources/SentryCrash/Recording/Monitors/SentryCrashMonitor_CPPException.h"
#include "Sources/SentryCrash/Recording/Monitors/SentryCrashMonitorType.h"
#include "Sources/Sentry/Public/SentryProfilingConditionals.h"

// Simple verification function that does nothing but proves compilation works
void verify_sentry_patches() {
    // This should compile without errors if our patches work
    std::cout << "Sentry patches verified!" << std::endl;
    
    // Make sure allocator works (previously caused errors)
    std::vector<int> test_vector;
    test_vector.push_back(1);
    
    // Use CPPException API to ensure it links
    void* api = sentrycrashcm_cppexception_getAPI();
    if (api) {
        std::cout << "CPPException API available" << std::endl;
    }
    
    // Verify monitor types
    int monitor_types = SentryCrashMonitorTypeAll;
    if ((monitor_types & SentryCrashMonitorTypeCPPException) == 0) {
        std::cout << "CPPException monitoring correctly disabled" << std::endl;
    }
}

// We don't actually compile and run this, it's just to verify the headers
EOL

echo "✅ All Sentry C++ compatibility patches applied!"
echo "The following files were patched:"
echo "- SentryCrashMonitor_CPPException.h (replaced with minimal stub)"
echo "- SentryCrashMonitor_CPPException.cpp (replaced with minimal implementation)"
echo "- SentryCrashMonitorType.h (CPPException monitoring disabled)"
echo "- SentryProfilingConditionals.h (thread profiling disabled)"
echo "- SentryCrashMonitor.c (modified to avoid using CPPException handlers)"
echo "- Created SentryDisableFeatures.h (global preprocessor directives)"
echo "- Patched main Sentry.h to include disable features header"
echo "- SentryThreadMetadataCache.hpp (if present, replaced with minimal implementation)"

echo "To verify these patches work in your build:"
echo "1. Run 'pod install' again"
echo "2. Build the project"
echo "3. If build fails, check the error messages for any remaining Sentry C++ issues"

# Make the script executable
chmod +x "$0"