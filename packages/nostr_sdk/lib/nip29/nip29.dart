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
    var relays = [groupIdentifier.host];
    
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
    
    // Create the event - using kind 16402 for group moderation events
    var event = Event(
      nostr.publicKey,
      EventKind.groupModeration, // Moderation event kind (16402)
      tags,
      "", // No content needed for moderation events
    );
    
    try {
      // Send the event to the group's relay
      await nostr.sendEvent(event, tempRelays: relays, targetRelays: relays);
      return event;
    } catch (e) {
      // Log error and return null on failure
      print("Error sending post removal event: $e");
      return null;
    }
  }
}
