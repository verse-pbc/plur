import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/util/app_logger.dart';
import 'package:nostrmo/main.dart';

/// Service to track and manage moderated posts and banned users
class ModerationService extends ChangeNotifier with LaterFunction {
  // Map of post IDs to moderation events
  final Map<String, Event> _moderatedPosts = {};
  
  // Map of group ID + user pubkey to ban event
  final Map<String, Event> _bannedUsers = {};
  
  // Map of ban expiry times (groupId_pubkey to expiry timestamp)
  final Map<String, int> _banExpiryTimes = {};
  
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
  
  /// Check if a user is banned from a specific group
  /// 
  /// @param pubkey The user's public key
  /// @param groupId The group identifier
  /// @return true if the user is banned, false otherwise
  bool isUserBanned(String pubkey, GroupIdentifier groupId) {
    final key = _getBanKey(groupId.groupId, pubkey);
    
    // Check if user is banned
    if (_bannedUsers.containsKey(key)) {
      // Check if the ban has expired (for temporary bans)
      final expiryTime = _banExpiryTimes[key];
      if (expiryTime != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (now > expiryTime) {
          // Ban has expired, remove it
          _bannedUsers.remove(key);
          _banExpiryTimes.remove(key);
          return false;
        }
      }
      
      // User is banned and ban hasn't expired
      return true;
    }
    
    return false;
  }
  
  /// Get a user's ban event if it exists
  /// 
  /// @param pubkey The user's public key
  /// @param groupId The group identifier
  /// @return The ban event, or null if the user is not banned
  Event? getUserBanEvent(String pubkey, GroupIdentifier groupId) {
    final key = _getBanKey(groupId.groupId, pubkey);
    return _bannedUsers[key];
  }
  
  /// Get the ban reason for a user if they are banned
  /// 
  /// @param pubkey The user's public key
  /// @param groupId The group identifier
  /// @return The ban reason, or null if the user is not banned or no reason provided
  String? getBanReason(String pubkey, GroupIdentifier groupId) {
    final banEvent = getUserBanEvent(pubkey, groupId);
    if (banEvent == null) return null;
    
    // Extract reason from tags
    for (var tag in banEvent.tags) {
      if (tag.length > 1 && tag[0] == 'reason') {
        return tag[1] as String;
      }
    }
    
    return null;
  }
  
  /// Get the ban expiry time for a temporary ban
  /// 
  /// @param pubkey The user's public key
  /// @param groupId The group identifier
  /// @return The ban expiry timestamp, or null if permanent ban or not banned
  int? getBanExpiryTime(String pubkey, GroupIdentifier groupId) {
    final key = _getBanKey(groupId.groupId, pubkey);
    return _banExpiryTimes[key];
  }
  
  /// Helper method to generate ban key from group ID and pubkey
  String _getBanKey(String groupId, String pubkey) {
    return '${groupId}_$pubkey';
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
    
    // Define filter for post moderation events
    final postFilter = {
      "kinds": [EventKind.groupModeration],
      "#h": [groupId.groupId],
      "#action": ["remove"],
      "#type": ["post"],
      "since": currentTime - (60 * 60 * 24 * 30) // Include events from the last 30 days
    };
    
    // Define filter for user ban events
    final userFilter = {
      "kinds": [EventKind.groupModeration],
      "#h": [groupId.groupId],
      "#action": ["ban", "remove"],
      "#type": ["user"],
      "since": currentTime - (60 * 60 * 24 * 90) // Include events from the last 90 days for bans
    };
    
    try {
      // Subscribe to moderation events (post removals and user bans)
      nostr!.subscribe(
        [postFilter, userFilter],
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
        String? userPubkey;
        String? groupId;
        String? action;
        String? type;
        String? duration;
        
        // Extract tags
        for (var tag in event.tags) {
          if (tag.length > 1) {
            if (tag[0] == 'e') {
              postId = tag[1] as String;
            } else if (tag[0] == 'p') {
              userPubkey = tag[1] as String;
            } else if (tag[0] == 'h') {
              groupId = tag[1] as String;
            } else if (tag[0] == 'action') {
              action = tag[1] as String;
            } else if (tag[0] == 'type') {
              type = tag[1] as String;
            } else if (tag[0] == 'duration') {
              duration = tag[1] as String;
            }
          }
        }
        
        // Process post removal events
        if (postId != null && action == 'remove' && type == 'post') {
          logger.d('Received moderation event for post $postId', null, null, LogCategory.groups);
          
          // Store moderation event
          if (!_moderatedPosts.containsKey(postId)) {
            updated = true;
          }
          _moderatedPosts[postId] = event;
        }
        
        // Process user ban events
        else if (userPubkey != null && groupId != null && action == 'ban' && type == 'user') {
          logger.d('Received ban event for user ${userPubkey.substring(0, 8)}... in group $groupId', 
              null, null, LogCategory.groups);
          
          final key = _getBanKey(groupId, userPubkey);
          
          // Calculate expiry time for temporary bans
          if (duration != null) {
            try {
              final durationSeconds = int.parse(duration);
              final createdAt = event.createdAt;
              final expiryTime = createdAt + durationSeconds;
              
              _banExpiryTimes[key] = expiryTime;
              
              logger.d('Ban expires at timestamp $expiryTime (duration: $durationSeconds seconds)', 
                  null, null, LogCategory.groups);
            } catch (e) {
              logger.w('Failed to parse ban duration: $duration', null, null, LogCategory.groups);
            }
          }
          
          // Store ban event
          if (!_bannedUsers.containsKey(key)) {
            updated = true;
          }
          _bannedUsers[key] = event;
        }
        
        // Process user removal events (which may remove bans)
        else if (userPubkey != null && groupId != null && action == 'remove' && type == 'user') {
          // User removal events override ban events (if a user is unbanned)
          final key = _getBanKey(groupId, userPubkey);
          
          // Only update if we previously had a ban event
          if (_bannedUsers.containsKey(key)) {
            _bannedUsers.remove(key);
            _banExpiryTimes.remove(key);
            updated = true;
            
            logger.d('User ${userPubkey.substring(0, 8)}... ban removed from group $groupId', 
                null, null, LogCategory.groups);
          }
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