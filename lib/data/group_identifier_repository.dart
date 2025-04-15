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

  Future<bool> checkMembership(GroupIdentifier groupIdentifier) async {
    final groupId = groupIdentifier.groupId;
    final filter = Filter(kinds: [EventKind.groupMembers], limit: 1);
    final filterMap = filter.toJson();
    filterMap["#d"] = [groupId];
    final completer = Completer<bool>();
    final host = groupIdentifier.host;
    log(
      "Checking membership of group $groupId in $host...",
      level: Level.FINE.value,
      name: _logName,
    );
    nostr!.query(
      [filterMap],
      (Event event) {
        if (event.kind == EventKind.groupMembers) {
          for (var tag in event.tags) {
            if (tag is List && tag.length > 1) {
              if (tag[0] == "p" && tag[1] == nostr!.publicKey) {
                if (!completer.isCompleted) {
                  completer.complete(true);
                }
                return;
              }
            }
          }
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        }
      },
      tempRelays: [host],
      relayTypes: RelayType.onlyTemp,
      sendAfterAuth: true,
    );
    try {
      final result = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
      log(
        "User is a member of group $groupId: $result",
        level: Level.INFO.value,
        name: _logName,
      );
      return result;
    } catch (error) {
      log(
        "Got error while cheking membership\n${error.toString()}",
        level: Level.WARNING.value,
        name: _logName,
      );
      return false;
    }
  }

  /// Creates a group and adds it to the group list
  Future<GroupIdentifier?> createGroupIdentifier(String groupId) async {
    const host = _defaultRelay;

    // Create the event for creating a group.
    // We only support private closed group for now.
    final createGroupEvent = Event(
      nostr!.publicKey,
      EventKind.groupCreateGroup,
      [
        ["h", groupId]
      ],
      "",
    );

    final resultEvent = await nostr!.sendEvent(
      createGroupEvent,
      tempRelays: [host],
      targetRelays: [host],
    );

    if (resultEvent == null) {
      return null;
    }

    final groupIdentifier = GroupIdentifier(host, groupId);
    await addGroupIdentifier(groupIdentifier);
    return groupIdentifier;
  }

  /// Adds a group to the group list
  Future<void> addGroupIdentifier(GroupIdentifier groupIdentifier) async {
    // Update the cached stream
    List<GroupIdentifier> updated = List.from(_groupIdentifiers.value);
    if (!updated.contains(groupIdentifier)) {
      updated.add(groupIdentifier);
      _groupIdentifiers.add(updated);
    }
    // Update the remote group list
    final currentGroupList = await _fetchGroupList();
    GroupIdentifiers updatedGroupList = List.from(currentGroupList);
    if (!updatedGroupList.contains(groupIdentifier)) {
      updatedGroupList.add(groupIdentifier);
      await _setGroupList(updatedGroupList);
    }
  }

  Future<void> removeGroupIdentifier(GroupIdentifier groupIdentifier) async {
    final groupId = groupIdentifier.groupId;
    final event = Event(
      nostr!.publicKey,
      EventKind.groupLeave,
      [
        ["h", groupId]
      ],
      "",
    );
    final host = groupIdentifier.host;
    await nostr!.sendEvent(event, tempRelays: [host], targetRelays: [host]);
    List<GroupIdentifier> updated = List.from(_groupIdentifiers.value);
    if (updated.contains(groupIdentifier)) {
      updated.remove(groupIdentifier);
      _groupIdentifiers.add(updated);
    }
    final groupIdentifiersInList = await _fetchGroupList();
    GroupIdentifiers updatedList = List.from(groupIdentifiersInList);
    if (updatedList.contains(groupIdentifier)) {
      updatedList.remove(groupIdentifier);
      await _setGroupList(updatedList);
    }
  }

  void dispose() => _groupIdentifiers.close();

  Future<void> _fetchInitialListOfGroupIdentifiers() async {
    final groupIdentifiersInList = await _fetchGroupList();
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

  Future<GroupIdentifiers> _fetchGroupList() async {
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

  Future<void> _setGroupList(GroupIdentifiers groupIdentifiers) async {
    final tags = groupIdentifiers.map((groupId) => groupId.toJson()).toList();
    final updateGroupListEvent = Event(
      nostr!.publicKey,
      EventKind.groupList,
      tags,
      "",
    );
    await nostr!.sendEvent(updateGroupListEvent);
    log(
      "Updated group list\n${groupIdentifiers.toString()}",
      level: Level.FINE.value,
      name: _logName,
    );
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
