import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../main.dart';

class BadgeDefinitionProvider extends ChangeNotifier with LaterFunction {
  Map<String, BadgeDefinition> map = {};

  BadgeDefinition? get(String badgeId, String pubkey) {
    var bd = map[badgeId];
    if (bd != null) {
      return bd;
    }

    if (!_needUpdatePubKeys.contains(pubkey) &&
        !_handingPubkeys.containsKey(pubkey)) {
      _needUpdatePubKeys.add(pubkey);
    }
    later(_laterCallback);
    return null;
  }

  final Map<String, int> _handingPubkeys = {};

  final List<String> _needUpdatePubKeys = [];

  // one user contains multi bedge defintion, here may not works
  final List<Event> _pendingEvents = [];

  void _laterCallback() {
    if (_needUpdatePubKeys.isNotEmpty) {
      _laterSearch();
    }

    if (_pendingEvents.isNotEmpty) {
      _handlePendingEvents();
    }
  }

  void _laterSearch() {
    List<Map<String, dynamic>> filters = [];
    for (var pubkey in _needUpdatePubKeys) {
      var filter =
          Filter(kinds: [EventKind.badgeDefinition], authors: [pubkey]);
      filters.add(filter.toJson());
    }
    var subscriptId = StringUtil.rndNameStr(16);
    // use query and close after EOSE
    nostr!.query(filters, _onEvent, id: subscriptId);

    for (var pubkey in _needUpdatePubKeys) {
      _handingPubkeys[pubkey] = 1;
    }
    _needUpdatePubKeys.clear();
  }

  void _onEvent(Event event) {
    _pendingEvents.add(event);
    later(_laterCallback);
  }

  void _handlePendingEvents() {
    bool updated = false;

    for (var event in _pendingEvents) {
      var bd = BadgeDefinition.loadFromEvent(event);
      if (bd != null) {
        var badgeId = "30009:${event.pubkey}:${bd.d}";

        var oldBD = map[badgeId];
        if (oldBD == null || oldBD.updatedAt < bd.updatedAt) {
          map[badgeId] = bd;
          updated = true;
        }
      }
    }
    _pendingEvents.clear;

    if (updated) {
      notifyListeners();
    }
  }
}
