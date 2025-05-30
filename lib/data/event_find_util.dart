import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/main.dart';

class EventFindUtil {
  static Future<List<Event>> findEvent(String str, {int limit = 5}) async {
    List<FindEventInterface> finders = [followEventProvider];
    finders.addAll(eventReactionsProvider.allReactions());

    var eventBox = EventMemBox(sortAfterAdd: false);
    for (var finder in finders) {
      var list = finder.findEvent(str, limit: limit);
      if (list.isNotEmpty) {
        eventBox.addList(list);

        if (eventBox.length() >= limit) {
          break;
        }
      }
    }

    if (eventBox.length() < limit) {
      // try to find something from localRelay
      var filter = Filter(kinds: EventKind.supportedEvents, limit: 5);
      var filterMap = filter.toJson();
      filterMap["search"] = str;

      var events = await nostr!
          .queryEvents([filterMap], relayTypes: RelayType.cacheAndLocal);
      eventBox.addList(events);
    }

    eventBox.sort();
    return eventBox.all();
  }
}
