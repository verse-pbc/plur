import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../main.dart';

class MentionMeNewProvider extends ChangeNotifier
    with PendingEventsLaterFunction {
  EventMemBox eventMemBox = EventMemBox();

  int? _localSince;

  String? subscribeId;

  void queryNew() {
    if (subscribeId != null) {
      try {
        nostr!.unsubscribe(subscribeId!);
      } catch (_) {}
    }

    _localSince =
        _localSince == null || mentionMeProvider.lastTime() > _localSince!
            ? mentionMeProvider.lastTime()
            : _localSince;

    subscribeId = StringUtil.rndNameStr(12);
    var filter = Filter(
      since: _localSince! + 1,
      kinds: mentionMeProvider.queryEventKinds(),
      p: [nostr!.publicKey],
    );
    nostr!.query([filter.toJson()], (event) {
      later(event, handleEvents, null);
    }, id: subscribeId);
  }

  handleEvents(List<Event> events) {
    eventMemBox.addList(events);
    _localSince = eventMemBox.newestEvent!.createdAt;
    notifyListeners();
  }

  void clear() {
    eventMemBox.clear();

    notifyListeners();
  }
}
