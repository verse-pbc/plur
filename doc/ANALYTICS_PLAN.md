# Analytics Implementation Plan with PostHog

This document outlines the plan for implementing analytics in the Plur app using PostHog, an open-source product analytics platform. The goal is to collect meaningful data that helps us understand how users interact with the app while respecting privacy.

## Goals

1. **Understand User Journey**: Track how users navigate through the app
2. **Feature Usage**: Identify which features are most/least used
3. **Retention Analysis**: Understand what keeps users coming back
4. **Performance Monitoring**: Identify and address performance bottlenecks
5. **Growth Metrics**: Track app growth and adoption

## Implementation Approach

### 1. PostHog SDK Integration

1. Add PostHog dependency to `pubspec.yaml`:
   ```yaml
   dependencies:
     posthog_flutter: ^x.x.x
   ```

2. Create an analytics service class to abstract the PostHog implementation:
   - Path: `lib/services/analytics_service.dart`
   - This service will handle initialization, identifying users, and tracking events
   - Will support disabling analytics based on user preferences

3. Initialize PostHog in the main app startup flow with appropriate configuration:
   ```dart
   // In main.dart or app initialization
   await analyticsService.initialize(
     apiKey: 'YOUR_POSTHOG_API_KEY',
     host: 'YOUR_POSTHOG_HOST',
     flushAt: 20,
     flushInterval: 30000,
   );
   ```

### 2. User Identification & Properties

We'll identify users with a randomly generated ID, not with their nostr public key to maintain better privacy:

```dart
// When user logs in or app starts with user session
analyticsService.identify(
  userId: generateUserHash(), // NOT the actual nostr pubkey
  userProperties: {
    'app_version': appVersion,
    'platform': Platform.operatingSystem,
    'first_login_date': firstLoginDate,
    'os_version': Platform.operatingSystemVersion,
    'using_bunker': isUsingBunker,
  }
);
```

### 3. Events to Track

#### Session Events
- `app_start` - When the app is opened
- `app_background` - When the app goes to background 
- `app_foreground` - When the app comes to foreground
- `app_terminate` - When possible, track app termination

#### Authentication Events
- `login` - User logs in (with properties like method: 'privkey', 'bunker', etc.)
- `signup` - User creates a new account
- `logout` - User logs out
- `account_switch` - User switches between accounts

#### Navigation Events
- `screen_view` - Track when user navigates to a new screen
  - Properties: `screen_name`, `from_screen`

#### Community/Group Events
- `group_create` - User creates a group
- `group_join` - User joins a group
- `group_leave` - User leaves a group
- `group_invite` - User generates an invite
- `post_create` - User creates a post (with type: text, image, etc.)
- `post_view` - User views a detailed post
- `post_interact` - User interacts with a post (like, comment, etc.)

#### DM Events
- `dm_session_start` - User starts a new DM session
- `dm_send` - User sends a DM
- `dm_search` - User searches for someone to DM

#### Settings/Preferences Events
- `setting_change` - User changes a setting
  - Properties: `setting_name`, `new_value` (non-sensitive)
- `theme_change` - User changes theme
- `analytics_opt_out` - User opts out of analytics

#### Error Events
- `error` - Track errors and exceptions
  - Properties: `error_type`, `error_message`, `screen`

#### Performance Events
- `slow_operation` - Track operations that take longer than expected
  - Properties: `operation_type`, `duration_ms`
- `relay_connection_status` - Track relay connection status changes

### 4. Privacy Considerations

1. **User Opt-Out**:
   - Add a setting to allow users to opt out of analytics
   - If a user opts out, stop sending events and clear their data

2. **Data Minimization**:
   - Never track actual message content
   - Never track actual pubkeys or NIP-05 identifiers
   - Use hashed/anonymized identifiers for user tracking
   - Only track metadata, not content

3. **Transparency**:
   - Add a privacy policy section explaining what we track and why
   - Make the analytics code open source for transparency

### 5. Implementation Phases

#### Phase 1: Basic Integration
- Set up PostHog SDK with opt-out capability
- Implement session tracking (app_start, app_background, etc.)
- Implement screen_view tracking
- Add basic error tracking

#### Phase 2: Core Feature Tracking
- Track authentication events
- Track community/group interactions
- Track post creation and interaction events
- Track DM events

#### Phase 3: Advanced Analytics
- Set up funnels and cohorts in PostHog dashboard
- Track performance metrics
- Implement A/B testing capability (if needed)
- Create custom retention reports

### 6. Dashboard Setup

Create the following dashboards in PostHog:

1. **User Growth Dashboard**
   - New user signups over time
   - Active users (DAU/WAU/MAU)
   - Retention cohorts

2. **Engagement Dashboard**
   - Session frequency and duration
   - Screen popularity heatmap
   - Feature usage breakdown

3. **Community Activity Dashboard**
   - Group creation rate
   - Posts per group
   - Group joining rate

4. **Error & Performance Dashboard**
   - Error rates by type
   - Slow operations
   - Relay connection issues

## Technical Implementation Details

### Analytics Service

```dart
// Basic structure of the analytics service
class AnalyticsService {
  bool _initialized = false;
  bool _optedOut = false;
  
  Future<void> initialize({
    required String apiKey,
    required String host,
    int flushAt = 20,
    int flushInterval = 30000,
  }) async {
    // Initialize PostHog
    // Check saved opt-out preference
  }
  
  void identify({required String userId, Map<String, dynamic>? userProperties}) {
    if (_optedOut || !_initialized) return;
    // Identify user in PostHog
  }
  
  void trackEvent(String eventName, {Map<String, dynamic>? properties}) {
    if (_optedOut || !_initialized) return;
    // Track event in PostHog
  }
  
  void trackScreen(String screenName, {String? fromScreen}) {
    if (_optedOut || !_initialized) return;
    trackEvent('screen_view', properties: {
      'screen_name': screenName,
      'from_screen': fromScreen,
    });
  }
  
  void setOptOut(bool optOut) {
    _optedOut = optOut;
    // Save preference
    // Clear user data if opting out
  }
  
  // Helper methods for common events
  void trackError(String errorType, String errorMessage, {String? screen}) { ... }
  void trackPerformance(String operation, int durationMs) { ... }
}
```

### Using the Analytics Service

```dart
// Example usage in components/screens
void navigateToGroupDetail(Group group) {
  analyticsService.trackScreen('group_detail', fromScreen: 'groups_list');
  // Navigation logic
}

void createPost(String content, Group group) {
  // Post creation logic
  analyticsService.trackEvent('post_create', properties: {
    'post_type': hasImages ? 'image' : 'text',
    'group_id': hashGroupId(group.id), // hashed for privacy
    'character_count': content.length,
  });
}

// In app lifecycle handlers
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  switch (state) {
    case AppLifecycleState.resumed:
      analyticsService.trackEvent('app_foreground');
      break;
    case AppLifecycleState.paused:
      analyticsService.trackEvent('app_background');
      break;
    // Other states
  }
}
```

## Next Steps

1. Add PostHog Flutter SDK to the project
2. Implement the AnalyticsService class
3. Add opt-out setting in app settings
4. Start implementing Phase 1 events
5. Set up initial PostHog dashboards
6. Test analytics data collection
7. Proceed with Phase 2 and 3 implementation

## Compliance and Ethical Considerations

- Ensure all analytics collection complies with GDPR, CCPA, and other applicable privacy regulations
- Be transparent with users about what is collected and why
- Provide a clear and easy way to opt out
- Regularly review and clean up collected data
- Only collect what is necessary to improve the app experience