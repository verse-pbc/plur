# Plur App Logging Guide

This guide describes how to use the structured logging system in the Plur application. The logging system is designed to provide consistent, filterable logs that help with debugging while keeping noise to a minimum.

## Basic Usage

The app uses a global `logger` instance that you can import and use throughout the application:

```dart
import 'package:nostrmo/util/app_logger.dart';

// Then in your code:
logger.d('This is a debug message');
logger.i('This is info');
logger.w('This is a warning');
logger.e('This is an error message');
```

## Log Levels

The logging system supports the following levels, in increasing order of severity:

- **Verbose** (`logger.v()`): Very detailed information, typically only useful when debugging specific issues
- **Debug** (`logger.d()`): Information useful for debugging, usually disabled in production
- **Info** (`logger.i()`): General information about normal application flow
- **Warning** (`logger.w()`): Potential issues that don't prevent the app from working
- **Error** (`logger.e()`): Errors that affect functionality but don't crash the app
- **WTF** (`logger.wtf()`): Critical failures that would typically cause a crash

In release mode, only warnings and errors are logged by default.

## Logging with Context

Always provide enough context in log messages to understand what's happening. For example:

```dart
// ❌ Poor: Not enough context
logger.d('Loading failed');

// ✅ Good: Clear context
logger.d('Failed to load group events from relay $relayUrl');
```

## Error Logging

When logging errors, use the additional parameters to include the error object and stack trace:

```dart
try {
  // Some code that might throw
} catch (e, stack) {
  logger.e('Failed to process event', e, stack);
}
```

## Categorized Logging

The logging system supports categorizing logs to make filtering easier:

```dart
// Using a specific category
logger.d('Connecting to relay', category: LogCategory.network);
logger.i('User authenticated', category: LogCategory.auth);
logger.e('Database query failed', error, stack, category: LogCategory.database);
```

Available categories:
- `LogCategory.core`: General application logic
- `LogCategory.network`: Network-related logs (API calls, relay connections)
- `LogCategory.database`: Database operations
- `LogCategory.ui`: UI-related logs
- `LogCategory.auth`: Authentication-related logs
- `LogCategory.groups`: Community/groups related logs
- `LogCategory.events`: Events feature logs
- `LogCategory.performance`: Performance metrics

## Runtime Filtering

The app includes a dialog for controlling which logs are displayed at runtime. You can access it via:

```dart
import 'package:nostrmo/util/log_filter_dialog.dart';

// Show the dialog
LogFilterDialog.show(context);
```

This dialog allows:
- Enabling/disabling specific categories
- Adding/removing excluded tags
- Enabling a "debug override" to see all logs

## Programmatic Filtering

You can also control filters programmatically:

```dart
// Filter by specific categories
logger.filterByCategories([LogCategory.network, LogCategory.auth]);

// Clear all category filters (show all categories)
logger.clearCategoryFilters();

// Add a tag to exclude
logger.addExcludedTag('provider');

// Remove an excluded tag
logger.removeExcludedTag('provider');

// Enable debug override (show all logs)
logger.enableDebugOverride(true);
```

## Debugging Tips

1. When debugging a specific feature, enable only the relevant categories to reduce noise.
2. For provider-related debugging, remove 'provider' from excluded tags.
3. Use the debug override temporarily when you need to see everything.
4. Custom tags can be added to exclude specific components when they become noisy.

## Stack Trace Formatting

The logging system includes a specialized stack trace formatter that makes error logs more readable:

- Highlights app code frames with an arrow (→) for better visibility
- De-emphasizes framework code (Flutter, provider, etc.)
- Compacts stack traces by collapsing repetitive framework frames
- Shows more frames in debug mode and fewer in production
- Extracts clean file names and line numbers for better readability

This happens automatically when you include a stack trace in any log method:

```dart
try {
  // Some code that might throw
} catch (e, stackTrace) {
  logger.e('Failed to perform operation', e, stackTrace, LogCategory.network);
}
```

## CI/Pre-commit Hooks

The project includes a pre-commit hook to enforce good logging practices. This prevents code with direct `print()` or `debugPrint()` statements from being committed.

### Installation

1. Run the installer script to set up the pre-commit hook:

```bash
bash scripts/install_hooks.sh
```

2. The hook will automatically run on each commit and check for:
   - Direct `print()` statements (should use `logger.d()` instead)
   - Direct `debugPrint()` statements (should use `logger.d()` instead)
   - Direct `developer.log()` calls (should use `logger.d()` instead)
   - Logger calls without categories (should specify a category)

3. If issues are found, the commit will be blocked until you fix them.

### Manual Checking

You can manually run the logging linter at any time:

```bash
dart scripts/lint_logging.dart [files...]
```

If no files are specified, it will check all staged Git files.

## Best Practices for Logging

- **Always use the global `logger` instance** instead of direct print statements
- **Include a specific `LogCategory`** to help with filtering
- **Select the appropriate log level** based on the information's importance:
  - `v()`: Verbose details useful only during deep debugging
  - `d()`: Debug information helpful during development
  - `i()`: Important information about normal application flow
  - `w()`: Warning situations that might lead to problems
  - `e()`: Error conditions that should be investigated
  - `wtf()`: Critical failures that need immediate attention
- **Include contextual data** like IDs and transaction references
- **Include stack traces for errors** to aid troubleshooting
- **Don't log sensitive information** like passwords or private keys
- **Keep log messages concise but descriptive**

## Performance Considerations

- Logs are conditionally compiled out in release mode for certain levels
- Low-priority logs (verbose, debug) are not sent to the console in release builds
- Category filtering happens early to avoid string formatting costs
- For expensive logs, check if the category is active before doing expensive work:

```dart
if (logger.isCategoryActive(LogCategory.performance)) {
  final expensiveData = computeExpensiveData();
  logger.d('Performance metrics: $expensiveData', null, null, LogCategory.performance);
}
```

## Troubleshooting

If the logger seems to be filtering too many messages:

1. Try enabling the debug override
2. Check which categories are active
3. Verify the excluded tags list

## Migrating Old Code

When migrating old code to use the new logging system:

1. Replace `print()` with `logger.d()`
2. Replace `debugPrint()` with `logger.d()`
3. Replace `developer.log()` with appropriate logger level
4. Add categories when appropriate to enable better filtering
5. For error logging, include error objects and stack traces

## Best Practices

1. **Choose the right level**: Use debug for development, info for important events, warnings for potential issues, errors for actual issues.
2. **Be concise but descriptive**: Include enough context without being verbose.
3. **Use categories**: Categorize logs to make filtering easier.
4. **Include error details**: Always include error objects and stack traces when available.
5. **Be mindful of sensitive data**: Never log sensitive information like private keys or passwords.
6. **Use emoji prefixes** for visual scanning: 🔄 for operations, ⚠️ for warnings, ❌ for errors, etc. 