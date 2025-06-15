import '../nostr.dart';
import '../event.dart';
import '../event_kind.dart';
import 'group_identifier.dart';

class NIP29 {
  static Future<void> deleteEvent(
      Nostr nostr, GroupIdentifier groupIdentifier, String eventId) async {
    var relays = [groupIdentifier.host];
    var event = Event(
        nostr.publicKey,
        EventKind.groupDeleteEvent,
        [
          ["h", groupIdentifier.groupId],
          ["e", eventId]
        ],
        "");
    await nostr.sendEvent(event, tempRelays: relays, targetRelays: relays);
  }

  static Future<void> editStatus(Nostr nostr, GroupIdentifier groupIdentifier,
      bool? public, bool? open) async {
    if (public == null && open == null) {
      return;
    }

    var tags = [];
    tags.add(["h", groupIdentifier.groupId]);
    if (public != null) {
      if (public) {
        tags.add(["public"]);
      } else {
        tags.add(["private"]);
      }
    }
    if (open != null) {
      if (open) {
        tags.add(["open"]);
      } else {
        tags.add(["closed"]);
      }
    }

    var relays = [groupIdentifier.host];
    var event = Event(nostr.publicKey, EventKind.groupEditStatus, tags, "");
    await nostr.sendEvent(event, tempRelays: relays, targetRelays: relays);
  }

  static Future<void> addMember(
      Nostr nostr, GroupIdentifier groupIdentifier, String pubkey) async {
    var relays = [groupIdentifier.host];
    var event = Event(
        nostr.publicKey,
        EventKind.groupAddUser,
        [
          ["h", groupIdentifier.groupId],
          ["p", pubkey]
        ],
        "");
    await nostr.sendEvent(event, tempRelays: relays, targetRelays: relays);
  }

  static Future<void> removeMember(
      Nostr nostr, GroupIdentifier groupIdentifier, String pubkey) async {
    var relays = [groupIdentifier.host];
    var event = Event(
        nostr.publicKey,
        EventKind.groupRemoveUser,
        [
          ["h", groupIdentifier.groupId],
          ["p", pubkey]
        ],
        "");

    await nostr.sendEvent(event, tempRelays: relays, targetRelays: relays);
  }

  /// Create a moderation event to remove a post from a group
  /// 
  /// This creates and sends a moderation event (kind 16402) to remove a post from a group
  /// Only users with admin privileges should be able to remove posts
  /// 
  /// @param nostr The Nostr instance to use
  /// @param groupIdentifier Group identifier (relay and group ID)
  /// @param postId ID of the post to remove
  /// @param reason Optional reason for removal
  /// @return The created event if successful, null otherwise
  static Future<Event?> removePost(
      Nostr nostr, GroupIdentifier groupIdentifier, String postId, {String? reason}) async {
    print("REMOVE DEBUG: NIP29.removePost called - group: ${groupIdentifier.groupId}, relay: ${groupIdentifier.host}");
    var relays = [groupIdentifier.host];
    print("REMOVE DEBUG: Using relays: $relays");
    
    // Create the tags for the moderation event
    List<List<dynamic>> tags = [
      ["h", groupIdentifier.groupId], // Group ID
      ["e", postId], // Post ID
      ["action", "remove"], // Action (remove)
      ["type", "post"], // Type (post)
    ];
    
    // Add reason if provided
    if (reason != null && reason.isNotEmpty) {
      tags.add(["reason", reason]);
    }
    
    print("REMOVE DEBUG: Created tags: $tags");
    print("REMOVE DEBUG: Using EventKind.groupModeration (${EventKind.groupModeration})");
    
    // Create the event - using kind 16402 for group moderation events
    var event = Event(
      nostr.publicKey,
      EventKind.groupModeration, // Moderation event kind (16402)
      tags,
      "", // No content needed for moderation events
    );
    
    try {
      // Send the event to the group's relay
      print("REMOVE DEBUG: About to send event to relays: $relays");
      await nostr.sendEvent(event, tempRelays: relays, targetRelays: relays);
      print("REMOVE DEBUG: Event sent successfully with ID: ${event.id}");
      return event;
    } catch (e) {
      // Log error and return null on failure
      print("REMOVE DEBUG: Error sending post removal event: $e");
      return null;
    }
  }
  
