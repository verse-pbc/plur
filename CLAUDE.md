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