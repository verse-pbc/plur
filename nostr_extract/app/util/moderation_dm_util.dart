import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/util/app_logger.dart';

/// Utility class for sending moderation-related direct messages
class ModerationDmUtil {
  static final AppLogger _log = AppLogger();
  
  /// Send a moderation notification DM to a user about being removed from a group
  /// 
  /// @param recipientPubkey The pubkey of the user to notify
  /// @param groupIdentifier The group identifier
  /// @param reason Optional reason for the moderation action
  /// @param adminPubkey The pubkey of the admin who performed the action
  /// @return Future<bool> True if the DM was sent successfully
  static Future<bool> sendRemovalNotification(
    String recipientPubkey,
    GroupIdentifier groupIdentifier, {
    String? reason,
    String? adminPubkey
  }) async {
    try {
      // Get the signed-in user's pubkey (admin)
      final senderPubkey = nostr?.publicKey;
      if (senderPubkey == null) {
        _log.e("Failed to send moderation DM: No sender pubkey available", null, null, LogCategory.groups);
        return false;
      }
      
      // Get group metadata
      final groupMetadata = groupProvider.getMetadata(groupIdentifier);
      final groupName = groupMetadata?.name ?? groupIdentifier.groupId;
      
      // Create message content
      final Map<String, dynamic> content = {
        "type": "moderation_notification",
        "action": "user_removed",
        "group": {
          "id": groupIdentifier.groupId,
          "host": groupIdentifier.host,
          "name": groupName
        },
        "timestamp": DateTime.now().millisecondsSinceEpoch ~/ 1000,
        "by": adminPubkey ?? senderPubkey,
      };
      
      if (reason != null && reason.isNotEmpty) {
        content["reason"] = reason;
      }
      
      // Create human-readable text version
      String textContent = "🚫 Moderation Notice: You have been removed from the group \"$groupName\".\n\n";
      
      if (reason != null && reason.isNotEmpty) {
        textContent += "Reason: $reason\n\n";
      }
      
      textContent += "This action was performed by a group admin. ";
      textContent += "If you believe this was done in error, please contact the group admins.";
      
      // Create a combined message with both machine-readable and human-readable content
      final messageContent = jsonEncode({
        "metadata": content,
        "text": textContent
      });
      
      // Create an encrypted DM event 
      // Create tags with p tag for recipient
      List<List<String>> tags = [["p", recipientPubkey]];
      
      // Encrypt content using NIP-04
      String? encryptedContent = await nostr!.nostrSigner.encrypt(
        recipientPubkey,
        messageContent
      );
      
      if (encryptedContent == null) {
        _log.e("Failed to encrypt DM content", null, null, LogCategory.groups);
        return false;
      }
      
      // Create direct message event
      final event = Event(
        nostr!.publicKey,
        EventKind.privateDirectMessage,
        tags,
        encryptedContent
      );
      
      if (event != null) {
        _log.i("Moderation DM created successfully", null, null, LogCategory.groups);
        
        // Send to relays
        final relays = [groupIdentifier.host]; // Use group relay plus user's relays
        try {
          await nostr!.sendEvent(event, targetRelays: relays);
          _log.i("Moderation DM sent successfully", null, null, LogCategory.groups);
          return true;
        } catch (sendError) {
          _log.e("Error sending moderation DM: $sendError", null, null, LogCategory.groups);
          return false;
        }
      } else {
        _log.e("Failed to create encrypted DM event", null, null, LogCategory.groups);
        return false;
      }
    } catch (e) {
      _log.e("Error sending moderation DM: $e", null, null, LogCategory.groups);
      return false;
    }
  }
  
  /// Send a general moderation message to a user
  /// 
  /// @param recipientPubkey The pubkey of the user to message
  /// @param groupIdentifier The group identifier 
  /// @param subject Subject line for the message
  /// @param message The message content
  /// @return Future<bool> True if the message was sent successfully
  static Future<bool> sendModerationMessage(
    String recipientPubkey,
    GroupIdentifier groupIdentifier,
    String subject,
    String message
  ) async {
    try {
      // Get the signed-in user's pubkey (admin)
      final senderPubkey = nostr?.publicKey;
      if (senderPubkey == null) {
        _log.e("Failed to send moderation message: No sender pubkey available", null, null, LogCategory.groups);
        return false;
      }
      
      // Get group metadata
      final groupMetadata = groupProvider.getMetadata(groupIdentifier);
      final groupName = groupMetadata?.name ?? groupIdentifier.groupId;
      
      // Create full message with subject and group context
      final fullMessage = "📣 $subject - Group: $groupName\n\n$message\n\nThis message was sent by a group administrator.";
      
      // Create metadata wrapper
      final Map<String, dynamic> content = {
        "type": "moderation_message",
        "group": {
          "id": groupIdentifier.groupId,
          "host": groupIdentifier.host,
          "name": groupName
        },
        "subject": subject,
        "message": message,
        "timestamp": DateTime.now().millisecondsSinceEpoch ~/ 1000,
        "by": senderPubkey,
      };
      
      // Create a combined message with both machine-readable and human-readable content
      final messageContent = jsonEncode({
        "metadata": content,
        "text": fullMessage
      });
      
      // Create an encrypted DM event
      // Create tags with p tag for recipient
      List<List<String>> tags = [["p", recipientPubkey]];
      
      // Encrypt content using NIP-04
      String? encryptedContent = await nostr!.nostrSigner.encrypt(
        recipientPubkey,
        messageContent
      );
      
      if (encryptedContent == null) {
        _log.e("Failed to encrypt message content", null, null, LogCategory.groups);
        return false;
      }
      
      // Create direct message event
      final event = Event(
        nostr!.publicKey,
        EventKind.privateDirectMessage,
        tags,
        encryptedContent
      );
      
      if (event != null) {
        _log.i("Moderation message created successfully", null, null, LogCategory.groups);
        
        // Send to relays
        final relays = [groupIdentifier.host]; // Use group relay 
        try {
          await nostr!.sendEvent(event, targetRelays: relays);
          _log.i("Moderation message sent successfully", null, null, LogCategory.groups);
          return true;
        } catch (sendError) {
          _log.e("Error sending moderation message: $sendError", null, null, LogCategory.groups);
          return false;
        }
      } else {
        _log.e("Failed to create encrypted message event", null, null, LogCategory.groups);
        return false;
      }
    } catch (e) {
      _log.e("Error sending moderation message: $e", null, null, LogCategory.groups);
      return false;
    }
  }
} 