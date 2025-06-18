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

## Internationalization Setup
The app supports 26 languages with proper native locale configuration:
- **iOS**: `CFBundleLocalizations` array in `ios/Runner/Info.plist` declares all supported languages
- **Android**: `resConfigs` in `android/app/build.gradle` enables regional locale fallback  
- **Web**: HTML `lang` attribute in `web/index.html` for browser locale detection
- **Automatic Detection**: `SettingsProvider.autoDetectAndSetLocale()` detects device language on first launch

This enables users with regional locales (e.g., `es_MX`, `fr_CA`, `de_AT`) to see translations in their language instead of falling back to English.

## iOS Build Instructions
- Initialize rbenv: `eval "$(rbenv init -)"` (requires Ruby 3.2.2+)
- Clean Flutter: `flutter clean && flutter pub get`
- Install pods: `cd ios && pod install`
- Build iOS: `flutter build ios --no-codesign`

## iOS Code Signing & Distribution

### Current Signing Setup (Working)
The iOS app signing is successfully configured with the following setup:

**Bundle ID**: `social.holis.app`
**Team ID**: `GZCZBKH7MY` (Verse Communications, Inc.)
**Certificate**: Apple Distribution: Verse Communications, Inc. (GZCZBKH7MY)

### Build Commands
- **IPA with Automatic Signing**: `flutter build ipa --export-options-plist=/Users/rabble/code/verse/plur/app_store_export_options_auto.plist`
- **Archive Only**: `flutter build ios --no-codesign` (for development/testing)

### Fastlane Configuration
Fastlane is configured with:
- **Ruby Environment**: Ruby 3.2.2+ with bundler
- **Match Setup**: Temporarily uses local git repo (see `fastlane/Matchfile`)
- **Auto Build Increment**: Fastlane automatically increments build numbers based on latest TestFlight build + 1
- **Lanes Available**:
  - `fastlane ios release` - Build and upload production app
  - `fastlane ios deploy_staging` - Build and upload staging app
  - `fastlane ios certs` - Refresh certificates

### Key Configuration Files
- `app_store_export_options_auto.plist` - Configured for automatic code signing
- `ios/Runner/Runner.entitlements` - Contains app entitlements and bundle ID
- `fastlane/Fastfile` - Build automation (API key section commented out due to format issues)
- `fastlane/Matchfile` - Certificate management configuration

### Environment Setup
Required environment variables in `~/.env.secret`:
```bash
APP_STORE_CONNECT_API_KEY_ID="your_key_id"
APP_STORE_CONNECT_ISSUER_ID="your_issuer_id" 
APP_STORE_CONNECT_API_KEY_CONTENT="your_key_content"
MATCH_PASSWORD="your_match_password"
```

### Distribution Process
1. Build IPA: `flutter build ipa --export-options-plist=app_store_export_options_auto.plist`
2. IPA will be created at: `build/ios/iphoneos/Runner.ipa`
3. For TestFlight: Use Fastlane lanes or manual upload via Xcode/Transporter
4. Build numbers are automatically incremented by Fastlane

### Troubleshooting Notes
- If API key issues occur, use username/password authentication (API key section is commented out)
- Match repository uses local git repo temporarily to avoid decryption issues
- Automatic signing is preferred over manual certificate management
- **Entitlements**: The `Runner.entitlements` file is properly linked in Xcode project via `CODE_SIGN_ENTITLEMENTS = "Runner/Runner.entitlements"`

### iOS Build Troubleshooting
If iOS build fails, check the following common issues:
1. **Deployment target issues**: The Podfile enforces iOS 15.5 minimum deployment target
2. **Ruby/CocoaPods version**: Use rbenv with Ruby 3.2.2+ and CocoaPods 1.12+
3. **Missing localization files**: If errors about missing messages_*.dart files appear, check lib/generated/intl/messages_all.dart
4. **Xcode configuration**: Make sure xcconfig files include the proper CocoaPods configurations
5. **Sentry**: Sentry has been completely removed from this project to avoid C++ compatibility issues with newer iOS SDK versions

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
- ALWAYS run `flutter analyze` after making code changes to check for syntax and type errors
- After significant changes, run the relevant tests to ensure nothing broke
- When working on a complex feature, test each part as you implement it
- When fixing one issue, verify you don't introduce new ones
- Ensure UI transitions are smooth and don't cause performance issues
- Profile the application when making performance-related changes
- DO NOT directly run the app (`flutter run`) from within the LLM coding agent - this will block the agent as it waits for the app process to complete, preventing further interaction. Instead, let the user run the app from their own terminal and continue focusing on code analysis and changes.

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

## Coding and Workflow Rules

- **Always run `flutter analyze` after each command.**
  - This ensures code quality and helps catch errors or warnings early in the development process.
  - If any issues are found, address them before proceeding to the next step.