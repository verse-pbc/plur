import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
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
  /// [eventKind] relevante to group [groupId] from relays.
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
    var metadataJsonMap = genFilter(groupId, EventKind.GROUP_METADATA);
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
      relayTypes: RelayType.tempAndLocal,
    );
  }

  void onEvent(GroupIdentifier groupIdentifier, Event e) {
    bool updated = false;
    if (e.kind == EventKind.GROUP_METADATA) {
      updated = handleEvent(
          groupMetadatas, groupIdentifier, GroupMetadata.loadFromEvent(e));
    } else if (e.kind == EventKind.groupAdmins) {
      updated = handleEvent(
          groupAdmins, groupIdentifier, GroupAdmins.loadFromEvent(e));
    } else if (e.kind == EventKind.groupMembers) {
      updated = handleEvent(
          groupMembers, groupIdentifier, GroupMembers.loadFromEvent(e));
    } else if (e.kind == EventKind.GROUP_EDIT_METADATA) {
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

  void udpateMetadata(
      GroupIdentifier groupIdentifier, GroupMetadata groupMetadata) async {
    var relays = [groupIdentifier.host];

    var tags = [];
    tags.add(["h", groupIdentifier.groupId]);
    if (StringUtil.isNotBlank(groupMetadata.name)) {
      tags.add(["name", groupMetadata.name!]);
    }
    if (StringUtil.isNotBlank(groupMetadata.picture)) {
      tags.add(["picture", groupMetadata.picture!]);
    }
    if (StringUtil.isNotBlank(groupMetadata.about)) {
      tags.add(["about", groupMetadata.about!]);
    }

    var e = Event(nostr!.publicKey, EventKind.GROUP_EDIT_METADATA, tags, "");
    var result =
        await nostr!.sendEvent(e, tempRelays: relays, targetRelays: relays);
    if (result != null) {
      handleEvent(
          groupMetadatas, groupIdentifier, GroupMetadata.loadFromEvent(e));
    }
  }
}
