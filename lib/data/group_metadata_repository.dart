import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import '../main.dart';

/// A repository class that handles fetching and setting group metadata.
class GroupMetadataRepository {
  /// Token that divides community guidelines in `about`.
  static const _communityGuidelinesMarker = "# Community Guidelines";

  /// Name used when logging.
  static const _logName = "GroupMetadataRepository";

  /// Fetches the metadata for a given group identifier.
  ///
  /// This function queries events from the `nostr` instance based on the
  /// provided group identifier and filters. If no metadata is found or `nostr`
  /// is null, an exception is thrown.
  ///
  /// - Parameters:
  ///   - id: The identifier of the group for which metadata is to be fetched.
  ///   - cached: Whether to retrieve metadata from cache. Defaults to false.
  /// - Returns: A `Future` that resolves to the `GroupMetadata` of the
  /// specified group.
  Future<GroupMetadata?> fetchGroupMetadata(GroupIdentifier id,
      {bool cached = false}) async {
    assert(nostr != null, "nostr instance is null");
    final host = id.host;
    final groupId = id.groupId;
    var filter = Filter(
      kinds: [EventKind.groupMetadata],
    );
    filter.limit = 1;
    var json = filter.toJson();
    json["#d"] = [groupId];
    final filters = [json];
    log(
      "Querying metadata for group $groupId...\n$json",
      level: Level.FINE.value,
      name: _logName,
    );
    final events = await nostr?.queryEvents(
      filters,
      tempRelays: [host],
      targetRelays: [host],
      relayTypes: cached ? [RelayType.local] : RelayType.onlyTemp,
      sendAfterAuth: true,
    );
    assert(events?.length == 1, "Didn't receive group metadata for $groupId");
    final event = events?.firstOrNull;
    if (event == null) {
      return null;
    }
    log(
      "Received metadata for group $groupId\n${event.toJson()}",
      level: Level.FINE.value,
      name: _logName,
    );
    var metadata = GroupMetadata.loadFromEvent(event);
    assert(metadata != null, "Couldn't parse group metadata for $groupId");
    if (metadata == null) {
      return null;
    }
    final about = metadata.about;
    if (about == null) {
      return metadata;
    }
    const marker = _communityGuidelinesMarker;
    final index = about.indexOf(marker);
    if (index == -1) {
      return metadata;
    }
    return GroupMetadata(
      metadata.groupId,
      metadata.createdAt,
      name: metadata.name,
      picture: metadata.picture,
      about: about.substring(0, index).trim(),
      communityGuidelines: about.substring(index + marker.length).trim(),
      public: metadata.public,
      open: metadata.open,
    );
  }

  /// Sets the metadata for a group.
  ///
  /// This function constructs and sends an event to update the metadata of the
  /// specified group  using the `nostr` instance. If `nostr` is null, an
  /// exception is thrown.
  ///
  /// - Parameters:
  ///   - metadata: The metadata to set for the group.
  ///   - host: The host where the event should be sent.
  /// - Returns: A `Future` that resolves to `true` if the metadata was
  /// successfully set, otherwise `false`.
  Future<bool> setGroupMetadata(GroupMetadata metadata, String host) async {
    assert(nostr != null, "nostr instance is null");
    var tags = [];
    final groupId = metadata.groupId;
    final name = metadata.name;
    final picture = metadata.picture;
    final about = metadata.about;
    final communityGuidelines = metadata.communityGuidelines;
    tags.add(["h", groupId]);
    if (name != null && name != "") {
      tags.add(["name", name]);
    }
    if (picture != null && picture != "") {
      tags.add(["picture", picture]);
    }
    const marker = _communityGuidelinesMarker;
    if (about != null && about != "") {
      if (communityGuidelines != null && communityGuidelines != "") {
        tags.add(["about", "$about\n\n$marker\n\n$communityGuidelines"]);
      } else {
        tags.add(["about", about]);
      }
    } else if (communityGuidelines != null && communityGuidelines != "") {
      tags.add(["about", "$marker\n\n$communityGuidelines"]);
    }
    final event = Event(
      nostr!.publicKey,
      EventKind.groupEditMetadata,
      tags,
      "",
    );
    log(
      "Saving metadata for group $groupId...\n${event.toJson()}",
      level: Level.FINE.value,
      name: _logName,
    );
    final relays = [host];
    final result = await nostr?.sendEvent(
      event,
      tempRelays: relays,
      targetRelays: relays,
    );
    log(
      "${result == null ? "Did not" : "Did"} save metadata for group $groupId",
      level: Level.FINE.value,
      name: _logName,
    );
    return result != null;
  }
}

/// A provider that supplies an instance of `GroupMetadataRepository`.
final groupMetadataRepositoryProvider =
    Provider<GroupMetadataRepository>((ref) {
  return GroupMetadataRepository();
});

/// A provider that fetches group metadata and handles its disposal.
final groupMetadataProvider = FutureProvider.autoDispose
    .family<GroupMetadata?, GroupIdentifier>((ref, id) {
  final repository = ref.watch(groupMetadataRepositoryProvider);
  return repository.fetchGroupMetadata(id);
});

/// A provider that fetches group metadata from cache and handles its disposal.
final cachedGroupMetadataProvider = FutureProvider.autoDispose
    .family<GroupMetadata?, GroupIdentifier>((ref, id) {
  final repository = ref.watch(groupMetadataRepositoryProvider);
  return repository.fetchGroupMetadata(id, cached: true);
});
