This file contains instructions for contributing code to Plur.

# Testing

You can run the unit tests with:
```
flutter test
```

Or if you use Flutter Version Manager:

```
fvm flutter test
```

In VSCode/Cursor there is a task that you can run using Command-Shift-P -> Run Task -> Run Plur Tests or via a custom keyboard shortcut.

# Formatting

It's good practice to run `dart analyze` and `dart format` before committing your code.

# Localization

This project uses the [intl_utils](https://pub.dev/packages/intl_utils) Dart package to generate Dart code from the translation files. 


You can add localized strings to the project by:
1. Adding a key and english translation to `lib/l10n/intl_en.arb`.
2. Run `[fvm] flutter pub run intl_utils:generate`
3. In the UI where you want to use the string `import '../../generated/l10n.dart';`
4. Use your localized string like `localization.Your_string_key`

Any time you update the translation files (`.arb` files), make sure to run `[fvm] flutter pub run intl_utils:generate` again.