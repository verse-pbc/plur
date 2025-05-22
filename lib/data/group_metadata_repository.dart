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
  /// provided group identifier and filters. If no metadata is found on the primary
  /// relay, it will try fallback relays. If no metadata is found on any relay
  /// or `nostr` is null, null is returned.
  ///
  /// - Parameters:
  ///   - id: The identifier of the group for which metadata is to be fetched.
  ///   - cached: Whether to retrieve metadata from cache. Defaults to false.
  /// - Returns: A `Future` that resolves to the `GroupMetadata` of the
  /// specified group, or null if not found.
  Future<GroupMetadata?> fetchGroupMetadata(GroupIdentifier id,
      {bool cached = false}) async {
    assert(nostr != null, "nostr instance is null");
    
    // Start with the specified host
    final host = id.host;
    final groupId = id.groupId;
    
    // Create a filter for group metadata
    // Look for both groupMetadata and groupEditMetadata events
    var filter = Filter(
      kinds: [EventKind.groupMetadata, EventKind.groupEditMetadata],
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
    
    // First try with the specified host
    GroupMetadata? metadata = await _tryFetchMetadata(
      filters: filters,
      relays: [host],
      groupId: groupId,
      cached: cached,
    );
    
    // If metadata is found, return it immediately
    if (metadata != null) {
      return metadata;
    }
    
    // If not in cached mode, try fallback relays
    if (!cached) {
      log(
        "No metadata found for group $groupId on primary relay. Trying fallbacks...",
        level: Level.INFO.value,
        name: _logName,
      );
      
      // Import relay provider info without creating a circular dependency
      const backupRelays = [
        'wss://relay.nos.social',
        'wss://feeds.nostr.band',
        'wss://nos.lol',
        'wss://relay.damus.io',
      ];
      
      // Try each fallback relay
      for (final fallbackRelay in backupRelays) {
        if (fallbackRelay == host) continue; // Skip if it's the same as the original host
        
        metadata = await _tryFetchMetadata(
          filters: filters,
          relays: [fallbackRelay],
          groupId: groupId,
          cached: cached,
        );
        
        if (metadata != null) {
          log(
            "Found metadata for group $groupId on fallback relay: $fallbackRelay",
            level: Level.INFO.value,
            name: _logName,
          );
          return metadata;
        }
      }
      
      log(
        "No metadata found for group $groupId on any relay",
        level: Level.WARNING.value,
        name: _logName,
      );
    }
    
    // Return null if metadata isn't found
    return null;
  }
  
  /// Helper method to try fetching metadata from specified relays
  /// Returns parsed metadata if found, null otherwise
  Future<GroupMetadata?> _tryFetchMetadata({
    required List<Map<String, dynamic>> filters,
    required List<String> relays,
    required String groupId,
    bool cached = false,
  }) async {
    try {
      final events = await nostr?.queryEvents(
        filters,
        tempRelays: relays,
        targetRelays: relays,
        relayTypes: cached ? [RelayType.local] : RelayType.onlyTemp,
        sendAfterAuth: true,
      ).timeout(const Duration(seconds: 8), onTimeout: () {
        log(
          "Timeout querying metadata for group $groupId on relays: $relays",
          level: Level.WARNING.value,
          name: _logName,
        );
        return [];
      });
      
      final event = events?.firstOrNull;
      if (event == null) {
        return null;
      }
      
      log(
        "Received metadata for group $groupId from relay: ${relays.firstOrNull}",
        level: Level.FINE.value,
        name: _logName,
      );
      
      final metadata = GroupMetadata.loadFromEvent(event);
      return metadata;
    } catch (e, stackTrace) {
      log(
        "Error fetching metadata for group $groupId from relays $relays: $e",
        level: Level.WARNING.value,
        name: _logName,
      );
      log(stackTrace.toString(), level: Level.FINE.value, name: _logName);
      return null;
    }
  }
  
  /// Fetches metadata for multiple group identifiers at once
  ///
  /// This function optimizes fetching metadata for multiple groups
  /// by batching requests where possible. If metadata is missing from the primary relay,
  /// it will try fallback relays.
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
        kinds: [EventKind.groupMetadata, EventKind.groupEditMetadata],
      );
      var json = filter.toJson();
      json["#d"] = dValues;
      
      log(
        "Bulk querying metadata for ${dValues.length} groups on $host",
        level: Level.FINE.value,
        name: _logName,
      );
      
      try {
        // First try the primary host
        final events = await nostr?.queryEvents(
          [json],
          tempRelays: [host],
          targetRelays: [host],
          relayTypes: cached ? [RelayType.local] : RelayType.onlyTemp,
          sendAfterAuth: true,
        ).timeout(const Duration(seconds: 8), onTimeout: () {
          log(
            "Timeout bulk querying metadata on relay: $host",
            level: Level.WARNING.value,
            name: _logName,
          );
          return [];
        });
        
        // Map events to their group IDs
        if (events != null && events.isNotEmpty) {
          for (final event in events) {
            final metadata = GroupMetadata.loadFromEvent(event);
            if (metadata != null) {
              results[metadata.groupId] = metadata;
            }
          }
        }
      } catch (e, stackTrace) {
        log(
          "Error bulk querying metadata on relay $host: $e",
          level: Level.WARNING.value,
          name: _logName,
        );
        log(stackTrace.toString(), level: Level.FINE.value, name: _logName);
      }
      
      // For missing IDs, try fallback relays (only if not in cached mode)
      if (!cached) {
        // Figure out which IDs are still missing
        final missingGroupIds = dValues.where((id) => !results.containsKey(id)).toList();
        
        if (missingGroupIds.isNotEmpty) {
          log(
            "Missing metadata for ${missingGroupIds.length} groups. Trying fallback relays...",
            level: Level.INFO.value,
            name: _logName,
          );
          
          // Import relay provider info without creating a circular dependency
          const backupRelays = [
            'wss://relay.nos.social',
            'wss://feeds.nostr.band',
            'wss://nos.lol',
            'wss://relay.damus.io',
          ];
          
          // Try each fallback relay for the missing IDs
          for (final fallbackRelay in backupRelays) {
            if (fallbackRelay == host) continue; // Skip if it's the same as the original host
            
            try {
              // Try this fallback relay with the same filter kinds
              final fallbackFilter = Filter(
                kinds: [EventKind.groupMetadata, EventKind.groupEditMetadata],
              );
              final fallbackJson = fallbackFilter.toJson();
              fallbackJson["#d"] = missingGroupIds;
              
              final fallbackEvents = await nostr?.queryEvents(
                [fallbackJson],
                tempRelays: [fallbackRelay],
                targetRelays: [fallbackRelay],
                relayTypes: RelayType.onlyTemp,
                sendAfterAuth: true,
              ).timeout(const Duration(seconds: 8), onTimeout: () {
                log(
                  "Timeout querying metadata on fallback relay: $fallbackRelay",
                  level: Level.WARNING.value,
                  name: _logName,
                );
                return [];
              });
              
              // Process any events found
              if (fallbackEvents != null && fallbackEvents.isNotEmpty) {
                for (final event in fallbackEvents) {
                  final metadata = GroupMetadata.loadFromEvent(event);
                  if (metadata != null) {
                    results[metadata.groupId] = metadata;
                    log(
                      "Found metadata for group ${metadata.groupId} on fallback relay: $fallbackRelay",
                      level: Level.INFO.value,
                      name: _logName,
                    );
                  }
                }
              }
              
              // Update the list of missing IDs
              final stillMissingGroupIds = missingGroupIds.where((id) => !results.containsKey(id)).toList();
              if (stillMissingGroupIds.isEmpty) {
                break; // Found all missing IDs, can stop trying more relays
              }
            } catch (e) {
              log(
                "Error querying metadata on fallback relay $fallbackRelay: $e",
                level: Level.WARNING.value,
                name: _logName,
              );
            }
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
  
  // For any communities without metadata, try a direct network fetch
  final keysWithNullValues = results.entries
      .where((entry) => entry.value == null || entry.value?.name == null || entry.value!.name!.isEmpty)
      .map((entry) => entry.key)
      .toList();
  
  if (keysWithNullValues.isNotEmpty) {
    for (final groupId in keysWithNullValues) {
      final correspondingIdentifier = groupIds.firstWhere(
        (id) => id.groupId == groupId, 
        orElse: () => groupIds.first
      );
      
      // Try to fetch metadata from network for this specific group
      final freshMetadata = await repository.fetchGroupMetadata(
        correspondingIdentifier,
        cached: false, // Explicitly fetch from network
      );
      
      if (freshMetadata != null) {
        results[groupId] = freshMetadata;
      }
    }
  }
  
  // The individual providers will access this data from the cache when requested
  return results;
});
