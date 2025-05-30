import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../main.dart';
import 'follow_event_provider.dart';

class FollowNewEventProvider extends ChangeNotifier
    with PendingEventsLaterFunction {
  EventMemBox eventPostMemBox = EventMemBox(sortAfterAdd: false);
  EventMemBox eventMemBox = EventMemBox();

  int? _localSince;

  List<String> _subscribeIds = [];

  void doUnsubscribe() {
    if (_subscribeIds.isNotEmpty) {
      for (var subscribeId in _subscribeIds) {
        try {
          nostr!.unsubscribe(subscribeId);
        } catch (_) {}
      }
      _subscribeIds.clear();
    }
  }

  void queryNew() {
    doUnsubscribe();

    bool queriedTags = false;
    _localSince =
        _localSince == null || followEventProvider.lastTime() > _localSince!
            ? followEventProvider.lastTime()
            : _localSince;
    var filter = Filter(
        since: _localSince! + 1, kinds: followEventProvider.queryEventKinds());

    List<String> subscribeIds = [];
    Iterable<Contact> contactList = contactListProvider.list();
    List<String> ids = [];
    for (Contact contact in contactList) {
      ids.add(contact.publicKey);
      if (ids.length > 100) {
        filter.authors = ids;
        var subscribeId = _doQueryFunc(filter, queriyTags: queriedTags);
        subscribeIds.add(subscribeId);
        ids = [];
        queriedTags = true;
      }
    }
    if (ids.isNotEmpty) {
      filter.authors = ids;
      var subscribeId = _doQueryFunc(filter, queriyTags: queriedTags);
      subscribeIds.add(subscribeId);
    }

    _subscribeIds = subscribeIds;
  }

  String _doQueryFunc(Filter filter, {bool queriyTags = false}) {
    var subscribeId = StringUtil.rndNameStr(12);
    nostr!.query(
        FollowEventProvider.addTagCommunityFilter(
            [filter.toJson()], queriyTags), (event) {
      later(event, handleEvents, null);
    }, id: subscribeId);
    return subscribeId;
  }

  void clear() {
    eventPostMemBox.clear();
    eventMemBox.clear();

    notifyListeners();
  }

  handleEvents(List<Event> events) {
    eventMemBox.addList(events);
    _localSince = eventMemBox.newestEvent!.createdAt;

    for (var event in events) {
      bool isPosts = FollowEventProvider.eventIsPost(event);
      if (isPosts) {
        eventPostMemBox.add(event);
      }
    }

    notifyListeners();
  }
}
