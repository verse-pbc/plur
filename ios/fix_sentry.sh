#!/bin/bash

# Script to fix problematic Sentry C++ files after pod install
# This fixes C++ exceptions and thread profiling issues with Sentry 8.46.0

echo "🔧 Fixing Sentry C++ files for iOS/macOS..."

# Create a header to disable thread profiling globally
PROFILING_DISABLE_HEADER="Pods/Sentry/Sources/Sentry/include/SentryDisableThreadProfiling.h"
echo "Creating global thread profiling disable header"
mkdir -p "$(dirname "$PROFILING_DISABLE_HEADER")"
cat > "$PROFILING_DISABLE_HEADER" << 'EOL'
// This header disables thread profiling in Sentry to avoid C++17 compatibility issues
#ifndef SentryDisableThreadProfiling_h
#define SentryDisableThreadProfiling_h

// Force disable thread profiling regardless of platform
#undef SENTRY_TARGET_PROFILING_SUPPORTED
#define SENTRY_TARGET_PROFILING_SUPPORTED 0

#endif /* SentryDisableThreadProfiling_h */
EOL

# Modify the main Sentry header to include our disable header
SENTRY_MAIN_HEADER="Pods/Sentry/Sources/Sentry/include/Sentry.h"
if [ -f "$SENTRY_MAIN_HEADER" ]; then
  echo "Patching main Sentry header to include thread profiling disable header"
  if ! grep -q "SentryDisableThreadProfiling.h" "$SENTRY_MAIN_HEADER"; then
    sed -i.bak '1i\
#include "SentryDisableThreadProfiling.h"
' "$SENTRY_MAIN_HEADER"
  fi
fi

# Also patch the profiling conditionals header directly
PROFILING_CONDITIONALS="Pods/Sentry/Sources/Sentry/Public/SentryProfilingConditionals.h"
if [ -f "$PROFILING_CONDITIONALS" ]; then
  echo "Patching SentryProfilingConditionals.h to force disable profiling"
  cp "$PROFILING_CONDITIONALS" "${PROFILING_CONDITIONALS}.bak"
  cat > "$PROFILING_CONDITIONALS" << 'EOL'
#ifndef SentryProfilingConditionals_h
#define SentryProfilingConditionals_h

// Force disable profiling for all platforms to avoid C++17 compatibility issues
#define SENTRY_TARGET_PROFILING_SUPPORTED 0

#endif /* SentryProfilingConditionals_h */
EOL
fi

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

# Create empty stub implementation for ThreadMetadataCache to avoid C++ issues
THREAD_METADATA_CACHE_CPP="Pods/Sentry/Sources/Sentry/SentryThreadMetadataCache.cpp"
if [ -f "$THREAD_METADATA_CACHE_CPP" ]; then
  echo "Creating stub implementation for ThreadMetadataCache.cpp"
  chmod 644 "$THREAD_METADATA_CACHE_CPP"
  cat > "$THREAD_METADATA_CACHE_CPP" << 'EOL'
// Stub implementation, thread profiling is disabled
#include "SentryProfilingConditionals.h"

#if SENTRY_TARGET_PROFILING_SUPPORTED
#include "SentryThreadMetadataCache.hpp"

namespace sentry {
namespace profiling {

ThreadMetadata ThreadMetadataCache::metadataForThread(const ThreadHandle &thread)
{
    // Return empty metadata
    ThreadMetadata metadata = {};
    return metadata;
}

} // namespace profiling
} // namespace sentry
#endif
EOL
fi

# Create a simplified stub for ThreadHandle.cpp as well
THREAD_HANDLE_CPP="Pods/Sentry/Sources/Sentry/SentryThreadHandle.cpp"
if [ -f "$THREAD_HANDLE_CPP" ]; then
  echo "Creating stub implementation for ThreadHandle.cpp"
  chmod 644 "$THREAD_HANDLE_CPP"
  cat > "$THREAD_HANDLE_CPP" << 'EOL'
// Stub implementation, thread profiling is disabled
#include "SentryProfilingConditionals.h"

#if SENTRY_TARGET_PROFILING_SUPPORTED
#include "SentryThreadHandle.hpp"

namespace sentry {
namespace profiling {
namespace thread {

// Empty implementations to satisfy linker
ThreadHandle::ThreadHandle() {}
ThreadHandle::ThreadHandle(NativeHandle handle) {}
ThreadHandle::~ThreadHandle() = default;

// Stub implementation
TIDType threadID(const ThreadHandle &) { return 0; }

} // namespace thread
} // namespace profiling
} // namespace sentry
#endif
EOL
fi

echo "✅ All Sentry files fixed!"

# Make the script executable
chmod +x "$0"