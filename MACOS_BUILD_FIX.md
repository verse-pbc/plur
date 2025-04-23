# macOS Build Fix for Plur

This document explains how to successfully build the macOS version of Plur while resolving the cryptography_flutter architecture compatibility issues.

## The Problem

The macOS build fails with an architecture incompatibility error related to the `cryptography_flutter` package:

```
error: could not find module 'cryptography_flutter' for target 'x86_64-apple-macos'; found: arm64-apple-macos
```

This happens because:
1. The macOS build tries to compile for both ARM64 and x86_64 architectures
2. The `cryptography_flutter` package is only available for ARM64 architecture
3. Flutter's plugin registration system doesn't gracefully handle missing plugins

## Our Solution

After extensive testing, we've developed a comprehensive approach that resolves these issues:

1. **One-Click Fix**: Use the `build_macos.sh` script to automatically handle all fixes and build the app.

## Key Components of the Solution

Our solution addresses the issues through multiple complementary approaches:

1. **Architecture Configuration**:
   - Force ARM64-only architecture by modifying Podfile settings
   - Exclude x86_64 architecture from build configurations

2. **Plugin Management**:
   - Remove cryptography_flutter references from GeneratedPluginRegistrant.swift
   - Create a dummy implementation of the plugin to satisfy registration requirements
   - Fix permissions to ensure files can be modified

3. **Build Process Control**:
   - Use the `--no-tree-shake-icons` flag to prevent regeneration of plugin registrant files
   - Ensure proper backup of modified files in case of failure

4. **Dependency Management**:
   - Pin the cryptography_flutter package to a known working version (2.3.2)
   - Handle web plugin registrant compatibility

## How to Build macOS Version

### Method 1: Using the One-Click Script (Recommended)

```bash
./build_macos.sh
```

This script will:
1. Update package dependencies
2. Configure the Podfile for ARM64-only architecture
3. Create necessary dummy plugin implementations
4. Patch GeneratedPluginRegistrant.swift
5. Build the macOS app with appropriate flags

### Method 2: Manual Step-By-Step Approach

If you need more control, you can follow these steps manually:

1. **Clean your project**:
   ```bash
   flutter clean
   rm -rf macos/Pods macos/Podfile.lock macos/.symlinks
   ```

2. **Get dependencies**:
   ```bash
   flutter pub get
   ```

3. **Update Podfile** to force ARM64-only architecture:
   - Edit macos/Podfile
   - Add architecture configuration to exclude x86_64 (as shown in script)

4. **Install pods**:
   ```bash
   cd macos && pod install && cd ..
   ```

5. **Fix GeneratedPluginRegistrant.swift**:
   ```bash
   chmod +w macos/Flutter/GeneratedPluginRegistrant.swift
   sed -i '' '/import cryptography_flutter/d' macos/Flutter/GeneratedPluginRegistrant.swift
   sed -i '' '/CryptographyFlutterPlugin/d' macos/Flutter/GeneratedPluginRegistrant.swift
   ```

6. **Build macOS app**:
   ```bash
   flutter build macos --no-tree-shake-icons
   ```

## Troubleshooting

If you encounter issues:

1. **Build fails with regenerated files**: Run `build_macos.sh` script again

2. **Permission errors**: The script uses sudo for permission fixes
   ```bash
   sudo chown -R $(whoami) macos/Flutter
   ```

3. **Pod installation failures**: Clean pods and try again
   ```bash
   rm -rf macos/Pods macos/Podfile.lock
   cd macos && pod install && cd ..
   ```

4. **Incompatible plugin errors**: Check if plugin registration is still referring to cryptography_flutter

5. **The app crashes at runtime**: This may happen if the app actually needs cryptography functionality. Consider:
   - Implementing platform-specific code with conditional imports
   - Finding an alternative package that supports both architectures

## For Other Platforms

These fixes are macOS-specific and should not affect other platforms:
- **iOS**: Works normally with no special handling
- **Android**: Works normally with no special handling
- **Web**: Works with the custom web_plugin_registrant_custom.dart

## Long-term Solutions

For more permanent solutions, consider:

1. **Alternative packages**: Replace cryptography_flutter with a cross-platform alternative
2. **Conditional imports**: Use platform-specific code to avoid loading cryptography_flutter on macOS
3. **Package contribution**: Consider contributing architecture fixes to cryptography_flutter

## Maintenance Notes

This solution has been tested with Flutter 3.16 and above. When upgrading:
1. Check if newer versions of cryptography_flutter fix the architecture issues
2. Test macOS builds after any dependency upgrades
3. Update the build script if Flutter's build system changes

---

Last updated: April 2025