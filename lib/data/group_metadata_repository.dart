import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../main.dart';

/// A repository class that handles fetching and setting group metadata.
class GroupMetadataRepository {
  /// Token that divides community guidelines in `about`.
  static const _communityGuidelinesMarker = "# Community Guidelines";

  /// Fetches the metadata for a given group identifier.
  /// 
  /// This function queries events from the `nostr` instance based on the
  /// provided group identifier and filters. If no metadata is found or `nostr`
  /// is null, an exception is thrown.
  /// 
  /// - Parameters:
  ///   - id: The identifier of the group for which metadata is to be fetched.
  /// - Returns: A `Future` that resolves to the `GroupMetadata` of the
  /// specified group.
  Future<GroupMetadata?> fetchGroupMetadata(GroupIdentifier id) async {
    final host = id.host;
    final groupId = id.groupId;
    var filter = Filter(
      kinds: [EventKind.groupMetadata],
    );
    filter.limit = 1;
    var json = filter.toJson();
    json["#d"] = [groupId];
    final filters = [json];
    if (nostr == null) {
      Sentry.captureMessage(
        "nostr is null",
        level: SentryLevel.error,
      );
      throw Exception("Unexpected error. nostr instance is null");
    }
    final events = await nostr!.queryEvents(
      filters,
      tempRelays: [host],
      targetRelays: [host],
      relayTypes: RelayType.tempAndLocal,
      sendAfterAuth: true,
    );
    final event = events.firstOrNull;
    if (event == null) {
      Sentry.captureMessage(
        "Didn't find a metadata event",
        level: SentryLevel.error,
      );
      throw Exception("Unexpected error. No metadata events found");
    }
    var metadata = GroupMetadata.loadFromEvent(event);
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
    var tags = [];
    final name = metadata.name;
    final picture = metadata.picture;
    final about = metadata.about;
    final communityGuidelines = metadata.communityGuidelines;
    tags.add(["h", metadata.groupId]);
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
    if (nostr == null) {
      Sentry.captureMessage(
        "nostr is null",
        level: SentryLevel.error,
      );
      throw Exception("Unexpected error. nostr instance is null");
    }
    final event = Event(
      nostr!.publicKey,
      EventKind.groupEditMetadata,
      tags,
      "",
    );
    final relays = [host];
    final result = await nostr!.sendEvent(
      event,
      tempRelays: relays,
      targetRelays: relays,
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
