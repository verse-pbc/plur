# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Plur Dev Guide

## Build/Test Commands
- Setup: `flutter pub get`
- Run tests: `flutter test` or `flutter test test/path_to_specific_test.dart`
- Run single test: `flutter test --name="test name" test/path_to_test.dart`
- Lint: `flutter analyze`
- Auto fix: `dart fix --apply`
- Generate localizations: `flutter pub run intl_utils:generate`

## Android Build Instructions
- Setup environment:
  ```bash
  flutter clean
  flutter pub get
  ```
- For debug builds:
  ```bash
  flutter build apk --debug
  ```
- For release builds:
  ```bash
  # First update the key.properties file with actual passwords
  # in the android/key.properties file:
  # storePassword=actual_store_password
  # keyPassword=actual_key_password
  # keyAlias=plur
  # storeFile=app/key.jks

  # Then build the app bundle
  flutter build appbundle --release
  ```
- App bundle location: `build/app/outputs/bundle/release/app-release.aab`
- Debug APK location: `build/app/outputs/apk/debug/app-debug.apk`

### Android Build Troubleshooting
1. **Flutter Engine Dependencies**: If you encounter errors related to missing Flutter engine dependencies (like arm64_v8a_release), try:
   ```bash
   flutter clean
   (cd android && ./gradlew clean)
   flutter pub get
   flutter build apk
   ```
2. **Java Version**: The project is set up to use Java 17, but newer Android Studio versions may bundle Java 21. If you encounter Java compatibility issues, try adding these JVM args to `android/gradle.properties`:
   ```
   org.gradle.jvmargs=-Xmx1536M -Dkotlin.daemon.jvm.options="-Xmx1536M" --add-exports=java.base/sun.nio.ch=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-exports=jdk.unsupported/sun.misc=ALL-UNNAMED
   ```
3. **Gradle Version**: Make sure you're using Gradle 8.1.1 or later, which can be specified in `android/build.gradle`

## iOS Build Instructions
- Initialize rbenv: `eval "$(rbenv init -)"` (requires Ruby 3.2.2+)
- Clean Flutter: `flutter clean && flutter pub get`
- Install pods: `cd ios && pod install`
- For development builds: `flutter build ios --no-codesign` (only for local testing)
- **IMPORTANT: ALL RELEASE BUILDS MUST BE SIGNED**

### Release Build and TestFlight Distribution
The app requires Associated Domains capability which complicates automated builds. The recommended approach for TestFlight distribution is:

#### Method 1: Using Xcode (Recommended)
1. Build a release version of the app:
   ```bash
   flutter build ios --release
   ```

2. Archive the app in Xcode:
   ```bash
   cd ios
   xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -destination 'generic/platform=iOS' -archivePath "$(pwd)/build/Runner.xcarchive" archive
   ```

3. Open Xcode and distribute manually:
   - Open Xcode
   - Go to Window > Organizer
   - Select the archive at `/Users/rabble/code/verse/plur/ios/build/Runner.xcarchive`
   - Click "Distribute App"
   - Select "App Store Connect"
   - Choose "Automatically manage signing" when prompted
   - Complete the upload process

#### Method 2: Using Fastlane (Requires Associated Domains Profile)
1. Ensure certificates and profiles are properly set up:
   ```bash
   bundle exec fastlane match repair
   ```

2. Deploy to TestFlight using fastlane:
   ```bash
   bundle exec fastlane ios release
   ```

#### Important Notes About Certificates
- The Apple Distribution certificate (ID: EDAC61F4388139A236294D33CB2F128D8B64D95D) must be used for release builds
- Never use `--no-codesign` for release builds
- The iOS Distribution certificate is stored in the private GitHub repository: `git@github.com:verse-pbc/fastlane_certs.git`
- The provisioning profile MUST include the Associated Domains capability for the app to work properly

### iOS Build Troubleshooting
If iOS build fails, check the following common issues:
1. **Deployment target issues**: The Podfile enforces iOS 15.5 minimum deployment target
2. **Ruby/CocoaPods version**: Use rbenv with Ruby 3.2.2+ and CocoaPods 1.12+
3. **Missing localization files**: If errors about missing messages_*.dart files appear, check lib/generated/intl/messages_all.dart
4. **Xcode configuration**: Make sure xcconfig files include the proper CocoaPods configurations
5. **Sentry**: Sentry has been completely removed from this project to avoid C++ compatibility issues with newer iOS SDK versions
6. **Code Signing**: If code signing fails for release builds, run `bundle exec fastlane match appstore --readonly` to install the certificates
7. **Associated Domains**: If you get provisioning profile errors related to Associated Domains, use Xcode manually to create a profile with the correct entitlements

See `ios/FIX_IOS_BUILD.md` for detailed iOS build troubleshooting steps.

