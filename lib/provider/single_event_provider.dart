import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../main.dart';

class SingleEventProvider extends ChangeNotifier with LaterFunction {
  final Map<String, Event> _eventsMap = {};

  final Map<String, String> _needUpdateIds = {};

  final Map<String, String> _handingIds = {};

  final List<Event> _pendingEvents = [];

  Event? getEvent(String id, {String? eventRelayAddr, bool queryData = true}) {
    var event = _eventsMap[id];
    if (event != null) {
      return event;
    }

    _getEventFromCacheRelay(id);

    if (!queryData) {
      return null;
    }

    if (_needUpdateIds[id] == null && _handingIds[id] == null) {
      eventRelayAddr ??= "";
      _needUpdateIds[id] = eventRelayAddr;
      later(_laterCallback);
    }

    return null;
  }

  final Map<String, int> _localRelayQuering = {};

  void _getEventFromCacheRelay(String id) async {
    if (_localRelayQuering[id] == null) {
      _localRelayQuering[id] = 1;
      try {
        var filter = Filter(ids: [id]);
        var events = await nostr!.queryEvents([filter.toJson()],
            relayTypes: RelayType.cacheAndLocal);
        if (events.isNotEmpty) {
          _eventsMap[id] = events.first;
          _needUpdateIds.remove(id);
          notifyListeners();
        }
      } finally {
        _localRelayQuering.remove(id);
      }
    }
  }

  void _laterCallback() {
    if (_needUpdateIds.isNotEmpty) {
      _laterSearch();
    }

    if (_pendingEvents.isNotEmpty) {
      _handlePendingEvents();
    }
  }

  void _handlePendingEvents() {
    for (var event in _pendingEvents) {
      var oldEvent = _eventsMap[event.id];
      if (oldEvent != null) {
        if (event.sources.isNotEmpty &&
            !oldEvent.sources.contains(event.sources[0])) {
          oldEvent.sources.add(event.sources[0]);
        }
      } else {
        _eventsMap[event.id] = event;
      }

      _handingIds.remove(event.id);
    }
    _pendingEvents.clear;
    notifyListeners();
  }

  void onEvent(Event event) {
    _pendingEvents.add(event);
    later(_laterCallback);
  }

  void _laterSearch() {
    if (_needUpdateIds.isNotEmpty) {
      List<String> tempIds = [..._needUpdateIds.keys];
      var filter = Filter(ids: tempIds);
      var subscriptId = StringUtil.rndNameStr(12);

      bool onCompleteCalled = false;
      onCompete() {
        if (onCompleteCalled) {
          return;
        }

        onCompleteCalled = true;

        for (var id in tempIds) {
          var eventRelayAddr = _handingIds.remove(id);
          if (StringUtil.isNotBlank(eventRelayAddr) && _eventsMap[id] == null) {
            // eventRelayAddr exist and event not found, send a single query again.
            log("single event $id not found! begin to query again from $eventRelayAddr.");
            var filter = Filter(ids: [id]);
            nostr!.query([filter.toJson()], onEvent,
                tempRelays: [eventRelayAddr!], relayTypes: RelayType.onlyTemp);
          }
        }
      }

      nostr!.query([filter.toJson()], onEvent, id: subscriptId, onComplete: () {
        onCompete();
      }, relayTypes: RelayType.onlyNormal);
      Future.delayed(const Duration(seconds: 2), onCompete);

      for (var entry in _needUpdateIds.entries) {
        _handingIds[entry.key] = entry.value;
      }
      _needUpdateIds.clear();
    }
  }
}