  /// Create a moderation event to remove/ban a user from a group
  /// 
  /// This creates and sends a moderation event (kind 16402) to remove a user from a group
  /// Only users with admin privileges should be able to remove users
  /// 
  /// @param nostr The Nostr instance to use
  /// @param groupIdentifier Group identifier (relay and group ID)
  /// @param userPubkey Pubkey of the user to remove
  /// @param reason Optional reason for removal
  /// @return The created event if successful, null otherwise
  static Future<Event?> removeUser(
      Nostr nostr, GroupIdentifier groupIdentifier, String userPubkey, {String? reason}) async {
    print("REMOVE USER DEBUG: NIP29.removeUser called - group: ${groupIdentifier.groupId}, user: ${userPubkey.substring(0, 8)}...");
    var relays = [groupIdentifier.host];
    
    // Create the tags for the moderation event
    List<List<dynamic>> tags = [
      ["h", groupIdentifier.groupId], // Group ID
      ["p", userPubkey], // User pubkey
      ["action", "remove"], // Action (remove)
      ["type", "user"], // Type (user)
    ];
    
    // Add reason if provided
    if (reason != null && reason.isNotEmpty) {
      tags.add(["reason", reason]);
    }
    
    print("REMOVE USER DEBUG: Created tags: $tags");
    
    // Create the event - using kind 16402 for group moderation events
    var event = Event(
      nostr.publicKey,
      EventKind.groupModeration, // Moderation event kind (16402)
      tags,
      "", // No content needed for moderation events
    );
    
    try {
      // Send the event to the group's relay
      print("REMOVE USER DEBUG: About to send event to relays: $relays");
      await nostr.sendEvent(event, tempRelays: relays, targetRelays: relays);
      print("REMOVE USER DEBUG: Event sent successfully with ID: ${event.id}");
      return event;
    } catch (e) {
      // Log error and return null on failure
      print("REMOVE USER DEBUG: Error sending user removal event: $e");
      return null;
    }
  }
  
  /// Create a moderation event to ban a user from a group
  /// 
  /// This creates and sends a moderation event (kind 16402) to ban a user from a group
  /// Only users with admin privileges should be able to ban users
  /// 
  /// @param nostr The Nostr instance to use
  /// @param groupIdentifier Group identifier (relay and group ID)
  /// @param userPubkey Pubkey of the user to ban
  /// @param reason Optional reason for ban
  /// @param duration Optional ban duration in seconds (for temporary bans)
  /// @return The created event if successful, null otherwise
  static Future<Event?> banUser(
      Nostr nostr, GroupIdentifier groupIdentifier, String userPubkey, 
      {String? reason, int? duration}) async {
    print("BAN USER DEBUG: NIP29.banUser called - group: ${groupIdentifier.groupId}, user: ${userPubkey.substring(0, 8)}...");
    var relays = [groupIdentifier.host];
    
    // Create the tags for the moderation event
    List<List<dynamic>> tags = [
      ["h", groupIdentifier.groupId], // Group ID
      ["p", userPubkey], // User pubkey
      ["action", "ban"], // Action (ban)
      ["type", "user"], // Type (user)
    ];
    
    // Add reason if provided
    if (reason != null && reason.isNotEmpty) {
      tags.add(["reason", reason]);
    }
    
    // Add duration if provided (for temporary bans)
    if (duration != null) {
      tags.add(["duration", duration.toString()]);
    }
    
    print("BAN USER DEBUG: Created tags: $tags");
    
    // Create the event - using kind 16402 for group moderation events
    var event = Event(
      nostr.publicKey,
      EventKind.groupModeration, // Moderation event kind (16402)
      tags,
      "", // No content needed for moderation events
    );
    
    try {
      // Send the event to the group's relay
      print("BAN USER DEBUG: About to send event to relays: $relays");
      await nostr.sendEvent(event, tempRelays: relays, targetRelays: relays);
      print("BAN USER DEBUG: Event sent successfully with ID: ${event.id}");
      return event;
    } catch (e) {
      // Log error and return null on failure
      print("BAN USER DEBUG: Error sending user ban event: $e");
      return null;
    }
  }
}
