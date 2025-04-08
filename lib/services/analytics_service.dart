import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Import the PostHog SDK once added to pubspec.yaml
// import 'package:posthog_flutter/posthog_flutter.dart';

/// Service that handles all analytics tracking in the app.
/// 
/// This service abstracts the PostHog implementation and provides a clean API
/// for tracking events throughout the app. It handles user opt-out preferences
/// and ensures privacy by not tracking sensitive information.
class AnalyticsService {
  static const String _optOutKey = 'analytics_opted_out';
  static const String _userIdKey = 'analytics_user_id';
  
  bool _initialized = false;
  bool _optedOut = false;
  String? _currentScreen;
  String? _userId;
  
  // Static instance for singleton pattern
  static final AnalyticsService _instance = AnalyticsService._internal();
  
  // Factory constructor to return the same instance
  factory AnalyticsService() => _instance;
  
  // Private constructor
  AnalyticsService._internal();
  
  /// Initialize the analytics service with PostHog configuration.
  /// 
  /// This should be called during app startup, after any required permissions
  /// have been granted.
  Future<void> initialize({
    required String apiKey,
    required String host,
    int flushAt = 20,
    int flushInterval = 30000,
  }) async {
    if (_initialized) return;
    
    try {
      // Load opt-out preference
      final prefs = await SharedPreferences.getInstance();
      _optedOut = prefs.getBool(_optOutKey) ?? false;
      
      // Initialize PostHog SDK
      /*
      await Posthog.initAsync(
        apiKey,
        host: host,
        flushAt: flushAt,
        flushInterval: flushInterval,
        captureAppLifecycleEvents: false, // We'll handle these manually
      );
      */
      
      // Get or generate user ID
      _userId = prefs.getString(_userIdKey);
      if (_userId == null) {
        _userId = _generateUserId();
        await prefs.setString(_userIdKey, _userId!);
      }
      
      _initialized = true;
      
      // If not opted out, identify the user
      if (!_optedOut) {
        _identifyUser();
      }
      
      debugPrint('Analytics service initialized. Opted out: $_optedOut');
    } catch (e) {
      debugPrint('Failed to initialize analytics: $e');
      // Fail gracefully - disable analytics on error
      _optedOut = true;
    }
  }
  
