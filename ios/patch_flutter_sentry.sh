#!/bin/bash

# Find all Dart files that import Sentry
find ../lib -name "*.dart" -type f -exec grep -l "import 'package:sentry" {} \; | while read -r file; do
  echo "Patching $file to use stub Sentry"
  # Replace Sentry import with local stub
  sed -i.sentrybak "s|import 'package:sentry|import '../sentry_stub.dart' // Disabled: import 'package:sentry|g" "$file"
done

echo "✅ Patched all Sentry imports to use stub implementation"
