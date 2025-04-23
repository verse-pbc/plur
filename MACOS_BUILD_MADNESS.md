# Flutter macOS Build Madness - The Cryptography Flutter Saga

This document summarizes the hours of debugging and troubleshooting required to get the macOS build working for the Plur app.

## The Problem

When attempting to build the macOS version of our Flutter app, we encountered persistent failures related to the `cryptography_flutter` package and architecture incompatibilities between ARM64 and x86_64 architectures.

The primary error:
```
error: could not find module 'cryptography_flutter' for target 'x86_64-apple-macos'; found: arm64-apple-macos
```

## Attempted Solutions

### Approach 1: Pinning Package Version

We initially tried pinning `cryptography_flutter` to a specific version using dependency overrides:

```yaml
dependency_overrides:
  cryptography_flutter: 2.3.2
```

**Result**: Still failed with architecture incompatibility errors.

### Approach 2: Modifying Podfile for ARM64-only

We attempted to force ARM64 architecture by modifying the Podfile:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ARCHS'] = 'arm64'
      config.build_settings['EXCLUDED_ARCHS[sdk=macosx*]'] = 'x86_64'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
    end
  end
end
```

**Result**: Still encountered architecture errors. Flutter kept regenerating plugin registration files.

### Approach 3: Manually Modifying GeneratedPluginRegistrant.swift

We tried manually removing `cryptography_flutter` references from `GeneratedPluginRegistrant.swift`:

```bash
sed -i '' '/import cryptography_flutter/d' macos/Flutter/GeneratedPluginRegistrant.swift
sed -i '' '/CryptographyFlutterPlugin/d' macos/Flutter/GeneratedPluginRegistrant.swift
```

**Result**: Failed because Flutter would regenerate the file during the build process.

### Approach 4: Creating a Custom Plugin Registrant File

We attempted to create a completely new `GeneratedPluginRegistrant.swift` without `cryptography_flutter` references:

```swift
// Custom file without cryptography_flutter
```

**Result**: Failed as Flutter would either regenerate the file or couldn't find other plugin modules.

### Approach 5: Modifying Podfile to Exclude `cryptography_flutter` 

We tried to exclude `cryptography_flutter` from CocoaPods installation:

```ruby
target 'Runner' do
  # Loop through all plugins except cryptography_flutter
  all_plugins = Dir.glob(File.join('.symlinks', 'plugins', '*', 'macos'))
  all_plugins.each do |plugin_path|
    plugin_name = File.basename(File.dirname(plugin_path))
    next if plugin_name == 'cryptography_flutter'
    # ...
  end
end
```

**Result**: CocoaPods would still try to access the plugin at some point.

### Approach 6: Post-Build Fix Script

We created a script to modify the files after Flutter generates them but before the build completes:

```bash
#!/bin/bash
chmod +w macos/Flutter/GeneratedPluginRegistrant.swift
sed -i '' '/import cryptography_flutter/d' macos/Flutter/GeneratedPluginRegistrant.swift
sed -i '' '/CryptographyFlutterPlugin/d' macos/Flutter/GeneratedPluginRegistrant.swift
chmod -w macos/Flutter/GeneratedPluginRegistrant.swift
```

**Result**: Build would still fail when trying to access the removed module.

## Root Causes Identified

1. **Architecture Incompatibility**: `cryptography_flutter` had issues with ARM64/x86_64 dual-architecture compilation on macOS.

2. **Plugin Registration System**: Flutter's plugin registration mechanism doesn't gracefully handle missing plugins.

3. **Build Process Interference**: Flutter regenerates files during the build process, overriding our manual changes.

4. **CocoaPods Limitations**: CocoaPods didn't provide clean ways to exclude specific plugins without breaking the rest.

## Final Working Solution

Our final approach involved a multi-step process:

1. Remove `cryptography_flutter` references from `pubspec.yaml`
2. Create a custom `GeneratedPluginRegistrant.swift` without any `cryptography_flutter` references
3. Make the file read-only to prevent Flutter from overwriting it
4. Configure the Podfile to force ARM64-only architecture
5. Create a build wrapper script to apply fixes before every build

```bash
#!/bin/bash
# Fix GeneratedPluginRegistrant.swift
chmod +w macos/Flutter/GeneratedPluginRegistrant.swift
sed -i '' '/import cryptography_flutter/d' macos/Flutter/GeneratedPluginRegistrant.swift
sed -i '' '/CryptographyFlutterPlugin/d' macos/Flutter/GeneratedPluginRegistrant.swift
chmod -w macos/Flutter/GeneratedPluginRegistrant.swift

# Build with specific flags
flutter build macos --debug --no-tree-shake-icons
```

## Lessons Learned

1. Flutter's plugin system isn't designed to selectively exclude plugins on a per-platform basis.

2. Architecture compatibility issues are particularly problematic on macOS with Apple Silicon.

3. Flutter's build process regenerates files in ways that can interfere with manual modifications.

4. CocoaPods integration with Flutter is complex and sometimes brittle.

5. When a package worked before but suddenly doesn't, check if dependency versions have changed.

## Going Forward

For future projects, we should:

1. Consider the macOS architecture compatibility of packages before including them.

2. Test macOS builds regularly to catch these issues early.

3. Maintain a dedicated build script that applies necessary fixes automatically.

4. Consider a more permanent solution by either contributing a fix to `cryptography_flutter` or replacing it with a more macOS-compatible alternative.