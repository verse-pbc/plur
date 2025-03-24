import 'package:nostr_sdk/nostr_sdk.dart';

class EventTraceInfo {
  Event event;

  late EventRelation eventRelation;

  EventTraceInfo(this.event) {
    eventRelation = EventRelation.fromEvent(event);
  }
}
