import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/app_logger.dart';
import 'package:nostrmo/util/moderation_dm_util.dart';
// Sentry has been removed

class GroupProvider extends ChangeNotifier with LaterFunction {
  Map<String, GroupMetadata> groupMetadatas = {};

  Map<String, GroupAdmins> groupAdmins = {};

  Map<String, GroupMembers> groupMembers = {};
  
  // Track pending invites: map of group key to list of invite events
  Map<String, List<Event>> pendingInvites = {};

  final Map<String, int> _handlingMetadataIds = {};

  final Map<String, int> _handlingAdminsIds = {};

  final Map<String, int> _handlingMembersIds = {};
  
  final Map<String, int> _handlingInviteIds = {};

  int now() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  void _markHandling(GroupIdentifier groupIdentifier) {
    var key = groupIdentifier.toString();
    var t = now();

    _handlingMetadataIds[key] = t;
    _handlingAdminsIds[key] = t;
    _handlingMembersIds[key] = t;
    _handlingInviteIds[key] = t;
  }

  void deleteEvent(GroupIdentifier groupIdentifier, String eventId) {
    NIP29.deleteEvent(nostr!, groupIdentifier, eventId);
  }

  void editStatus(GroupIdentifier groupIdentifier, bool? public, bool? open) {
    NIP29.editStatus(nostr!, groupIdentifier, public, open);
  }

  /// Removes a post from a group as a moderator/admin
  /// 
  /// Creates and sends a moderation event to remove the specified post from 
  /// the group view. Only admins should be able to perform this action.
  /// 
  /// @param groupIdentifier The group identifier
  /// @param postId The ID of the post to remove
  /// @param reason Optional reason for removal
  /// @return A Future<bool> that resolves to true if the event was sent successfully
  Future<bool> removePost(GroupIdentifier groupIdentifier, String postId, {String? reason}) async {
    logger.i('REMOVE DEBUG: Starting removePost in GroupProvider', null, null, LogCategory.groups);
    logger.i('REMOVE DEBUG: Group: ${groupIdentifier.host}/${groupIdentifier.groupId}', null, null, LogCategory.groups);
    logger.i('REMOVE DEBUG: Post ID: $postId', null, null, LogCategory.groups);
    if (reason != null) {
      logger.d('REMOVE DEBUG: Removal reason: $reason', null, null, LogCategory.groups);
    }
    
    // Before sending, verify that the current user is an admin of this group
    var key = groupIdentifier.toString();
    var admins = groupAdmins[key];
    var isAdmin = false;
    
    if (admins != null && nostr != null) {
      isAdmin = admins.containsUser(nostr!.publicKey);
      logger.i('REMOVE DEBUG: Admin check for user ${nostr!.publicKey.substring(0, 8)}... result: $isAdmin', null, null, LogCategory.groups);
    } else {
      logger.w('REMOVE DEBUG: No admin data for this group or nostr is null', null, null, LogCategory.groups);
      if (admins == null) {
        logger.w('REMOVE DEBUG: No admin data loaded for group $key', null, null, LogCategory.groups);
      }
      if (nostr == null) {
        logger.w('REMOVE DEBUG: Nostr SDK instance is null', null, null, LogCategory.groups);
      }
    }
    
    if (!isAdmin) {
      logger.w('REMOVE DEBUG: User is not an admin of this group - cannot remove post', null, null, LogCategory.groups);
      return false;
    }
    
    // Send the moderation event
    try {
      var result = await NIP29.removePost(nostr!, groupIdentifier, postId, reason: reason);
      
      if (result != null) {
        logger.i('REMOVE DEBUG: Post removal event sent successfully with ID: ${result.id}', null, null, LogCategory.groups);
        
        // Give time for relay propagation
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Force refresh
        _markHandling(groupIdentifier);
        
        // Notify listeners
        notifyListeners();
        
        return true;
      } else {
        logger.e('REMOVE DEBUG: Failed to send post removal event', null, null, LogCategory.groups);
        return false;
      }
    } catch (e, st) {
      logger.e('REMOVE DEBUG: Exception during post removal: $e', st, null, LogCategory.groups);
      return false;
    }
  }

