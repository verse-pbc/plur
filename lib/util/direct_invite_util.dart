import 'dart:convert';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/util/string_code_generator.dart';
// Using DateTime directly for timestamps
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/group_invite_link_util.dart';
import 'package:nostrmo/provider/relay_provider.dart';
import 'package:nostrmo/features/events/nostr_event_kinds.dart';
import 'package:logging/logging.dart';

/// Utility class for handling direct invites to groups via DM
class DirectInviteUtil {
  static final _log = Logger('DirectInviteUtil');

  /// Create a structured invite payload for sending via DM
  static Map<String, dynamic> createInvitePayload({
    required String groupId,
    required String code,
    required String relay,
    required String groupName,
    String? avatar,
    String role = 'member',
    DateTime? expiresAt,
    bool reusable = true,
  }) {
    // Generate text fallback with direct protocol URL
    final inviteUrl = GroupInviteLinkUtil.generateDirectProtocolUrl(
      groupId, code, relay);
      
    return {
      "invite": {
        "group_id": groupId,
        "code": code,
        "relay": relay,
        "group_name": groupName,
        "avatar": avatar ?? "",
        "role": role,
        "expires_at": expiresAt != null ? expiresAt.millisecondsSinceEpoch ~/ 1000 : 0,
        "reusable": reusable
      },
      "text": "Hey! Join my Plur group: $inviteUrl"
    };
  }

  /// Send an invite via direct message to the specified recipient
  static Future<Event?> sendInviteAsDM({
    required String recipientPubkey,
    required Map<String, dynamic> invitePayload,
    bool usePrivateDM = false,
  }) async {
    try {
      if (nostr == null) {
        _log.severe("Nostr instance is null");
        return null;
      }
      
      // Convert payload to JSON string
      String jsonPayload = jsonEncode(invitePayload);
      
      // Create tags with p tag for recipient
      List<dynamic> tags = [["p", recipientPubkey]];
      
      Event? event;
      
      if (usePrivateDM) {
        // Use NIP-44 private DM (gift wrap)
        var rumorEvent = Event(
          nostr!.publicKey, 
          EventKind.privateDirectMessage, 
          tags, 
          jsonPayload, 
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000
        );
        
        event = await GiftWrapUtil.getGiftWrapEvent(
          nostr!, 
          rumorEvent, 
          nostr!, 
          recipientPubkey
        );
      } else {
        // Use standard NIP-04 encryption
        String? encryptedContent = await nostr!.nostrSigner.encrypt(
          recipientPubkey, 
          jsonPayload
        );
        
        if (encryptedContent == null) {
          _log.severe("Failed to encrypt content");
          return null;
        }
        
        event = Event(
          nostr!.publicKey,
          EventKind.directMessage,
          tags,
          encryptedContent,
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000
        );
      }
      
      if (event != null) {
        // Send event to relays
        _log.info("Sending invite DM to $recipientPubkey");
        return await nostr!.sendEvent(event);
      }
      
      return null;
    } catch (e) {
      _log.severe("Error sending invite DM: $e");
      return null;
    }
  }

  /// Generate a random invite code
  static String generateInviteCode() {
    return StringCodeGenerator.generateInviteCode();
  }
  
  /// Create, send and track a direct invite to a user
  static Future<bool> sendDirectInvite({
    required GroupIdentifier groupIdentifier,
    required String recipientPubkey,
    required String groupName,
    String? avatar,
    String role = 'member',
    DateTime? expiresAt,
    bool reusable = true,
  }) async {
    try {
      // Generate invite code
      final inviteCode = generateInviteCode();
      
      // Create invite event (same as regular invites)
      final tags = [
        ["h", groupIdentifier.groupId],
        ["code", inviteCode],
        ["roles", role],
        ["p", recipientPubkey], // Add recipient pubkey to track invites
      ];

      final inviteEvent = Event(
        nostr!.publicKey,
        EventKind.groupCreateInvite,
        tags,
        "", // Empty content as per normal invites
      );

      // Send invite event to group's host relay and default groups relay
      List<String> relaysToTry = [
        groupIdentifier.host, 
        RelayProvider.defaultGroupsRelayAddress
      ];
      
      // Ensure no duplicates
      relaysToTry = relaysToTry.toSet().toList();
      
      // Send to all applicable relays
      for (final relay in relaysToTry) {
        try {
          _log.info("Sending invite event to relay: $relay");
          nostr!.sendEvent(
            inviteEvent,
            tempRelays: [relay], 
            targetRelays: [relay]
          );
        } catch (e) {
          _log.warning("Error sending invite to relay $relay: $e");
          // Continue to next relay
        }
      }
      
      // Create structured invite payload for DM
      final invitePayload = createInvitePayload(
        groupId: groupIdentifier.groupId,
        code: inviteCode,
        relay: groupIdentifier.host,
        groupName: groupName,
        avatar: avatar,
        role: role,
        expiresAt: expiresAt,
        reusable: reusable,
      );
      
      // Send as direct message
      final dmEvent = await sendInviteAsDM(
        recipientPubkey: recipientPubkey,
        invitePayload: invitePayload,
      );
      
      return dmEvent != null;
    } catch (e) {
      _log.severe("Error sending direct invite: $e");
      return false;
    }
  }
  
  /// Parse an invite from a DM content
  static Map<String, dynamic>? parseInviteFromDM(String dmContent) {
    try {
      final Map<String, dynamic> payload = jsonDecode(dmContent);
      if (payload.containsKey('invite')) {
        return payload;
      }
      return null;
    } catch (e) {
      _log.warning("Failed to parse invite from DM: $e");
      return null;
    }
  }
  
  /// Subscribe to invite accept events for a group
  static void subscribeToAcceptEvents(
    String groupId, 
    void Function(Event) onAcceptEvent
  ) {
    final filter = Filter(
      kinds: [EventKindExtension.groupInviteAccept],
      authors: [nostr!.publicKey],
    );
    
    nostr!.subscribe([filter.toJson()], onAcceptEvent);
  }
}