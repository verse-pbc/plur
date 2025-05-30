import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/main.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class GroupProvider extends ChangeNotifier with LaterFunction {
  Map<String, GroupMetadata> groupMetadatas = {};

  Map<String, GroupAdmins> groupAdmins = {};

  Map<String, GroupMembers> groupMembers = {};

  final Map<String, int> _handlingMetadataIds = {};

  final Map<String, int> _handlingAdminsIds = {};

  final Map<String, int> _handlingMembersIds = {};

  int now() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  void _markHandling(GroupIdentifier groupIdentifier) {
    var key = groupIdentifier.toString();
    var t = now();

    _handlingMetadataIds[key] = t;
    _handlingAdminsIds[key] = t;
    _handlingMembersIds[key] = t;
  }

  void deleteEvent(GroupIdentifier groupIdentifier, String eventId) {
    NIP29.deleteEvent(nostr!, groupIdentifier, eventId);
  }

  void editStatus(GroupIdentifier groupIdentifier, bool? public, bool? open) {
    NIP29.editStatus(nostr!, groupIdentifier, public, open);
  }

  GroupMetadata? getMetadata(GroupIdentifier groupIdentifier) {
    var key = groupIdentifier.toString();
    var m = groupMetadatas[key];
    if (m != null) {
      return m;
    }

    var ot = _handlingMetadataIds[key];
    if (ot == null || now() - ot > 60 * 5) {
      _markHandling(groupIdentifier);
      query(groupIdentifier);
    }
    return null;
  }

  GroupAdmins? getAdmins(GroupIdentifier groupIdentifier) {
    var key = groupIdentifier.toString();
    var m = groupAdmins[key];
    if (m != null) {
      return m;
    }

    var ot = _handlingAdminsIds[key];
    if (ot == null || now() - ot > 60 * 5) {
      _markHandling(groupIdentifier);
      query(groupIdentifier);
    }
    return null;
  }

  bool isAdmin(String pubkey, GroupIdentifier groupIdentifier) {
    final admins = getAdmins(groupIdentifier);
    return admins?.containsUser(pubkey) ?? false;
  }

  GroupMembers? getMembers(GroupIdentifier groupIdentifier) {
    var key = groupIdentifier.toString();
    var m = groupMembers[key];
    if (m != null) {
      return m;
    }

    var ot = _handlingMembersIds[key];
    if (ot == null || now() - ot > 60 * 5) {
      _markHandling(groupIdentifier);
      query(groupIdentifier);
    }
    return null;
  }

  int getMemberCount(GroupIdentifier groupIdentifier) =>
      getMembers(groupIdentifier)?.members?.length ?? 0;

  void _updateMember(GroupIdentifier groupIdentifier) {
    var membersJsonMap =
        genFilter(groupIdentifier.groupId, EventKind.groupMembers);

    nostr!.query(
      [membersJsonMap],
      (e) {
        onEvent(groupIdentifier, e);
      },
      tempRelays: [groupIdentifier.host],
      relayTypes: RelayType.onlyTemp,
    );
  }

  void addMember(GroupIdentifier groupIdentifier, String pubkey) {
    NIP29.addMember(nostr!, groupIdentifier, pubkey);

    // try to add to mem
    var key = groupIdentifier.toString();
    var members = groupMembers[key];
    if (members != null) {
      members.add(pubkey);
    }

    _updateMember(groupIdentifier);

    notifyListeners();
  }

  Future<void> removeMember(
      GroupIdentifier groupIdentifier, String pubkey) async {
    NIP29.removeMember(nostr!, groupIdentifier, pubkey);

    // try to delete from mem
    var key = groupIdentifier.toString();
    var members = groupMembers[key];
    if (members != null) {
      members.remove(pubkey);
    }

    _updateMember(groupIdentifier);

    notifyListeners();
  }

  /// Returns a [Filter] object that can be used to query events with kind
  /// [eventKind] relevant to group [groupId] from relays.
  @visibleForTesting
  Map<String, dynamic> genFilter(String groupId, int eventKind) {
    var filter = Filter(
      kinds: [eventKind],
    );
    var jsonMap = filter.toJson();
    jsonMap["#d"] = [groupId];
    return jsonMap;
  }

  /// Query metadata, admin list, and member list, from group [groupIdentifier]
  /// from the network.
  void query(GroupIdentifier groupIdentifier) {
    final groupId = groupIdentifier.groupId;
    final host = groupIdentifier.host;
    var metadataJsonMap = genFilter(groupId, EventKind.groupMetadata);
    var adminsJsonMap = genFilter(groupId, EventKind.groupAdmins);
    var membersJsonMap = genFilter(groupId, EventKind.groupMembers);
    final filters = [metadataJsonMap, adminsJsonMap, membersJsonMap];
    if (nostr == null) {
      Sentry.captureMessage("nostr is null", level: SentryLevel.error);
      return;
    }
    nostr!.query(
      filters,
      (e) => onEvent(groupIdentifier, e),
      tempRelays: [host],
      targetRelays: [host],
      relayTypes: RelayType.tempAndLocal,
      sendAfterAuth: true,
    );
  }

  void onEvent(GroupIdentifier groupIdentifier, Event e) {
    bool updated = false;
    if (e.kind == EventKind.groupMetadata) {
      updated = handleEvent(
          groupMetadatas, groupIdentifier, GroupMetadata.loadFromEvent(e));
    } else if (e.kind == EventKind.groupAdmins) {
      updated = handleEvent(
          groupAdmins, groupIdentifier, GroupAdmins.loadFromEvent(e));
    } else if (e.kind == EventKind.groupMembers) {
      updated = handleEvent(
          groupMembers, groupIdentifier, GroupMembers.loadFromEvent(e));
    } else if (e.kind == EventKind.groupEditMetadata) {
      updated = handleEvent(
          groupMetadatas, groupIdentifier, GroupMetadata.loadFromEvent(e));
    }

    if (updated) {
      notifyListeners();
    }
  }

  /// Updates the given Map with the new data contained in groupIdentifier and
  /// groupObject with some validation to filter out bad data.
  bool handleEvent(
      Map map, GroupIdentifier groupIdentifier, GroupObject? groupObject) {
    var key = groupIdentifier.toString();
    if (groupObject == null) {
      return false;
    }

    if (groupObject.groupId != groupIdentifier.groupId) {
      return false;
    }

    bool updated = false;
    var object = map[key];
    if (object == null) {
      map[key] = groupObject;
      updated = true;
    } else {
      // gets the most recent valid metadata
      if (object is GroupObject && groupObject.createdAt > object.createdAt) {
        map[key] = groupObject;
        updated = true;
      }
    }

    return updated;
  }

  /// Saves group metadata in associated relay.
  Future<void> updateMetadata(
    GroupIdentifier groupIdentifier,
    GroupMetadata groupMetadata,
  ) async {
    var tags = [];
    final name = groupMetadata.name;
    final picture = groupMetadata.picture;
    final about = groupMetadata.about;
    tags.add(["h", groupIdentifier.groupId]);
    if (name != null && name != "") {
      tags.add(["name", name]);
    }
    if (picture != null && picture != "") {
      tags.add(["picture", picture]);
    }
    if (about != null && about != "") {
      tags.add(["about", about]);
    }
    final event = Event(
      nostr!.publicKey,
      EventKind.groupEditMetadata,
      tags,
      ""
    );
    final relays = [groupIdentifier.host];
    final result = await nostr!.sendEvent(
      event,
      tempRelays: relays,
      targetRelays: relays
    );
    if (result != null) {
      handleEvent(
        groupMetadatas,
        groupIdentifier,
        GroupMetadata.loadFromEvent(event),
      );
    }
  }
}