  /// Removes a user from a group (admin only)
  /// 
  /// Creates and sends a moderation event to remove the specified user from the group.
  /// Only admins can perform this action.
  /// Optionally sends a notification DM to the removed user.
  /// 
  /// @param groupIdentifier The group identifier
  /// @param userPubkey The pubkey of the user to remove
  /// @param reason Optional reason for removal
  /// @param sendNotification Whether to send a DM notification to the user
  /// @return A Future<bool> that resolves to true if the user was successfully removed
  Future<bool> removeUser(GroupIdentifier groupIdentifier, String userPubkey, {
    String? reason,
    bool sendNotification = true
  }) async {
    logger.i('REMOVE USER: Starting removeUser in GroupProvider', null, null, LogCategory.groups);
    logger.i('REMOVE USER: Group: ${groupIdentifier.host}/${groupIdentifier.groupId}', null, null, LogCategory.groups);
    logger.i('REMOVE USER: User: ${userPubkey.substring(0, 8)}...', null, null, LogCategory.groups);
    if (reason != null) {
      logger.d('REMOVE USER: Removal reason: $reason', null, null, LogCategory.groups);
    }
    
    // Verify that the current user is an admin of this group
    var key = groupIdentifier.toString();
    var admins = groupAdmins[key];
    var isAdmin = false;
    
    if (admins != null && nostr != null) {
      isAdmin = admins.containsUser(nostr!.publicKey);
      logger.i('REMOVE USER: Admin check for user ${nostr!.publicKey.substring(0, 8)}... result: $isAdmin', null, null, LogCategory.groups);
    } else {
      logger.w('REMOVE USER: No admin data for this group or nostr is null', null, null, LogCategory.groups);
      if (admins == null) {
        logger.w('REMOVE USER: No admin data loaded for group $key', null, null, LogCategory.groups);
      }
      if (nostr == null) {
        logger.w('REMOVE USER: Nostr SDK instance is null', null, null, LogCategory.groups);
      }
    }
    
    if (!isAdmin) {
      logger.w('REMOVE USER: User is not an admin of this group - cannot remove user', null, null, LogCategory.groups);
      return false;
    }
    
    // Don't allow removing self
    if (nostr!.publicKey == userPubkey) {
      logger.w('REMOVE USER: Cannot remove yourself from the group', null, null, LogCategory.groups);
      return false;
    }
    
    // Send the moderation event
    try {
      var result = await NIP29.removeUser(nostr!, groupIdentifier, userPubkey, reason: reason);
      
      if (result != null) {
        logger.i('REMOVE USER: User removal event sent successfully with ID: ${result.id}', null, null, LogCategory.groups);
        
        // Send notification DM if requested
        if (sendNotification) {
          try {
            final dmSent = await ModerationDmUtil.sendRemovalNotification(
              userPubkey,
              groupIdentifier,
              reason: reason,
              adminPubkey: nostr!.publicKey
            );
            
            if (dmSent) {
              logger.i('REMOVE USER: Notification DM sent successfully', null, null, LogCategory.groups);
            } else {
              logger.w('REMOVE USER: Failed to send notification DM', null, null, LogCategory.groups);
            }
          } catch (dmError) {
            logger.e('REMOVE USER: Error sending notification DM: $dmError', null, null, LogCategory.groups);
            // Continue even if DM fails
          }
        }
        
        // Give time for relay propagation
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Force refresh
        _markHandling(groupIdentifier);
        
        // Notify listeners
        notifyListeners();
        
        return true;
      } else {
        logger.e('REMOVE USER: Failed to send user removal event', null, null, LogCategory.groups);
        return false;
      }
    } catch (e, st) {
      logger.e('REMOVE USER: Exception during user removal: $e', st, null, LogCategory.groups);
      return false;
    }
  }

