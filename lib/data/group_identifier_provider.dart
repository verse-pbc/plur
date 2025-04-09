import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../main.dart';
import '../provider/relay_provider.dart';

/// List of [GroupIdentifier] objects.
typedef GroupIdentifiers = List<GroupIdentifier>;

class GroupIdentifierRepository {
  /// Name used when logging.
  static const _logName = "GroupIdentifierRepository";

  static const _defaultRelay = RelayProvider.defaultGroupsRelayAddress;

  Future<GroupIdentifiers> fetchGroupIdentifierList() async {
    Filter filter = Filter();
    filter.kinds = [EventKind.groupList];
    filter.authors = [nostr!.publicKey];
    filter.limit = 1;

    final filters = [filter.toJson()];

    final events = await nostr?.queryEvents(
      filters,
      tempRelays: [_defaultRelay],
      targetRelays: [_defaultRelay],
      relayTypes: RelayType.tempAndLocal,
      sendAfterAuth: true,
    );
    assert(events?.length == 1, "Didn't receive a group list");
    final event = events?.firstOrNull;
    if (event == null) {
      return [];
    }
    GroupIdentifiers groupIdentifiers = [];
    for (var tag in event.tags) {
      if (tag is List && tag.length > 2) {
        var k = tag[0];
        var groupId = tag[1];
        var host = tag[2];
        if (k == "group") {
          var groupIdentifier = GroupIdentifier(host, groupId);
          groupIdentifiers.add(groupIdentifier);
        }
      }
    }
    return groupIdentifiers;
  }

  GroupIdentifiers _cachedGroupIdentifiers = [];

  Stream<GroupIdentifiers> watchGroupIdentifierList() async* {
    _cachedGroupIdentifiers = await fetchGroupIdentifierList();
    final filters = [
      {
        // Get groups where user is a member
        "kinds": [EventKind.groupMembers],
        "#p": [nostr!.publicKey],
      },
      {
        // Get groups where user is an admin
        "kinds": [EventKind.groupAdmins],
        "#p": [nostr!.publicKey],
      }
    ];
    nostr!.query(
      filters,
      (Event event) {
        final ids = _extractGroupIdentifiersFromTags(event, tagPrefix: "d");
        for (var x in ids) {
          _cachedGroupIdentifiers.add(x);
        }
      },
      tempRelays: [RelayProvider.defaultGroupsRelayAddress],
      targetRelays: [RelayProvider.defaultGroupsRelayAddress],
      relayTypes: RelayType.onlyTemp,
      sendAfterAuth: true,
    );
   yield _cachedGroupIdentifiers; 
  }

  /// Extracts group identifiers from event tags with specified prefix ("h" or
  /// "d").
  GroupIdentifiers _extractGroupIdentifiersFromTags(
    Event event, {
    required String tagPrefix,
  }) {
    return event.tags
        .where((tag) => tag is List && tag.length > 1 && tag[0] == tagPrefix)
        .map((tag) => GroupIdentifier(_defaultRelay, tag[1]))
        .toList();
  }
}

/// A provider that supplies an instance of `GroupIdentifierRepository`.
final groupIdentifierRepositoryProvider =
    Provider<GroupIdentifierRepository>((ref) {
  return GroupIdentifierRepository();
});

/// A provider that fetches group identifiers and handles their disposal.
final groupIdentifiersProvider =
    FutureProvider.autoDispose<GroupIdentifiers>((ref) {
  final repository = ref.watch(groupIdentifierRepositoryProvider);
  return repository.fetchGroupIdentifierList();
});

/// A provider that fetches group identifiers and handles their disposal.
final groupIdentifiersStreamProvider =
    StreamProvider.autoDispose<Stream<GroupIdentifiers>>((ref) async* {
  final repository = ref.watch(groupIdentifierRepositoryProvider);
  yield repository.watchGroupIdentifierList();
});

