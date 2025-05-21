import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    // The internal format is kept for deep linking but we display web format in UI
    return 'holis.is/c/$inviteCode';
  }
}

/// A provider that supplies an instance of `GroupInviteRepository`.
final groupInviteRepositoryProvider = Provider<GroupInviteRepository>((ref) {
  final repository = GroupInviteRepository();
  return repository;
});