  /// Ban a user from a group
  /// 
  /// This bans a user from a group by publishing a moderation event
  /// Only group admins can ban users
  /// 
  /// @param groupIdentifier The group identifier
  /// @param userPubkey The pubkey of the user to ban
  /// @param reason Optional reason for ban
  /// @param duration Optional ban duration in seconds (for temporary bans)
  /// @param sendNotification Whether to send a DM notification to the user
  /// @return A Future<bool> that resolves to true if the user was successfully banned
  Future<bool> banUser(GroupIdentifier groupIdentifier, String userPubkey, {
    String? reason,
    int? duration,
    bool sendNotification = true
  }) async {
    logger.i('BAN USER: Starting banUser in GroupProvider', null, null, LogCategory.groups);
    logger.i('BAN USER: Group: ${groupIdentifier.host}/${groupIdentifier.groupId}', null, null, LogCategory.groups);
    logger.i('BAN USER: User: ${userPubkey.substring(0, 8)}...', null, null, LogCategory.groups);
    if (reason != null) {
      logger.d('BAN USER: Ban reason: $reason', null, null, LogCategory.groups);
    }
    if (duration != null) {
      logger.d('BAN USER: Ban duration: $duration seconds', null, null, LogCategory.groups);
    }
    
    // Verify that the current user is an admin of this group
    var key = groupIdentifier.toString();
    var admins = groupAdmins[key];
    var isAdmin = false;
    
    if (admins != null && nostr != null) {
      isAdmin = admins.containsUser(nostr!.publicKey);
      logger.i('BAN USER: Admin check for user ${nostr!.publicKey.substring(0, 8)}... result: $isAdmin', null, null, LogCategory.groups);
    } else {
      logger.w('BAN USER: No admin data for this group or nostr is null', null, null, LogCategory.groups);
      if (admins == null) {
        logger.w('BAN USER: No admin data loaded for group $key', null, null, LogCategory.groups);
      }
      if (nostr == null) {
        logger.w('BAN USER: Nostr SDK instance is null', null, null, LogCategory.groups);
      }
    }
    
    if (!isAdmin) {
      logger.w('BAN USER: User is not an admin of this group - cannot ban user', null, null, LogCategory.groups);
      return false;
    }
    
    // Don't allow banning self
    if (nostr!.publicKey == userPubkey) {
      logger.w('BAN USER: Cannot ban yourself from the group', null, null, LogCategory.groups);
      return false;
    }
    
    // Send the ban event
    try {
      var result = await NIP29.banUser(nostr!, groupIdentifier, userPubkey, 
          reason: reason, duration: duration);
      
      if (result != null) {
        logger.i('BAN USER: User ban event sent successfully with ID: ${result.id}', null, null, LogCategory.groups);
        
        // Send notification DM if requested
        if (sendNotification) {
          try {
            final banType = duration != null ? "temporarily banned" : "permanently banned";
            final durationText = duration != null 
                ? formatDuration(duration) 
                : "permanently";
            
            final banMessage = "You have been $banType from group \"${getGroupName(groupIdentifier)}\" $durationText.";
            final subject = "Group Ban Notification";
            
            final dmSent = await ModerationDmUtil.sendModerationMessage(
              userPubkey,
              groupIdentifier,
              subject,
              banMessage + (reason != null ? "\n\nReason: $reason" : "")
            );
            
            if (dmSent) {
              logger.i('BAN USER: Notification DM sent successfully', null, null, LogCategory.groups);
            } else {
              logger.w('BAN USER: Failed to send notification DM', null, null, LogCategory.groups);
            }
          } catch (dmError) {
            logger.e('BAN USER: Error sending notification DM: $dmError', null, null, LogCategory.groups);
            // Continue even if DM fails
          }
        }
        
        // Give time for relay propagation
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Force refresh
        _markHandling(groupIdentifier);
        
        // Notify listeners
        notifyListeners();
        
        return true;
      } else {
        logger.e('BAN USER: Failed to send user ban event', null, null, LogCategory.groups);
        return false;
      }
    } catch (e, st) {
      logger.e('BAN USER: Exception during user ban: $e', st, null, LogCategory.groups);
      return false;
    }
  }

