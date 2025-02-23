# Secrets

This folder contains `.env` files used for batch specifying environment variables.  

### Reference

For more details, see the [Dart documentation on environment declarations](https://dart.dev/libraries/core/environment-declarations) (look for the **Flutter** section).  

### Usage

To use these files when building **Plur**, you can pass them as flags to `flutter run` or `flutter build`:  

```sh
--dart-define-from-file=<use-define-config.json|.env>
```

This flag specifies the path to a .json or .env file containing key-value pairs that will be available as environment variables. These values can be accessed using:

```dart
String.fromEnvironment
bool.fromEnvironment
int.fromEnvironment
```

You can pass multiple environment files by repeating the `--dart-define-from-file` flag. If the same key is defined in both these files and `--dart-define`, the `--dart-define` value takes precedence.