## Communication Guidelines
- When planning changes, provide detailed explanations of:
  - Which files you'll modify and why
  - What specific problems you'll address in each file
  - How your proposed changes solve these problems
  - Any potential side effects or considerations
- Before implementing, outline your approach with architectural considerations
- When making multiple related changes, explain how they work together
- Provide context about the surrounding code ecosystem when relevant
- Explain performance implications of changes you propose
- For complex changes, provide a step-by-step breakdown of the implementation

## Code Change Explanations
For each file you plan to modify, explain:

1. **Current Implementation Analysis**: 
   - What the current code does
   - Identify specific issues, inefficiencies, or bugs
   - Highlight patterns that need improvement

2. **Proposed Changes**: 
   - Detailed description of what you'll change
   - Line-by-line explanations for complex modifications
   - How the changes address the identified issues

3. **Implementation Strategy**:
   - Order of changes if there are dependencies
   - Any refactoring needed before main changes
   - Consideration of different approaches and why one was chosen

4. **Expected Impact**:
   - How the changes will improve functionality
   - Performance implications (positive or negative)
   - How users will experience the difference

5. **Testing Considerations**:
   - How to verify the changes work as expected
   - Edge cases to consider
   - Potential regressions to watch for

## Important Process Rules
- ALWAYS run `flutter analyze` before completing any task to ensure there are no compiler errors, warnings, or lint issues
- ALWAYS verify that code compiles and passes static analysis checks before considering a task complete
- After making code changes, run `flutter analyze` to check for syntax and type errors - this is mandatory for every change
- After significant changes, run the relevant tests to ensure nothing broke
- When working on a complex feature, test each part as you implement it
- When fixing one issue, verify you don't introduce new ones by running the analyzer
- Ensure UI transitions are smooth and don't cause performance issues
- Profile the application when making performance-related changes
- When running bash commands, never use `cd ..` or attempt to navigate to parent directories as this is blocked by Claude Code security measures - use subshells or absolute paths instead

## Code Style Guidelines
- Follow Flutter's standard linting rules (package:flutter_lints/flutter.yaml)
- Use Dart's static typing system for all variables, parameters, and return values
- Widget classes should be stateless unless state is required
- Import order: dart:*, package:flutter/*, other packages, relative imports
- Use named parameters for all widget constructors with required annotation
- Document public APIs with /// comments (especially parameters and return values)
- Prefer const constructors when possible
- Use camelCase for variables/methods, PascalCase for classes
- Error handling: use try/catch for recoverable errors
- Create reusable components in the lib/component directory
- Follow provider pattern for state management
- Ensure all UI strings use the localization system (S.of(context).your_string_key)

## Performance Best Practices

### General
- Use caching for expensive operations
- Implement lazy loading for data that isn't immediately needed
- Avoid blocking the main thread with synchronous operations
- Batch updates to minimize rebuilds
- Profile UI performance and fix jank
- Use `const` constructors whenever possible
- Limit setState() calls - batch multiple changes into a single setState
- Keep build methods lightweight - extract complex logic to methods
- Use Future.microtask() or Future.delayed(Duration.zero) to defer heavy work

### UI Rendering
- Add proper widget lifecycle management with AutomaticKeepAliveClientMixin where appropriate
- Use RepaintBoundary to isolate painting operations for complex widgets
- Throttle UI updates during animations
- Employ Stack + Offstage instead of IndexedStack for efficient tab switching
- Add proper loading indicators during expensive operations

### ListView Performance
- Use `ListView.builder()` for dynamic lists
- Add appropriate keys to list items to ensure proper recycling
- Implement paging/virtualization for long lists
- Set `addAutomaticKeepAlives: false` when list items don't need to maintain state
- Use `itemExtent` for fixed-height items for better performance
- Use appropriate cacheExtent values for smooth scrolling
- Implement widget recycling for long lists

### State Management
- Keep state as local as possible
- Use Provider efficiently - minimize rebuilding with Selector or Consumer
- Implement `shouldRebuild` in custom Selector builders
- Avoid expensive computations in build methods
- Cache results of expensive operations
- Create and cache widgets instead of rebuilding them
- Use proper key usage for widget identity preservation

### Image Handling
- Specify dimensions when loading images
- Use appropriate caching mechanisms
- Implement progressive loading with placeholders
- Consider using `precacheImage` for critical images
- Optimize image assets for size/quality balance
- Add RepaintBoundary around image widgets

### Encryption/Decryption Operations
- Move encryption/decryption off the main thread
- Implement multi-level caching strategies (memory, database)
- Batch decrypt operations rather than one-by-one
- Show appropriate loading indicators during heavy operations
- Prioritize decryption of visible content
- Use queues to limit parallel decryption operations

### Background Processing
- Use proper background tasks to avoid UI blocking
- Properly cancel timers and streams when not needed
- Use memory efficiently with proper caching strategies
- When tab is not visible, pause expensive operations
- Implement periodic refresh in the background for critical data