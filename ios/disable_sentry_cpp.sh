#!/bin/bash

# Create an empty implementation of problematic Sentry C++ headers
PODS_DIR="/Users/sebastian/projects/plur/ios/Pods"
EMPTY_DIR="$PODS_DIR/Sentry/Sources/Empty"

mkdir -p "$EMPTY_DIR"

# Create an empty ThreadMetadataCache.h implementation
cat > "$EMPTY_DIR/ThreadMetadataCache.h" << EOF
#ifndef SentryThreadMetadataCache_h
#define SentryThreadMetadataCache_h

namespace sentry {
namespace profiling {

class ThreadMetadataCache {
public:
    struct ThreadHandleMetadataPair {
        int dummy;
    };
};

} // namespace profiling
} // namespace sentry

#endif /* SentryThreadMetadataCache_h */
EOF

# Add include path to Sentry C++ build settings
SENTRY_XCCONFIG="$PODS_DIR/Target Support Files/Sentry/Sentry.debug.xcconfig"
if [ -f "$SENTRY_XCCONFIG" ]; then
    echo 'HEADER_SEARCH_PATHS = $(inherited) "${PODS_ROOT}/Sentry/Sources/Empty"' >> "$SENTRY_XCCONFIG"
    echo 'GCC_PREPROCESSOR_DEFINITIONS = $(inherited) SENTRY_DISABLED=1' >> "$SENTRY_XCCONFIG"
fi

SENTRY_XCCONFIG="$PODS_DIR/Target Support Files/Sentry/Sentry.release.xcconfig"
if [ -f "$SENTRY_XCCONFIG" ]; then
    echo 'HEADER_SEARCH_PATHS = $(inherited) "${PODS_ROOT}/Sentry/Sources/Empty"' >> "$SENTRY_XCCONFIG"
    echo 'GCC_PREPROCESSOR_DEFINITIONS = $(inherited) SENTRY_DISABLED=1' >> "$SENTRY_XCCONFIG"
fi

# Update all Sentry C++ source files to add the SENTRY_DISABLED guard
find "$PODS_DIR/Sentry/Sources" -type f -name "*.cpp" -o -name "*.mm" | while read -r file; do
    if ! grep -q "SENTRY_DISABLED" "$file"; then
        sed -i '' '1s/^/#if !defined(SENTRY_DISABLED)\n/' "$file"
        echo "#endif // !defined(SENTRY_DISABLED)" >> "$file"
    fi
done

echo "Sentry C++ code has been disabled!"