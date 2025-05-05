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

# Fix CPPException.cpp with minimal C implementation
CPP_EXCEPTION_FILE="$SENTRY_DIR/Sources/SentryCrash/Recording/Monitors/SentryCrashMonitor_CPPException.cpp"
if [ -f "$CPP_EXCEPTION_FILE" ]; then
  echo "Creating minimal CPPException.cpp implementation"
  cat > "$CPP_EXCEPTION_FILE" << 'EOL'
#include <stdio.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    void (*install)(void);
    void (*uninstall)(void);
    void (*setRequiresAsyncSafety)(bool);
    bool (*isInstalled)(void);
    bool (*canHandleSignal)(int);
} sentrycrashcm_api_t;

void sentrycrashcm_register_cpp_exception_handler(void) {}
void sentrycrashcm_deregister_cpp_exception_handler(void) {}
void sentrycrashcm_handleException(bool isAsyncSafeEnvironment) {}

const sentrycrashcm_api_t* sentrycrashcm_cppexception_getAPI(void) {
    static sentrycrashcm_api_t api = {
        sentrycrashcm_register_cpp_exception_handler,
        sentrycrashcm_deregister_cpp_exception_handler,
        NULL,
        NULL,
        NULL
    };
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

echo "✅ Direct Sentry fixes applied for CI environment"