  /// Helper method to format duration in a human-readable way
  String formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds seconds';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '$minutes minute${minutes == 1 ? '' : 's'}';
    } else if (seconds < 86400) {
      final hours = seconds ~/ 3600;
      return '$hours hour${hours == 1 ? '' : 's'}';
    } else {
      final days = seconds ~/ 86400;
      return '$days day${days == 1 ? '' : 's'}';
    }
  }

  /// Helper method to get group name
  String getGroupName(GroupIdentifier groupIdentifier) {
    final metadata = getMetadata(groupIdentifier);
    return metadata?.name ?? groupIdentifier.groupId;
  }

  GroupMetadata? getMetadata(GroupIdentifier groupIdentifier) {
    var key = groupIdentifier.toString();
    var m = groupMetadatas[key];
    if (m != null) {
      return m;
    }

    var ot = _handlingMetadataIds[key];
    if (ot == null || now() - ot > 60 * 5) {
      _markHandling(groupIdentifier);
      query(groupIdentifier);
    }
    return null;
  }

  GroupAdmins? getAdmins(GroupIdentifier groupIdentifier) {
    var key = groupIdentifier.toString();
    var m = groupAdmins[key];
    if (m != null) {
      return m;
    }

    var ot = _handlingAdminsIds[key];
    if (ot == null || now() - ot > 60 * 5) {
      _markHandling(groupIdentifier);
      query(groupIdentifier);
    }
    return null;
  }

  bool isAdmin(String pubkey, GroupIdentifier groupIdentifier) {
    final admins = getAdmins(groupIdentifier);
    return admins?.containsUser(pubkey) ?? false;
  }

  /// Get all groups where the given user is an admin
  List<GroupIdentifier> getAdminGroups(String pubkey) {
    final adminGroups = <GroupIdentifier>[];
    
    logger.d("getAdminGroups for pubkey ${pubkey.substring(0, 8)}... (${groupAdmins.length} admin groups cached)", 
        LogCategory.groups);
    
    // Check each group where we have admin information
    groupAdmins.forEach((key, admins) {
      final containsUser = admins.containsUser(pubkey);
      logger.d("Checking admin status for group key $key: $containsUser", LogCategory.groups);
      
      if (containsUser) {
        // The key is in the format "relay/groupId", so we need to parse it
        final parts = key.split('/');
        if (parts.length == 2) {
          final host = parts[0];
          final groupId = parts[1];
          adminGroups.add(GroupIdentifier(host, groupId));
        }
      }
    });
    
    logger.d("Found ${adminGroups.length} admin groups for user ${pubkey.substring(0, 8)}...", 
        LogCategory.groups);
    return adminGroups;
  }

  /// Check if a user is an admin of any group
  bool isAdminOfAnyGroup(String pubkey) {
    return getAdminGroups(pubkey).isNotEmpty;
  }

  GroupMembers? getMembers(GroupIdentifier groupIdentifier) {
    var key = groupIdentifier.toString();
    var m = groupMembers[key];
    if (m != null) {
      return m;
    }

    var ot = _handlingMembersIds[key];
    if (ot == null || now() - ot > 60 * 5) {
      _markHandling(groupIdentifier);
      query(groupIdentifier);
    }
    return null;
  }

  int getMemberCount(GroupIdentifier groupIdentifier) =>
      getMembers(groupIdentifier)?.members?.length ?? 0;
      
  // Pending invite methods
  
  /// Extract invite details from an event
  (String, List<String>) getInviteDetails(Event inviteEvent) {
    String inviteCode = "";
    List<String> roles = ["member"];
    
    for (final tag in inviteEvent.tags) {
      if (tag.length > 1) {
        if (tag[0] == "code") {
          inviteCode = tag[1].toString();
        } else if (tag[0] == "roles" && tag.length > 1) {
          roles = tag.sublist(1).map((role) => role.toString()).toList().cast<String>();
        }
      }
    }
    
    return (inviteCode, roles);
  }
      
  /// Returns the list of pending invite events for a group
  List<Event> getPendingInvites(GroupIdentifier groupIdentifier) {
    var key = groupIdentifier.toString();
    var invites = pendingInvites[key];
    if (invites != null) {
      return invites;
    }
    
    // If no pending invites cached, return empty list for now
    // In a real implementation, this would query the relay for invite events
    return [];
  }
  
  /// Get the count of pending invites for a group
  int getPendingInviteCount(GroupIdentifier groupIdentifier) =>
      getPendingInvites(groupIdentifier).length;

  void _updateMember(GroupIdentifier groupIdentifier) {
    var membersJsonMap =
        genFilter(groupIdentifier.groupId, EventKind.groupMembers);

    nostr!.query(
      [membersJsonMap],
      (e) {
        onEvent(groupIdentifier, e);
      },
      tempRelays: [groupIdentifier.host],
      relayTypes: RelayType.onlyTemp,
    );
  }

  void addMember(GroupIdentifier groupIdentifier, String pubkey) {
    NIP29.addMember(nostr!, groupIdentifier, pubkey);

    // try to add to mem
    var key = groupIdentifier.toString();
    var members = groupMembers[key];
    if (members != null) {
      members.add(pubkey);
    }

    _updateMember(groupIdentifier);

    notifyListeners();
  }

  Future<void> removeMember(
      GroupIdentifier groupIdentifier, String pubkey) async {
    NIP29.removeMember(nostr!, groupIdentifier, pubkey);

    // try to delete from mem
    var key = groupIdentifier.toString();
    var members = groupMembers[key];
    if (members != null) {
      members.remove(pubkey);
    }

    _updateMember(groupIdentifier);

    notifyListeners();
  }

  /// Returns a [Filter] object that can be used to query events with kind
  /// [eventKind] relevante to group [groupId] from relays.
  @visibleForTesting
  Map<String, dynamic> genFilter(String groupId, int eventKind) {
    var filter = Filter(
      kinds: [eventKind],
    );
    var jsonMap = filter.toJson();
    jsonMap["#d"] = [groupId];
    return jsonMap;
  }

  /// Query metadata, admin list, and member list, from group [groupIdentifier]
  /// from the network.
  void query(GroupIdentifier groupIdentifier) {
    final groupId = groupIdentifier.groupId;
    final host = groupIdentifier.host;
    var metadataJsonMap = genFilter(groupId, EventKind.groupMetadata);
    var adminsJsonMap = genFilter(groupId, EventKind.groupAdmins);
    var membersJsonMap = genFilter(groupId, EventKind.groupMembers);
    final filters = [metadataJsonMap, adminsJsonMap, membersJsonMap];
    if (nostr == null) {
      logger.w("nostr is null");
      return;
    }
    nostr!.query(
      filters,
      (e) => onEvent(groupIdentifier, e),
      tempRelays: [host],
      targetRelays: [host],
      relayTypes: RelayType.tempAndLocal,
      sendAfterAuth: true,
    );
    
    // Also query for pending invites
    queryInvites(groupIdentifier);
  }
  
  /// Query for pending invites for this group
  void queryInvites(GroupIdentifier groupIdentifier) {
    final groupId = groupIdentifier.groupId;
    final host = groupIdentifier.host;
    
    // Filter to get all group create invite events for this group
    final filter = Filter(
      kinds: [EventKind.groupCreateInvite],
      authors: [nostr!.publicKey], // Only get invites created by the current user
    );
    final filterMap = filter.toJson();
    filterMap["#h"] = [groupId]; // Filter for our group ID in the "h" tag
    
    if (nostr == null) {
      logger.w("nostr is null");
      return;
    }
    
    nostr!.query(
      [filterMap],
      (e) => onInviteEvent(groupIdentifier, e),
      tempRelays: [host],
      targetRelays: [host],
      relayTypes: RelayType.tempAndLocal,
      sendAfterAuth: true,
    );
  }

  void onEvent(GroupIdentifier groupIdentifier, Event e) {
    bool updated = false;
    if (e.kind == EventKind.groupMetadata) {
      updated = handleEvent(
          groupMetadatas, groupIdentifier, GroupMetadata.loadFromEvent(e));
    } else if (e.kind == EventKind.groupAdmins) {
      updated = handleEvent(
          groupAdmins, groupIdentifier, GroupAdmins.loadFromEvent(e));
    } else if (e.kind == EventKind.groupMembers) {
      updated = handleEvent(
          groupMembers, groupIdentifier, GroupMembers.loadFromEvent(e));
    } else if (e.kind == EventKind.groupEditMetadata) {
      updated = handleEvent(
          groupMetadatas, groupIdentifier, GroupMetadata.loadFromEvent(e));
    } else if (e.kind == EventKind.groupCreateInvite) {
      updated = handleInviteEvent(groupIdentifier, e);
    }

    if (updated) {
      notifyListeners();
    }
  }
  
  /// Handler for group invite events
  void onInviteEvent(GroupIdentifier groupIdentifier, Event e) {
    if (e.kind == EventKind.groupCreateInvite) {
      bool updated = handleInviteEvent(groupIdentifier, e);
      if (updated) {
        notifyListeners();
      }
    }
  }
  
  /// Process invite events and check if they've been accepted
  bool handleInviteEvent(GroupIdentifier groupIdentifier, Event inviteEvent) {
    final groupKey = groupIdentifier.toString();
    
    // Extract the invite code (we'll need it to check if it was accepted)
    String? inviteCode;
    for (var tag in inviteEvent.tags) {
      if (tag is List && tag.length > 1 && tag[0] == "code") {
        inviteCode = tag[1];
        break;
      }
    }
    
    if (inviteCode == null) {
      // Not a valid invite event
      return false;
    }
    
    // Initialize the pending invites list if it doesn't exist for this group
    if (!pendingInvites.containsKey(groupKey)) {
      pendingInvites[groupKey] = [];
    }
    
    // Check if we already have this event
    bool alreadyHave = pendingInvites[groupKey]!.any((e) => e.id == inviteEvent.id);
    if (alreadyHave) {
      return false;
    }
    
    // Add the invite event to our list
    pendingInvites[groupKey]!.add(inviteEvent);
    return true;
  }
  
  // Method removed to fix duplicate declaration
  // The getInviteDetails method is already defined at line 102

  /// Updates the given Map with the new data contained in groupIdentifier and
  /// groupObject with some validation to filter out bad data.
  bool handleEvent(
      Map map, GroupIdentifier groupIdentifier, GroupObject? groupObject) {
    var key = groupIdentifier.toString();
    if (groupObject == null) {
      return false;
    }

    if (groupObject.groupId != groupIdentifier.groupId) {
      return false;
    }

    bool updated = false;
    var object = map[key];
    if (object == null) {
      map[key] = groupObject;
      updated = true;
    } else {
      // gets the most recent valid metadata
      if (object is GroupObject && groupObject.createdAt > object.createdAt) {
        map[key] = groupObject;
        updated = true;
      }
    }

    return updated;
  }

  /// Saves group metadata in associated relay.
  Future<void> updateMetadata(
    GroupIdentifier groupIdentifier,
    GroupMetadata groupMetadata,
  ) async {
    var tags = [];
    final name = groupMetadata.name;
    final picture = groupMetadata.picture;
    final about = groupMetadata.about;
    tags.add(["h", groupIdentifier.groupId]);
    if (name != null && name != "") {
      tags.add(["name", name]);
    }
    if (picture != null && picture != "") {
      tags.add(["picture", picture]);
    }
    if (about != null && about != "") {
      tags.add(["about", about]);
    }
    final event = Event(
      nostr!.publicKey,
      EventKind.groupEditMetadata,
      tags,
      ""
    );
    final relays = [groupIdentifier.host];
    final result = await nostr!.sendEvent(
      event,
      tempRelays: relays,
      targetRelays: relays
    );
    if (result != null) {
      handleEvent(
        groupMetadatas,
        groupIdentifier,
        GroupMetadata.loadFromEvent(event),
      );
    }
  }

  /// Force admin access for a particular group (TEMPORARY WORKAROUND)
  /// This is used to fix inconsistencies between isAdmin and getAdminGroups
  void forceAdminForGroup(GroupIdentifier groupIdentifier, String pubkey) {
    final key = groupIdentifier.toString();
    logger.i("FORCE: Setting admin for group $key, user ${pubkey.substring(0, 8)}...", 
             null, null, LogCategory.groups);
    
    // Create or get the GroupAdmins object
    var admins = groupAdmins[key];
    if (admins == null) {
      // Create a new GroupAdmins object with required parameters
      admins = GroupAdmins(groupIdentifier.groupId, 
                         DateTime.now().millisecondsSinceEpoch ~/ 1000, 
                         [GroupAdminUser(pubkey: pubkey, role: "admin")]);
      groupAdmins[key] = admins;
    } else {
      // Check if the user is already an admin
      if (!admins.containsUser(pubkey)) {
        // Create a new GroupAdmins object with the user added
        var updatedUsers = List<GroupAdminUser>.from(admins.users);
        updatedUsers.add(GroupAdminUser(pubkey: pubkey, role: "admin"));
        
        admins = GroupAdmins(groupIdentifier.groupId,
                           DateTime.now().millisecondsSinceEpoch ~/ 1000,
                           updatedUsers);
        groupAdmins[key] = admins;
      }
    }
    
    logger.i("FORCE: Admin set successfully", null, null, LogCategory.groups);
  }

  /// Refresh the data for a specific group
  /// 
  /// This forces a reload of the group's metadata and member information
  /// @param groupIdentifier The group identifier
  Future<void> refreshGroup(GroupIdentifier groupIdentifier) async {
    logger.i("Refreshing group data for ${groupIdentifier.groupId}", LogCategory.groups);
    
    try {
      // Clear cached data for this group
      _handlingMetadataIds.remove(groupIdentifier.toString());
      _handlingAdminsIds.remove(groupIdentifier.toString());
      _handlingMembersIds.remove(groupIdentifier.toString());
      _handlingInviteIds.remove(groupIdentifier.toString());
      
      // Clear any in-memory metadata and members/admins
      groupMetadatas.remove(groupIdentifier.toString());
      groupAdmins.remove(groupIdentifier.toString());
      groupMembers.remove(groupIdentifier.toString());
      
      // Reload the group data
      query(groupIdentifier);
      
      // Notify listeners that data has changed
      notifyListeners();
      logger.i("Group data refreshed for ${groupIdentifier.groupId}", LogCategory.groups);
    } catch (e) {
      logger.e("Error refreshing group data: $e", LogCategory.groups);
    }
  }
}
