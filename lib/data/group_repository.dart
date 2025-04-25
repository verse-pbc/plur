import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../main.dart';
import '../provider/relay_provider.dart';

/// Repository for managing group-related operations.
///
/// This class provides methods to create groups, leave groups, generate invite
/// links, and accept invite links. It interacts with relays to perform these
/// operations.
class GroupRepository {
  /// Name used when logging.
  static const _logName = "GroupRepository";

  /// Default relay address for group-related operations.
  static const _defaultRelay = RelayProvider.defaultGroupsRelayAddress;

  /// Creates a new group with the specified [groupId].
  ///
  /// Sends an event to the relay to create a private closed group. Returns
  /// a [GroupIdentifier] if the group creation succeeds, otherwise returns `null`.
  Future<GroupIdentifier?> createGroup(String groupId) async {
    final createGroupEvent = Event(
      nostr!.publicKey,
      EventKind.groupCreateGroup,
      [
        ["h", groupId]
      ],
      "",
    );
    const host = _defaultRelay;
    log(
      "Creating group $groupId in $host...\n$createGroupEvent",
      level: Level.FINE.value,
      name: _logName,
    );
    final resultEvent = await nostr!.sendEvent(
      createGroupEvent,
      tempRelays: [host],
      targetRelays: [host],
    );
    final result = resultEvent != null;
    log(
      "Group $groupId in $host created: $result",
      level: Level.INFO.value,
      name: _logName,
    );
    if (result) {
      return GroupIdentifier(host, groupId);
    } else {
      return null;
    }
  }

  /// Leaves the specified group.
  ///
  /// Sends an event to the relay to leave the group identified by
  /// [groupIdentifier]. Returns `true` if the operation succeeds, otherwise `false`.
  Future<bool> leaveGroup(GroupIdentifier groupIdentifier) async {
    final groupId = groupIdentifier.groupId;
    final leaveGroupEvent = Event(
      nostr!.publicKey,
      EventKind.groupLeave,
      [
        ["h", groupId]
      ],
      "",
    );
    final host = groupIdentifier.host;
    log(
      "Leaving group $groupId in $host...\n$leaveGroupEvent",
      level: Level.FINE.value,
      name: _logName,
    );
    final resultEvent = await nostr!.sendEvent(
      leaveGroupEvent,
      tempRelays: [host],
      targetRelays: [host],
    );
    final result = resultEvent != null;
    log(
      "Group $groupId in $host left: $result",
      level: Level.INFO.value,
      name: _logName,
    );
    return result;
  }

  /// Creates an invite link for the specified group.
  ///
  /// Generates an invite link for the group identified by [group]. The
  /// [inviteCode] is used as the unique code for the invite. Optionally,
  /// [roles] can be specified to assign roles to the invitee. Returns the
  /// formatted invite link as a string.
  Future<String> createInviteLink(
    GroupIdentifier group,
    String inviteCode, {
    List<String>? roles,
  }) async {
    final tags = [
      ["h", group.groupId],
      ["code", inviteCode],
      ["reusable"]
    ];
    if (roles != null && roles.isNotEmpty) {
      tags.add(["roles", ...roles]);
    } else {
      tags.add(["roles", "member"]);
    }
    final inviteEvent = Event(
      nostr!.publicKey,
      EventKind.groupCreateInvite,
      tags,
      "",
    );
    await nostr!.sendEvent(
      inviteEvent,
      tempRelays: [group.host],
      targetRelays: [group.host],
    );
    return 'plur://join-community?group-id=${group.groupId}&code=$inviteCode';
  }

  /// Accepts an invite link to join a group.
  ///
  /// Sends an event to the relay to join the group identified by
  /// [groupIdentifier]. Optionally, a [code] can be provided to redeem
  /// the invite. Returns `true` if the invite is successfully redeemed,
  /// otherwise `false`.
  Future<bool> acceptInviteLink(
    GroupIdentifier groupIdentifier, {
    String? code,
  }) async {
    final groupId = groupIdentifier.groupId;
    final List<List<String>> eventTags = [
      ["h", groupId]
    ];
    if (code != null) {
      eventTags.add(["code", code]);
    }
    final event = Event(nostr!.publicKey, EventKind.groupJoin, eventTags, "");
    final host = groupIdentifier.host;
    final relays = [host];
    log(
      "Reedeming invite to $groupId in $host...\nCode: $code",
      level: Level.FINE.value,
      name: _logName,
    );
    final result = await nostr!.sendEvent(
      event,
      tempRelays: relays,
      targetRelays: relays,
    );
    final acceptedInvite = result != null;
    log(
      "Invite to $groupId in $host redeemed: $acceptedInvite",
      level: Level.INFO.value,
      name: _logName,
    );
    return acceptedInvite;
  }
}

/// A provider that supplies an instance of `GroupRepository`.
final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  final repository = GroupRepository();
  return repository;
});
