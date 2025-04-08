# Analytics Integration Examples

This document provides examples of how to use the Analytics Service throughout the app.

## Basic Setup

First, make sure the analytics service is initialized in your main.dart file:

```dart
import 'package:nostrmo/services/analytics_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize other services...
  
  // Setup analytics
  final analyticsService = AnalyticsService();
  await analyticsService.initialize(
    apiKey: 'your-posthog-api-key',
    host: 'https://app.posthog.com',
  );
  
  runApp(const MyApp());
}
```

## Tracking Screen Views

Track screen views whenever a user navigates to a new screen:

```dart
class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AnalyticsService _analytics = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _analytics.trackScreen('profile_screen');
  }
  
  // Rest of the code...
}
```

## Tracking User Actions

Track specific user actions to understand feature usage:

```dart
void _createNewGroup() {
  // Create group logic...
  
  final groupId = 'abc123'; // The actual group ID
  final groupName = 'My Group'; // The actual group name
  
  // Track the group creation
  AnalyticsService().trackGroupCreate(
    groupId,
    groupName,
    isPrivate: true,
  );
}

void _sendPost() {
  // Post sending logic...
  
  AnalyticsService().trackPostCreate(
    groupId: 'group-123',
    hasMedia: _selectedMedia != null,
    characterCount: _postText.length,
    isReply: _replyingToPost != null,
  );
}
```

## Tracking Errors

Track errors to identify issues affecting users:

```dart
Future<void> _fetchData() async {
  try {
    final data = await apiService.getData();
    setState(() {
      _data = data;
    });
  } catch (e, stackTrace) {
    AnalyticsService().trackError(
      'api_error',
      e.toString(),
      stackTrace: stackTrace,
    );
    
    // Show error message to user...
  }
}
```

## Tracking Performance

Track performance metrics to identify bottlenecks:

```dart
Future<void> _loadLargeList() async {
  final stopwatch = Stopwatch()..start();
  
  try {
    final data = await repository.fetchItems();
    setState(() {
      _items = data;
    });
  } finally {
    stopwatch.stop();
    
    AnalyticsService().trackPerformance(
      'load_large_list',
      stopwatch.elapsedMilliseconds,
      extraProperties: {'item_count': _items.length},
    );
  }
}
```

## App Lifecycle Tracking

Track app lifecycle events by implementing the WidgetsBindingObserver:

```dart
class _AppState extends State<App> with WidgetsBindingObserver {
  final AnalyticsService _analytics = AnalyticsService();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _analytics.trackAppLifecycleState(state);
  }
  
  // Rest of the code...
}
```

## Custom Event Tracking

Track custom events with specific properties:

```dart
void _handleSettingsChange(String setting, dynamic value) {
  // Update setting logic...
  
  // Track the settings change
  AnalyticsService().trackEvent('setting_change', properties: {
    'setting': setting,
    'value': value.toString(),
  });
}

void _handleThemeChange(ThemeMode themeMode) {
  // Change theme logic...
  
  // Track the theme change
  AnalyticsService().trackEvent('theme_change', properties: {
    'theme': themeMode.toString(),
  });
}
```

## Integration with Navigation

Track screen views automatically when using the Navigator:

```dart
// Create a custom page route observer
class AnalyticsRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  final AnalyticsService _analytics = AnalyticsService();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      _analytics.trackScreen(
        route.settings.name ?? 'unknown',
        fromScreen: previousRoute?.settings.name,
      );
    }
  }
}

// Use it in your MaterialApp
MaterialApp(
  navigatorObservers: [
    AnalyticsRouteObserver(),
  ],
  // Other properties...
)
```

## Opt-Out Management

Respect user preferences by allowing them to opt out of analytics:

```dart
class PrivacySettingsScreen extends StatefulWidget {
  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final AnalyticsService _analytics = AnalyticsService();
  bool _analyticsEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _analyticsEnabled = !_analytics.isOptedOut;
  }
  
  Future<void> _toggleAnalytics(bool value) async {
    await _analytics.setOptOut(!value);
    setState(() {
      _analyticsEnabled = value;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Other properties...
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable Analytics'),
            subtitle: const Text(
              'Help us improve the app by sharing anonymous usage data',
            ),
            value: _analyticsEnabled,
            onChanged: _toggleAnalytics,
          ),
          // Other settings...
        ],
      ),
    );
  }
}
```

## Best Practices

1. **Don't Track Personal Data**: Never track personal information, message content, or identifiers.
2. **Use Consistent Event Names**: Use snake_case for event names (e.g., `post_create`, not `postCreate`).
3. **Add Context to Events**: Include relevant context in event properties (e.g., screen name).
4. **Check for Opt-Out**: The AnalyticsService handles this automatically, but be aware it might not track.
5. **Test Analytics**: Verify events are recorded correctly in the PostHog dashboard.
6. **Document New Events**: When adding new analytics events, document them in the codebase.