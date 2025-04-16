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

/// Repository for managing and interacting with group identifiers.
///
/// This class provides methods to fetch, add, remove, and monitor group
/// identifiers. It interacts with relays and handles group membership
/// verification, group list updates, and subscription to group-related events.
class GroupIdentifierRepository {
  /// Name used when logging.
  static const _logName = "GroupIdentifierRepository";

  /// Default relay address for group-related operations.
  static const _defaultRelay = RelayProvider.defaultGroupsRelayAddress;

  /// BehaviorSubject to manage the stream of group identifiers.
  final _groupIdentifiers = BehaviorSubject<GroupIdentifiers>();

  /// Watches the list of group identifiers as a stream.
  ///
  /// Returns a [Stream] of [GroupIdentifiers] that emits updates whenever
  /// the list changes.
  Stream<GroupIdentifiers> watchGroupIdentifierList() {
    return _groupIdentifiers.stream;
  }

  /// Checks if the user is a member of the specified group.
  ///
  /// Queries the relay to verify membership in the group identified by
  /// [groupIdentifier]. Returns `true` if the user is a member, otherwise `false`.
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

  /// Adds a group identifier to the list.
  ///
  /// Updates both the local cached list and the remote group list.
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

  /// Removes a group identifier from the list.
  ///
  /// Updates both the local cached list and the remote group list.
  Future<void> removeGroupIdentifier(GroupIdentifier groupIdentifier) async {
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

  /// Checks if the group identifier exists in the list.
  ///
  /// Returns `true` if the [groupIdentifier] is present, otherwise `false`.
  Future<bool> containsGroupIdentifier(GroupIdentifier groupIdentifier) async {
    return _groupIdentifiers.value.contains(groupIdentifier);
  }

  /// Disposes of the repository by closing the stream.
  void dispose() => _groupIdentifiers.close();

  /// Fetches the initial list of group identifiers.
  ///
  /// Combines group identifiers from the local cache and relays, ensuring
  /// the list is up-to-date.
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

  /// Fetches the group list from the relay.
  ///
  /// Queries the relay for the user's group list and parses the response
  /// into a list of [GroupIdentifier] objects.
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

  /// Updates the group list on the relay.
  ///
  /// Sends an event to the relay with the updated list of group identifiers.
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

  /// Fetches group identifiers from relays where the user is a member or admin.
  ///
  /// Queries the relay for group membership and admin events and extracts
  /// the group identifiers from the event tags.
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

  /// Subscribes to updates for group-related events.
  ///
  /// Listens for events such as group membership changes, metadata edits,
  /// and deletions, and updates the local list accordingly.
  void _subscribeToNewUpdates(Ref ref) {
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
        () => _handleSubscriptionEvent(event, ref),
      ),
      id: subscribeId,
      tempRelays: [RelayProvider.defaultGroupsRelayAddress],
      targetRelays: [RelayProvider.defaultGroupsRelayAddress],
      relayTypes: RelayType.onlyTemp,
      sendAfterAuth: true,
    );
  }

  /// Handles events received from the subscription.
  ///
  /// Processes events such as group deletions, membership changes, and
  /// metadata edits, and updates the local list of group identifiers.
  void _handleSubscriptionEvent(Event event, Ref ref) async {
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
          final repository = ref.watch(groupMetadataRepositoryProvider);
          await repository.fetchGroupMetadata(groupIdentifier);
          // Add delay so that the local cache has time to update the db
          await Future.delayed(const Duration(seconds: 1));
          // Invalidate provider so that the UI is updated
          ref.invalidate(cachedGroupMetadataProvider(groupIdentifier));
        }
    }
    _groupIdentifiers.add(updated);
  }

  /// Extracts group identifiers from event tags with the specified prefix.
  ///
  /// Parses the tags of the given [event] and returns a list of
  /// [GroupIdentifier] objects matching the [tagPrefix].
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
  Future.microtask(() async {
    await repository._fetchInitialListOfGroupIdentifiers();
    repository._subscribeToNewUpdates(ref);
  });
  ref.onDispose(() => repository.dispose());
  return repository;
});

/// A provider that fetches group identifiers and handles their disposal.
final groupIdentifiersProvider = StreamProvider<GroupIdentifiers>((ref) {
  final repository = ref.watch(groupIdentifierRepositoryProvider);
  return repository.watchGroupIdentifierList();
});
