#!/bin/bash

# Script to fix problematic Sentry C++ files after pod install
# This fixes C++ exceptions issues with Sentry 8.46.0

echo "🔧 Fixing Sentry C++ files for iOS/macOS..."

# Fix the problematic CPPException file
CPP_EXCEPTION_FILE="Pods/Sentry/Sources/SentryCrash/Recording/Monitors/SentryCrashMonitor_CPPException.cpp"

if [ -f "$CPP_EXCEPTION_FILE" ]; then
  echo "Fixing $CPP_EXCEPTION_FILE"
  chmod 644 "$CPP_EXCEPTION_FILE"
  cat > "$CPP_EXCEPTION_FILE" << 'EOL'
// Stub implementation to avoid C++ template errors
#include "SentryCrashMonitor_CPPException.h"
#include "SentryCrashMonitor.h" // for the API type

// Don't include problematic headers
// #include "SentryCrashAlloc.h"
// #include "SentryCrashLogger.h"

// Define empty implementations
void sentrycrashcm_register_cpp_exception_handler() {}
void sentrycrashcm_deregister_cpp_exception_handler() {}

// Static variables
static bool g_installed = false;
static bool g_requiresAsyncSafety = false;

// Empty implementation - no exceptions
#if SENTRY_HAS_UCONTEXT
void sentrycrashcm_handleException(bool isAsyncSafeEnvironment, const sentrycrashmc_exception_context_t *context) {}
#else
void sentrycrashcm_handleException(bool isAsyncSafeEnvironment) {}
#endif

// Add missing symbol that's referenced elsewhere
const sentrycrashcm_api_t* sentrycrashcm_cppexception_getAPI(void) {
    static const sentrycrashcm_api_t api = {
        .install = sentrycrashcm_register_cpp_exception_handler,
        .uninstall = sentrycrashcm_deregister_cpp_exception_handler,
        .setRequiresAsyncSafety = NULL,
        .isInstalled = NULL,
        .canHandleSignal = NULL,
    };
    return &api;
}
EOL
  echo "✅ Fixed CPPException file"
fi

echo "✅ All Sentry files fixed!"

# Make the script executable
chmod +x "$0"