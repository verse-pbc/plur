import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../main.dart';

class GroupMetadataRepository {
  static const _communityGuidelinesMarker = "# Community Guidelines";

  Future<GroupMetadata?> fetchGroupMetadata(GroupIdentifier id) async {
    await Future.delayed(const Duration(seconds: 2));
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
      relayTypes: [RelayType.local],
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

final groupMetadataRepositoryProvider =
    Provider<GroupMetadataRepository>((ref) {
  return GroupMetadataRepository();
});

final groupMetadataProvider = FutureProvider.autoDispose
    .family<GroupMetadata?, GroupIdentifier>((ref, id) {
  final repository = ref.watch(groupMetadataRepositoryProvider);
  return repository.fetchGroupMetadata(id);
});
