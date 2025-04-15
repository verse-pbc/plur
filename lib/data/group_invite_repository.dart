import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../main.dart';
import '../provider/relay_provider.dart';

class GroupInviteRepository {
  /// Name used when logging.
  static const _logName = "GroupInviteRepository";

  static const _defaultRelay = RelayProvider.defaultGroupsRelayAddress;

  Future<String> createInviteLink(
    GroupIdentifier group,
    String inviteCode, {
    List<String>? roles,
  }) async {
    final tags = [
      ["h", group.groupId],
      ["code", inviteCode]
    ];

    // Add roles if provided, default to "member"
    if (roles != null && roles.isNotEmpty) {
      tags.add(["roles", ...roles]);
    } else {
      tags.add(["roles", "member"]);
    }

    final inviteEvent = Event(
      nostr!.publicKey,
      EventKind.groupCreateInvite,
      tags,
      "", // Empty content as per example
    );

    await nostr!.sendEvent(
      inviteEvent,
      tempRelays: [group.host],
      targetRelays: [group.host],
    );

    // Return the formatted invite link
    return 'plur://join-community?group-id=${group.groupId}&code=$inviteCode';
  }

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

/// A provider that supplies an instance of `GroupInviteRepository`.
final groupInviteRepositoryProvider = Provider<GroupInviteRepository>((ref) {
  final repository = GroupInviteRepository();
  return repository;
});
