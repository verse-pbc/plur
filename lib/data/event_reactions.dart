import 'package:nostr_sdk/nostr_sdk.dart';

import '../main.dart';

class EventReactions implements FindEventInterface {
  String id;

  int replyNum = 0;

  List<Event> replies = [];

  int repostNum = 0;

  List<Event> reposts = [];

  int likeNum = 0;

  Map<String, int> likeNumMap = {};

  List<Event> likes = [];

  List<Event>? myLikeEvents;

  int zapNum = 0;

  List<Event> zaps = [];

  Map<String, int> eventIdMap = {};

  EventReactions(this.id);

  DateTime accessTime = DateTime.now();

  DateTime dataTime = DateTime.now();

  EventReactions clone() {
    return EventReactions(id)
      ..replyNum = replyNum
      ..replies = replies
      ..repostNum = repostNum
      ..reposts = reposts
      ..likeNum = likeNum
      ..likeNumMap = likeNumMap
      ..likes = likes
      ..myLikeEvents = myLikeEvents
      ..zaps = zaps
      ..zapNum = zapNum
      ..eventIdMap = eventIdMap
      ..accessTime = accessTime
      ..dataTime = dataTime;
  }

  @override
  List<Event> findEvent(String str, {int? limit = 5}) {
    List<Event> list = [];
    for (var event in replies) {
      if (event.content.contains(str)) {
        list.add(event);

        if (limit != null && list.length >= limit) {
          break;
        }
      }
    }
    return list;
  }

  void access(DateTime t) {
    accessTime = t;
  }

  static String getLikeText(Event event) {
    if (event.content == "+" || event.content.length > 3) {
      return "❤️";
    }

    return event.content;
  }

  bool onEvent(Event event) {
    dataTime = DateTime.now();

    var id = event.id;
    if (eventIdMap[id] == null) {
      eventIdMap[id] = 1;

      if (event.kind == EventKind.textNote) {
        replyNum++;
        replies.add(event);
      } else if (event.kind == EventKind.repost ||
          event.kind == EventKind.genericRepost) {
        repostNum++;
        reposts.add(event);
      } else if (event.kind == EventKind.reaction) {
        var likeText = getLikeText(event);

        var num = likeNumMap[likeText];
        num ??= 0;
        num++;
        likeNumMap[likeText] = num;

        likeNum++;

        likes.add(event);
        if (event.pubkey == nostr!.publicKey) {
          myLikeEvents ??= [];
          myLikeEvents!.add(event);
        }
      } else if (event.kind == EventKind.zap) {
        zapNum += ZapInfoUtil.getNumFromZapEvent(event);
        zaps.add(event);

        if (StringUtil.isNotBlank(event.content)) {
          replyNum++;
          replies.add(event);
        }
      }

      return true;
    }

    return false;
  }
}
