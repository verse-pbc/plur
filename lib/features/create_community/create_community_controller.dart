import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../main.dart';
import '../../util/community_relay_util.dart';
import '../../util/string_code_generator.dart';

typedef CreateCommunityModel = (GroupIdentifier, String);

/// A controller class that manages group creation.
class CreateCommunityController
    extends AutoDisposeAsyncNotifier<CreateCommunityModel?> {
  // Using dart:developer log instead of Logger class
  
  /// Error message from the last failed operation
  String? _lastErrorMessage;
  
  /// Get the error message from the last failed operation
  String get lastError => _lastErrorMessage ?? "Unknown error";
      
  @override
  FutureOr<CreateCommunityModel?> build() async {
    return null;
  }

  /// Creates a new community with the given name and optional custom invite code.
  /// Returns true if successful, false otherwise.
  Future<bool> createCommunity(String name, {String? customInviteCode}) async {
    state = const AsyncValue<CreateCommunityModel?>.loading();
    _lastErrorMessage = null;
    
    try {
      log("Creating community: $name with${customInviteCode != null ? ' custom' : ''} invite code",
        name: 'CreateCommunityController');
      
      // Step 1: Create group identifier
      final groupIdentifier = await _createGroupIdentifier();
      if (groupIdentifier == null) {
        _lastErrorMessage = "Failed to create group identifier";
        log(_lastErrorMessage!, level: Level.SEVERE.value, name: 'CreateCommunityController');
        state = AsyncValue<CreateCommunityModel?>.error(_lastErrorMessage!, StackTrace.current);
        return false;
      }
      
      log("Created group identifier: ${groupIdentifier.groupId}", 
        name: 'CreateCommunityController');
      
      // Step 2: Set group name
      try {
        await _setGroupName(groupIdentifier, name);
        log("Set group name: $name for group ${groupIdentifier.groupId}", 
          name: 'CreateCommunityController');
      } catch (e, stackTrace) {
        _lastErrorMessage = "Failed to set group name: ${e.toString()}";
        log(_lastErrorMessage!, level: Level.SEVERE.value, name: 'CreateCommunityController');
        log(stackTrace.toString(), level: Level.SEVERE.value, name: 'CreateCommunityController');
        state = AsyncValue<CreateCommunityModel?>.error(_lastErrorMessage!, stackTrace);
        return false;
      }
      
      // Step 3: Generate invite link
      String inviteLink;
      try {
        inviteLink = await _generateInviteLink(groupIdentifier, customInviteCode);
        log("Generated invite link for group ${groupIdentifier.groupId}", 
          name: 'CreateCommunityController');
      } catch (e, stackTrace) {
        _lastErrorMessage = "Failed to generate invite link: ${e.toString()}";
        log(_lastErrorMessage!, level: Level.SEVERE.value, name: 'CreateCommunityController');
        log(stackTrace.toString(), level: Level.SEVERE.value, name: 'CreateCommunityController');
        state = AsyncValue<CreateCommunityModel?>.error(_lastErrorMessage!, stackTrace);
        return false;
      }
      
      // Success - update state
      state = AsyncValue<CreateCommunityModel?>.data((
        groupIdentifier,
        inviteLink,
      ));
      
      log("Community created successfully: ${groupIdentifier.groupId}", 
        name: 'CreateCommunityController');
      return true;
    } catch (e, stackTrace) {
      _lastErrorMessage = "Unexpected error creating community: ${e.toString()}";
      log(_lastErrorMessage!, level: Level.SEVERE.value, name: 'CreateCommunityController');
      log(stackTrace.toString(), level: Level.SEVERE.value, name: 'CreateCommunityController');
      state = AsyncValue<CreateCommunityModel?>.error(_lastErrorMessage!, stackTrace);
      return false;
    }
  }

  /// Creates a group identifier with a generated ID
  /// Returns the GroupIdentifier or null if creation failed
  Future<GroupIdentifier?> _createGroupIdentifier() async {
    try {
      final groupId = StringCodeGenerator.generateGroupId();
      log("Generated group ID: $groupId", name: 'CreateCommunityController');
      
      log("Attempting to create group with fallbacks", name: 'CreateCommunityController');
      
      // Try creating the group using our fallback utility
      final result = await CommunityRelayUtil.createGroup(groupId)
          .timeout(const Duration(seconds: 30), onTimeout: () {
        _lastErrorMessage = "Group creation timed out after 30 seconds";
        log(_lastErrorMessage!, level: Level.SEVERE.value, name: 'CreateCommunityController');
        return null;
      });
      
      if (result == null) {
        if (_lastErrorMessage == null) {
          _lastErrorMessage = "Group identifier creation failed on all relays";
          log(_lastErrorMessage!, level: Level.SEVERE.value, name: 'CreateCommunityController');
        }
      } else {
        log("Successfully created group on relay: ${result.host}", 
            name: 'CreateCommunityController');
        
        // No need to manually update the repository list here
        // The repository will handle this internally
        log("Group created successfully", name: 'CreateCommunityController');
      }
      
      return result;
    } catch (e, stackTrace) {
      _lastErrorMessage = "Error creating group identifier: ${e.toString()}";
      log(_lastErrorMessage!, level: Level.SEVERE.value, name: 'CreateCommunityController');
      log(stackTrace.toString(), level: Level.SEVERE.value, name: 'CreateCommunityController');
      return null;
    }
  }

  /// Sets the group name in metadata
  /// Throws an exception if the operation fails
  Future<void> _setGroupName(GroupIdentifier groupIdentifier, String name) async {
    try {
      final groupId = groupIdentifier.groupId;
      final host = groupIdentifier.host;
      
      log("Setting group name: '$name' for group $groupId on host $host", 
        name: 'CreateCommunityController');
      
      // Create the event for setting group metadata
      final tags = [
        ["h", groupId]
      ];
      
      if (name.isNotEmpty) {
        tags.add(["name", name]);
      }
      
      final event = Event(
        nostr!.publicKey,
        EventKind.groupEditMetadata,
        tags,
        "",
      );
      
      // Try to send the event with fallbacks
      final resultEvent = await CommunityRelayUtil.sendEventWithFallbacks(event)
          .timeout(const Duration(seconds: 20), onTimeout: () {
        throw TimeoutException("Setting group name timed out after 20 seconds");
      });
      
      if (resultEvent == null) {
        throw Exception("Failed to set group metadata on any relay");
      }
      
      log("Group name set successfully for $groupId", name: 'CreateCommunityController');
    } catch (e, stackTrace) {
      log("Error setting group name: ${e.toString()}", 
        level: Level.SEVERE.value, name: 'CreateCommunityController');
      log(stackTrace.toString(), level: Level.SEVERE.value, name: 'CreateCommunityController');
      rethrow; // Re-throw to be caught by the caller
    }
  }

  /// Generates an invite link for the group
  /// Throws an exception if the operation fails
  Future<String> _generateInviteLink(GroupIdentifier groupIdentifier, String? customInviteCode) async {
    try {
      // Use the custom invite code if provided, otherwise generate one
      final inviteCode = customInviteCode?.isNotEmpty == true
          ? customInviteCode!
          : StringCodeGenerator.generateInviteCode();
      
      log("Generating invite link with code: $inviteCode for group ${groupIdentifier.groupId}", 
        name: 'CreateCommunityController');
      
      // Create the event for creating an invite
      final tags = [
        ["h", groupIdentifier.groupId],
        ["code", inviteCode],
        ["roles", "member"]
      ];
      
      final inviteEvent = Event(
        nostr!.publicKey,
        EventKind.groupCreateInvite,
        tags,
        "", // Empty content as per example
      );
      
      // Try to send the event with fallbacks
      final resultEvent = await CommunityRelayUtil.sendEventWithFallbacks(inviteEvent)
          .timeout(const Duration(seconds: 20), onTimeout: () {
        throw TimeoutException("Generating invite link timed out after 20 seconds");
      });
      
      if (resultEvent == null) {
        throw Exception("Failed to create invite on any relay");
      }
      
      // Generate the formatted invite link
      final inviteLink = 'holis.is/c/$inviteCode';
      
      log("Invite link generated: $inviteLink", name: 'CreateCommunityController');
      return inviteLink;
    } catch (e, stackTrace) {
      log("Error generating invite link: ${e.toString()}", 
        level: Level.SEVERE.value, name: 'CreateCommunityController');
      log(stackTrace.toString(), level: Level.SEVERE.value, name: 'CreateCommunityController');
      rethrow; // Re-throw to be caught by the caller
    }
  }
}

final createCommunityControllerProvider = AsyncNotifierProvider.autoDispose<
    CreateCommunityController,
    CreateCommunityModel?>(CreateCommunityController.new);
