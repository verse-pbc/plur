import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:rxdart/rxdart.dart';

import '../main.dart';
import '../provider/relay_provider.dart';
import '../util/time_util.dart';
import 'group_metadata_repository.dart';

/// List of [GroupIdentifier] objects.
typedef GroupIdentifiers = List<GroupIdentifier>;

class GroupIdentifierRepository {
  /// Name used when logging.
  static const _logName = "GroupIdentifierRepository";

  static const _defaultRelay = RelayProvider.defaultGroupsRelayAddress;

  final _groupIdentifiers = BehaviorSubject<GroupIdentifiers>();

  Stream<GroupIdentifiers> watchGroupIdentifierList() {
    return _groupIdentifiers.stream;
  }

  void dispose() => _groupIdentifiers.close();

  Future<void> _fetchInitialListOfGroupIdentifiers() async {
    final groupIdentifiersInList = await _fetchGroupIdentifiersFromGroupList();
    log(
      "Received group list\n${groupIdentifiersInList.toString()}",
      level: Level.FINE.value,
      name: _logName,
    );
    _groupIdentifiers.add(groupIdentifiersInList);
    final groupIdentifiersInRelays = await _fetchGroupIdentifiersFromRelays();
    log(
      "Received groups from relays\n${groupIdentifiersInRelays.toString()}",
      level: Level.FINE.value,
      name: _logName,
    );
    final newGroupIdentifiers = GroupIdentifiers.from(groupIdentifiersInList);
    newGroupIdentifiers.retainWhere(
      (e) => groupIdentifiersInRelays.contains(e),
    );
    newGroupIdentifiers.addAll(groupIdentifiersInRelays.where(
      (e) => !groupIdentifiersInList.contains(e),
    ));
    log(
      "Setting initial list of groups...\n${newGroupIdentifiers.toString()}",
      level: Level.FINE.value,
      name: _logName,
    );
    _groupIdentifiers.add(newGroupIdentifiers);
  }

  Future<GroupIdentifiers> _fetchGroupIdentifiersFromGroupList() async {
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
    // If there's no group list event yet (first time user), just return an empty list
    if (events == null || events.isEmpty) {
      log("No group list event found - this may be a new user", name: _logName);
      return [];
    }
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

  Future<GroupIdentifiers> _fetchGroupIdentifiersFromRelays() async {
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
    var eventBox = EventMemBox(sortAfterAdd: false);
    var completer = Completer();
    nostr!.query(
      filters,
      tempRelays: [_defaultRelay],
      targetRelays: [_defaultRelay],
      relayTypes: RelayType.tempAndLocal,
      sendAfterAuth: true,
      (event) => eventBox.add(event),
      onComplete: () => completer.complete(),
    );
    await completer.future;
    final events = eventBox.all();
    GroupIdentifiers groupIdentifiersInRelays = [];
    for (var event in events) {
      final ids = _extractGroupIdentifiersFromTags(event, tagPrefix: "d");
      for (var x in ids) {
        if (groupIdentifiersInRelays.contains(x)) continue;
        groupIdentifiersInRelays.add(x);
      }
    }
    return groupIdentifiersInRelays;
  }

  void _subscribeToNewUpdates(GroupMetadataRepository groupMetadataRepository) {
    // Get current timestamp to only receive events from now onwards.
    final since = currentUnixTimestamp();
    final filters = [
      {
        // Listen for communities where user is a member
        "kinds": [EventKind.groupMembers],
        "#p": [nostr!.publicKey],
        "since": since,
      },
      {
        // Listen for communities where user is an admin
        "kinds": [EventKind.groupAdmins],
        "#p": [nostr!.publicKey],
        "since": since,
      },
      {
        // Listen for community deletions
        "kinds": [EventKind.groupDeleteGroup],
        "since": since,
      },
      {
        // Listen for community metadata edits
        "kinds": [EventKind.groupEditMetadata],
        "since": since,
      }
    ];
    final subscribeId = StringUtil.rndNameStr(16);
    nostr!.subscribe(
      filters,
      (event) => Future.microtask(
        () => _handleSubscriptionEvent(
          event,
          groupMetadataRepository,
        ),
      ),
      id: subscribeId,
      tempRelays: [RelayProvider.defaultGroupsRelayAddress],
      targetRelays: [RelayProvider.defaultGroupsRelayAddress],
      relayTypes: RelayType.onlyTemp,
      sendAfterAuth: true,
    );
  }

  void _handleSubscriptionEvent(
    Event event,
    GroupMetadataRepository groupMetadataRepository,
  ) async {
    log(
      "Received event\n${event.toJson()}",
      level: Level.FINE.value,
      name: _logName,
    );
    final current = _groupIdentifiers.value;
    final updated = GroupIdentifiers.from(current);
    switch (event.kind) {
      case EventKind.groupDeleteGroup:
        final parsed = _extractGroupIdentifiersFromTags(
          event,
          tagPrefix: "h",
        );
        updated.removeWhere((e) => parsed.contains(e));
      case EventKind.groupMembers || EventKind.groupAdmins:
        final parsed = _extractGroupIdentifiersFromTags(
          event,
          tagPrefix: "d",
        );
        for (var groupIdentifier in parsed) {
          if (updated.contains(groupIdentifier)) continue;
          updated.add(groupIdentifier);
        }
      case EventKind.groupEditMetadata:
        final parsed = _extractGroupIdentifiersFromTags(
          event,
          tagPrefix: "h",
        );
        for (var groupIdentifier in parsed) {
          await groupMetadataRepository.fetchGroupMetadata(groupIdentifier);
        }
    }
    _groupIdentifiers.add(updated);
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
  final repository = GroupIdentifierRepository();
  final groupMetadataRepository = ref.watch(groupMetadataRepositoryProvider);
  Future.microtask(() async {
    await repository._fetchInitialListOfGroupIdentifiers();
    repository._subscribeToNewUpdates(groupMetadataRepository);
  });
  ref.onDispose(() => repository.dispose());
  return repository;
});

/// A provider that fetches group identifiers and handles their disposal.
final groupIdentifiersProvider = StreamProvider<GroupIdentifiers>((ref) {
  final repository = ref.watch(groupIdentifierRepositoryProvider);
  return repository.watchGroupIdentifierList();
});
