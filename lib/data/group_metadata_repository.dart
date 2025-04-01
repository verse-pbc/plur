import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../main.dart';

class GroupMetadataRepository {
  Future<GroupMetadata?> fetchGroupMetadata(
      GroupIdentifier groupIdentifier) async {
    final host = groupIdentifier.host;
    final groupId = groupIdentifier.groupId;
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
      relayTypes: [RelayType.local],
    );
    final event = events.firstOrNull;
    if (event == null) {
      Sentry.captureMessage(
        "Didn't find a metadatada event",
        level: SentryLevel.error,
      );
      throw Exception("Unexpected error. No metadata events found");
    }
    return GroupMetadata.loadFromEvent(event);
  }

  Future<String?> fetchCommunityGuidelines(
      GroupIdentifier groupIdentifier) async {
    final metadata = await fetchGroupMetadata(groupIdentifier);
    if (metadata == null) {
      Sentry.captureMessage(
        "Couldn't parse metadata event",
        level: SentryLevel.error,
      );
      throw Exception("Unexpected error. Metadata event couldn't be parsed");
    }
    final about = metadata.about;
    if (about == null) {
      return null;
    }
    const marker = "# Community Guidelines";
    final index = about.indexOf(marker);
    if (index == -1) {
      return null;
    }
    return about.substring(index + marker.length).trim();
  }
}

final groupMetadataProvider = Provider<GroupMetadataRepository>((ref) {
  return GroupMetadataRepository();
});

final communityGuidelinesProvider =
    FutureProvider.autoDispose.family<String?, GroupIdentifier>((ref, id) {
  final repository = ref.watch(groupMetadataProvider);
  return repository.fetchCommunityGuidelines(id);
});
