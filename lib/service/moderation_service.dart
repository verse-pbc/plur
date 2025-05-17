import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/util/app_logger.dart';
import 'package:nostrmo/main.dart';

/// Service to track and manage moderated posts
class ModerationService extends ChangeNotifier with LaterFunction {
  // Map of post IDs to moderation events
  final Map<String, Event> _moderatedPosts = {};
  
  // Set of subscription IDs to avoid duplicates
  final Set<String> _activeSubscriptions = {};

  /// Check if a post has been moderated (removed)
  /// 
  /// @param postId The ID of the post to check
  /// @return true if the post has been moderated, false otherwise
  bool isPostModerated(String postId) {
    return _moderatedPosts.containsKey(postId);
  }
  
  /// Get the moderation event for a post if it exists
  /// 
  /// @param postId The ID of the post
  /// @return The moderation event, or null if the post is not moderated
  Event? getModerationEvent(String postId) {
    return _moderatedPosts[postId];
  }
  
  /// Subscribe to moderation events for a specific group
  /// 
  /// @param groupId The group identifier
  void subscribeToGroupModerationEvents(GroupIdentifier groupId) {
    // Generate a unique subscription ID for this group
    final subscriptionId = 'mod_${groupId.groupId}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Skip if already subscribed
    if (_activeSubscriptions.contains(subscriptionId)) {
      return;
    }
    
    logger.i('Subscribing to moderation events for group ${groupId.groupId}', 
        null, null, LogCategory.groups);
    
    // Add to active subscriptions
    _activeSubscriptions.add(subscriptionId);
    
    // Get the current timestamp
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Define filter for moderation events
    final filter = {
      "kinds": [EventKind.groupModeration],
      "#h": [groupId.groupId],
      "#action": ["remove"],
      "#type": ["post"],
      "since": currentTime - (60 * 60 * 24 * 30) // Include events from the last 30 days
    };
    
    try {
      // Subscribe to moderation events
      nostr!.subscribe(
        [filter],
        _handleModerationEvent,
        id: subscriptionId,
        relayTypes: [RelayType.temp],
        tempRelays: [groupId.host],
        sendAfterAuth: true,
      );
      
      logger.d('Successfully subscribed to moderation events: $subscriptionId',
          null, null, LogCategory.groups);
    } catch (e, stackTrace) {
      logger.e('Error subscribing to moderation events: $e', stackTrace, null, 
          LogCategory.groups);
      _activeSubscriptions.remove(subscriptionId);
    }
  }
  
  /// Handle incoming moderation events
  void _handleModerationEvent(Event event) {
    later(() {
      bool updated = false;
      
      // Process only group moderation events with proper tags
      if (event.kind == EventKind.groupModeration) {
        String? postId;
        String? action;
        String? type;
        
        // Extract tags
        for (var tag in event.tags) {
          if (tag.length > 1) {
            if (tag[0] == 'e') {
              postId = tag[1] as String;
            } else if (tag[0] == 'action') {
              action = tag[1] as String;
            } else if (tag[0] == 'type') {
              type = tag[1] as String;
            }
          }
        }
        
        // Only process post removal events
        if (postId != null && action == 'remove' && type == 'post') {
          logger.d('Received moderation event for post $postId', null, null, LogCategory.groups);
          
          // Check admin status (could add verification here)
          
          // Store moderation event
          if (!_moderatedPosts.containsKey(postId)) {
            updated = true;
          }
          _moderatedPosts[postId] = event;
        }
      }
      
      // Notify listeners if needed
      if (updated) {
        notifyListeners();
      }
    });
  }
  
  /// Unsubscribe from all moderation event subscriptions
  void unsubscribeAll() {
    for (final subId in _activeSubscriptions) {
      try {
        nostr!.unsubscribe(subId);
      } catch (e) {
        logger.e('Error unsubscribing from moderation events: $e', null, null,
            LogCategory.groups);
      }
    }
    _activeSubscriptions.clear();
  }
  
  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }
} 