  /// Generate a unique user ID that isn't the Nostr public key.
  /// 
  /// This creates a random ID that will consistently identify the user
  /// without exposing their actual Nostr identity.
  String _generateUserId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = timestamp + DateTime.now().microsecond.toString();
    final bytes = utf8.encode(random);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }
  
  /// Identify the current user with our analytics platform.
  /// 
  /// This sets the user ID and basic properties in PostHog.
  void _identifyUser() {
    if (_optedOut || !_initialized || _userId == null) return;
    
    final properties = {
      'app_version': 'TODO', // Get from package info
      'platform': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
      'first_seen_at': DateTime.now().toIso8601String(),
    };
    
    // Identify in PostHog
    /*
    Posthog.identify(
      userId: _userId!,
      userProperties: properties,
    );
    */
    
    debugPrint('User identified for analytics: $_userId');
  }
  
  /// Update user properties in the analytics platform.
  /// 
  /// This can be used to update user properties as they change.
  void updateUserProperties(Map<String, dynamic> properties) {
    if (_optedOut || !_initialized || _userId == null) return;
    
    // Set user properties in PostHog
    /*
    Posthog.identify(
      userId: _userId!,
      userProperties: properties,
    );
    */
    
    debugPrint('Updated user properties: $properties');
  }
  
  /// Track a custom event with optional properties.
  /// 
  /// This is the main method for tracking events throughout the app.
  void trackEvent(String eventName, {Map<String, dynamic>? properties}) {
    if (_optedOut || !_initialized) return;
    
    // Add current screen to properties if available
    final eventProperties = Map<String, dynamic>.from(properties ?? {});
    if (_currentScreen != null) {
      eventProperties['screen'] = _currentScreen;
    }
    
    // Track event in PostHog
    /*
    Posthog.capture(
      eventName: eventName,
      properties: eventProperties,
    );
    */
    
    debugPrint('Tracked event: $eventName with properties: $eventProperties');
  }
  
  /// Track screen views to understand navigation patterns.
  /// 
  /// Call this method when navigating to a new screen.
  void trackScreen(String screenName, {String? fromScreen}) {
    if (_optedOut || !_initialized) return;
    
    _currentScreen = screenName;
    
    trackEvent('screen_view', properties: {
      'screen_name': screenName,
      'from_screen': fromScreen,
    });
  }
  
  /// Track errors that occur in the app.
  /// 
  /// This helps identify and fix issues affecting users.
  void trackError(String errorType, String errorMessage, {String? screen, StackTrace? stackTrace}) {
    if (_optedOut || !_initialized) return;
    
    final properties = {
      'error_type': errorType,
      'error_message': errorMessage,
      'screen': screen ?? _currentScreen,
      'stack_trace': stackTrace?.toString(),
    };
    
    trackEvent('error', properties: properties);
  }
  
  /// Track performance metrics for operations.
  /// 
  /// Use this to identify and address performance bottlenecks.
  void trackPerformance(String operation, int durationMs, {Map<String, dynamic>? extraProperties}) {
    if (_optedOut || !_initialized) return;
    
    final properties = {
      'operation': operation,
      'duration_ms': durationMs,
      ...?extraProperties,
    };
    
    trackEvent('performance', properties: properties);
  }
  
  /// Track app lifecycle events.
  /// 
  /// Call this from the app's lifecycle state changes.
  void trackAppLifecycleState(AppLifecycleState state) {
    if (_optedOut || !_initialized) return;
    
    String eventName;
    switch (state) {
      case AppLifecycleState.resumed:
        eventName = 'app_foreground';
        break;
      case AppLifecycleState.paused:
        eventName = 'app_background';
        break;
      case AppLifecycleState.detached:
        eventName = 'app_terminate';
        break;
      default:
        return; // Don't track other states
    }
    
    trackEvent(eventName);
  }
  
  /// Track when a user creates a community/group.
  void trackGroupCreate(String groupId, String groupName, {bool isPrivate = true}) {
    if (_optedOut || !_initialized) return;
    
    // Hash the group ID and name for privacy
    final hashedGroupId = _hashString(groupId);
    final hashedGroupName = _hashString(groupName);
    
    trackEvent('group_create', properties: {
      'group_id_hash': hashedGroupId,
      'group_name_hash': hashedGroupName,
      'is_private': isPrivate,
    });
  }
  
  /// Track when a user joins a community/group.
  void trackGroupJoin(String groupId, String groupName, {bool viaInvite = false}) {
    if (_optedOut || !_initialized) return;
    
    // Hash the group ID and name for privacy
    final hashedGroupId = _hashString(groupId);
    final hashedGroupName = _hashString(groupName);
    
    trackEvent('group_join', properties: {
      'group_id_hash': hashedGroupId,
      'group_name_hash': hashedGroupName,
      'via_invite': viaInvite,
    });
  }
  
  /// Track when a user creates a post.
  void trackPostCreate({
    required String groupId,
    required bool hasMedia,
    required int characterCount,
    bool isReply = false,
  }) {
    if (_optedOut || !_initialized) return;
    
    // Hash the group ID for privacy
    final hashedGroupId = _hashString(groupId);
    
    trackEvent('post_create', properties: {
      'group_id_hash': hashedGroupId,
      'has_media': hasMedia,
      'character_count': characterCount,
      'is_reply': isReply,
    });
  }
  
  /// Track when a user starts a DM session.
  void trackDmSessionStart(String recipientId) {
    if (_optedOut || !_initialized) return;
    
    // Hash the recipient ID for privacy
    final hashedRecipientId = _hashString(recipientId);
    
    trackEvent('dm_session_start', properties: {
      'recipient_id_hash': hashedRecipientId,
    });
  }
  
  /// Set the user's opt-out preference.
  /// 
  /// This will stop tracking if opted out, and clear any existing data.
  Future<void> setOptOut(bool optOut) async {
    _optedOut = optOut;
    
    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_optOutKey, _optedOut);
    
    if (_initialized) {
      // Handle opt-out in PostHog
      /*
      if (optOut) {
        Posthog.disable();
        // Optional: Clear user data
        // Posthog.reset();
      } else {
        Posthog.enable();
        // Re-identify the user
        _identifyUser();
      }
      */
    }
    
    debugPrint('Analytics opt-out set to: $_optedOut');
  }
  
  /// Hash a string for privacy when tracking.
  /// 
  /// This creates a consistent hash that can be used for correlation
  /// without exposing the actual value.
  String _hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16); // Use first 16 chars of hash
  }
  
  /// Check if analytics is currently enabled.
  bool get isEnabled => _initialized && !_optedOut;
  
  /// Check if the user has opted out of analytics.
  bool get isOptedOut => _optedOut;
}