# Plur Dev Guide

## Build/Test Commands
- Setup: `flutter pub get`
- Run tests: `flutter test` or `flutter test test/path_to_specific_test.dart`
- Run single test: `flutter test --name="test name" test/path_to_test.dart`
- Lint: `flutter analyze`
- Auto fix: `dart fix --apply`
- Generate localizations: `flutter pub run intl_utils:generate`

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