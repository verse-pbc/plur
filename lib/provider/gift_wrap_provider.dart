import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../data/event_db.dart';
import '../main.dart';

class GiftWrapProvider extends ChangeNotifier {
  // The box to contains events.
  // Maybe it should only hold all eventIds.
  EventMemBox box = EventMemBox(sortAfterAdd: false);

  Future<void> init() async {
    var keyIndex = settingsProvider.privateKeyIndex!;
    var events =
        await EventDB.list(keyIndex, [EventKind.giftWrap], 0, 10000000);

    for (var event in events) {
      box.add(event);
    }
    box.sort();
  }

  bool initQuery = true;

  int timeFlag = 60 * 60 * 24 * 2;

  void query({Nostr? targetNostr, int? since}) {
    targetNostr ??= nostr;
    if (since == null && !box.isEmpty()) {
      if (initQuery) {
        // haven't query before
        var oldestEvent = box.oldestEvent;
        since = oldestEvent!.createdAt - timeFlag;
      } else {
        // queried before, since change to two days before now avoid query too much event
        since = DateTime.now().millisecondsSinceEpoch ~/ 1000 - timeFlag;
      }
    }

    var filter = Filter(
      kinds: [EventKind.giftWrap],
      since: since,
      p: [nostr!.publicKey],
    );

    // log("query!");
    targetNostr!.query([filter.toJson()], onEvent);
  }

  Future<void> onEvent(Event e) async {
    if (box.add(e)) {
      // This is an new event.
      // decode this event.
      var sourceEvent = await GiftWrapUtil.getRumorEvent(nostr!, e);

      // some event need some handle
      if (sourceEvent != null) {
        if (sourceEvent.kind == EventKind.privateDirectMessage) {
          // private DM, handle by dmProvider
          dmProvider.onEvent(sourceEvent);
        }
      }

      var keyIndex = settingsProvider.privateKeyIndex!;
      EventDB.insert(keyIndex, e);
    }
  }
}
