import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../main.dart';

class MentionMeProvider extends ChangeNotifier
    with PendingEventsLaterFunction {
  late int _initTime;

  late EventMemBox eventBox;

  MentionMeProvider() {
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    eventBox = EventMemBox();
  }

  void refresh() {
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    eventBox.clear();
    doQuery();

    mentionMeNewProvider.clear();
  }

  void deleteEvent(String id) {
    var result = eventBox.delete(id);
    if (result) {
      notifyListeners();
    }
  }

  int lastTime() {
    return _initTime;
  }

  final List<String> _subscribeIds = [];

  List<int> queryEventKinds() {
    return [
      EventKind.textNote,
      EventKind.repost,
      EventKind.badgeAward,
      EventKind.genericRepost,
      EventKind.zap,
      EventKind.longForm,
    ];
  }

  String? subscribeId;

  void doQuery({Nostr? targetNostr, bool initQuery = false, int? until}) {
    targetNostr ??= nostr!;
    var filter = Filter(
      kinds: queryEventKinds(),
      until: until ?? _initTime,
      limit: 50,
      p: [targetNostr.publicKey],
    );

    if (subscribeId != null) {
      try {
        targetNostr.unsubscribe(subscribeId!);
      } catch (e) {}
    }

    subscribeId = _doQueryFunc(targetNostr, filter, initQuery: initQuery);
  }

  String _doQueryFunc(Nostr targetNostr, Filter filter,
      {bool initQuery = false}) {
    var subscribeId = StringUtil.rndNameStr(12);
    if (initQuery) {
      // targetNostr.pool.subscribe([filter.toJson()], onEvent, subscribeId);
      targetNostr.addInitQuery([filter.toJson()], onEvent, id: subscribeId);
    } else {
      if (!eventBox.isEmpty()) {
        var activeRelays = targetNostr.activeRelays();
        var oldestCreatedAts =
            eventBox.oldestCreatedAtByRelay(activeRelays, _initTime);
        Map<String, List<Map<String, dynamic>>> filtersMap = {};
        for (var relay in activeRelays) {
          var oldestCreatedAt = oldestCreatedAts.createdAtMap[relay.url];
          if (oldestCreatedAt != null) {
            filter.until = oldestCreatedAt;
            filtersMap[relay.url] = [filter.toJson()];
          }
        }
        targetNostr.queryByFilters(filtersMap, onEvent, id: subscribeId);
      } else {
        targetNostr.query([filter.toJson()], onEvent, id: subscribeId);
      }
    }
    return subscribeId;
  }

  void onEvent(Event event) {
    // filter the zap send by myself.
    if (event.kind == EventKind.zap) {
      for (var tag in event.tags) {
        if (tag is List && tag.length > 1) {
          var k = tag[0];
          var v = tag[1];

          if (k == "p" && v != nostr!.publicKey) {
            return;
          }
          if (k == "P" && v == nostr!.publicKey) {
            return;
          }
        }
      }
    }

    later(event, (list) {
      var result = eventBox.addList(list);
      if (result) {
        notifyListeners();
      }
    }, null);
  }

  void clear() {
    eventBox.clear();
    notifyListeners();
  }

  void mergeNewEvent() {
    var allEvents = mentionMeNewProvider.eventMemBox.all();

    eventBox.addList(allEvents);

    // sort
    eventBox.sort();

    mentionMeNewProvider.clear();

    // update ui
    notifyListeners();
  }
}
