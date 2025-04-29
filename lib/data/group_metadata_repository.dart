import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import '../main.dart';

/// A repository class that handles fetching and setting group metadata.
class GroupMetadataRepository {
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
    
    // Use default timeout for events query
    final events = await nostr?.queryEvents(
      filters,
      tempRelays: [host],
      targetRelays: [host],
      relayTypes: cached ? [RelayType.local] : RelayType.onlyTemp,
      sendAfterAuth: true,
    );
    
    // Events can be empty if the group never got a name for example
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
    return metadata;
  }
  
  /// Fetches metadata for multiple group identifiers at once
  ///
  /// This function optimizes fetching metadata for multiple groups
  /// by batching requests where possible.
  ///
  /// - Parameters:
  ///   - ids: The list of group identifiers to fetch metadata for
  ///   - cached: Whether to retrieve metadata from cache. Defaults to false.
  /// - Returns: A map of group IDs to their metadata
  Future<Map<String, GroupMetadata?>> fetchMultipleGroupMetadata(
      List<GroupIdentifier> ids, {bool cached = false}) async {
    assert(nostr != null, "nostr instance is null");
    
    // Group IDs by host to batch requests
    final idsByHost = <String, List<GroupIdentifier>>{};
    for (final id in ids) {
      final host = id.host;
      idsByHost.putIfAbsent(host, () => []).add(id);
    }
    
    final results = <String, GroupMetadata?>{};
    
    // Process each host in parallel
    await Future.wait(idsByHost.entries.map((entry) async {
      final host = entry.key;
      final idsForHost = entry.value;
      
      // Create a filter with all group IDs for this host
      final dValues = idsForHost.map((id) => id.groupId).toList();
      var filter = Filter(
        kinds: [EventKind.groupMetadata],
      );
      var json = filter.toJson();
      json["#d"] = dValues;
      
      log(
        "Bulk querying metadata for ${dValues.length} groups on $host",
        level: Level.FINE.value,
        name: _logName,
      );
      
      final events = await nostr?.queryEvents(
        [json],
        tempRelays: [host],
        targetRelays: [host],
        relayTypes: cached ? [RelayType.local] : RelayType.onlyTemp,
        sendAfterAuth: true,
      );
      
      // Map events to their group IDs
      if (events != null) {
        for (final event in events) {
          final metadata = GroupMetadata.loadFromEvent(event);
          if (metadata != null) {
            results[metadata.groupId] = metadata;
          }
        }
      }
    }));
    
    // Fill in missing results
    for (final id in ids) {
      if (!results.containsKey(id.groupId)) {
        results[id.groupId] = null;
      }
    }
    
    return results;
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
    if (about != null && about != "") {
      tags.add(["about", about]);
    }
    if (communityGuidelines != null && communityGuidelines != "") {
      tags.add(["guidelines", communityGuidelines]);
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
  
  // Keep the provider alive for a reasonable amount of time (5 minutes)
  // This prevents it from being disposed too quickly
  ref.keepAlive();
  
  return repository.fetchGroupMetadata(id, cached: true);
});

/// A provider that pre-fetches metadata for multiple groups at once
final bulkGroupMetadataProvider = 
    FutureProvider.family<Map<String, GroupMetadata?>, List<GroupIdentifier>>((ref, groupIds) async {
  final repository = ref.watch(groupMetadataRepositoryProvider);
  
  // Use the optimized bulk fetching method
  final results = await repository.fetchMultipleGroupMetadata(groupIds, cached: true);
  
  // We've already loaded all data in bulk
  // The individual providers will access this data from the cache when requested
  
  return results;
});
