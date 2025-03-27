import '../event_kind.dart';
import 'relay_local_db.dart';

/// Adds functions capable of handling COUNT, REQ and EVENT requests.
mixin RelayLocalMixin {
  /// Callback function used for returning results.
  ///
  /// [connId]: Connection ID, might be used to identify the source of the
  /// callback.
  /// [message]: List of messages that are being returned as response.
  void callback(String? connId, List<dynamic> list);

  /// Processes a COUNT message.
  ///
  /// [connId]: Connection ID, might be used to identify the source of the
  /// callback.
  /// [message]: List of messages that are being sent to the relay.
  Future<void> doCount(String? connId, List message) async {
    if (message.length < 3) {
      return;
    }
    final subscriptionId = message[1];
    final filter = message[2];
    final count = await getRelayLocalDB().doQueryCount(filter);
    final result = {"count", count};
    callback(connId, ["COUNT", subscriptionId, result]);
  }

  /// Processes an EVENT message.
  ///
  /// [connId]: Connection ID, might be used to identify the source of the
  /// callback.
  /// [message]: List of messages that are being sent to the relay.
  void doEvent(String? connId, List message) {
    if (message.length < 2) {
      return;
    }
    final event = message[1];
    final id = event["id"];
    final eventKind = event["kind"];
    final pubkey = event["pubkey"];
    switch (eventKind) {
      case EventKind.EVENT_DELETION:
        final tags = event["tags"];
        if (tags is List && tags.isNotEmpty) {
          for (var tag in tags) {
            if (tag is List && tag.isNotEmpty && tag.length > 1) {
              final k = tag[0];
              final v = tag[1];
              if (k == "e") {
                getRelayLocalDB().deleteEvent(pubkey, v);
              } else if (k == "a") {
                // TODO should add support delete by aid
              }
            }
          }
        }
      case EventKind.METADATA:
      case EventKind.CONTACT_LIST:
        // These eventkinds can only save 1 event, so delete other event first.
        getRelayLocalDB().deleteEventByKind(pubkey, eventKind);
        continue addEvent;
      addEvent:
      default:
        // maybe it shouldn't insert here, due to it doesn't had a source.
        getRelayLocalDB().addEvent(event);
    }
    callback(connId, ["OK", id, true]);
  }

  /// Processes a REQ message.
  ///
  /// [connId]: Connection ID, might be used to identify the source of the
  /// callback.
  /// [message]: List of messages that are being sent to the relay.
  Future<void> doReq(String? connId, List message) async {
    if (message.length < 3) {
      return;
    }
    final subscriptionId = message[1];
    for (var i = 2; i < message.length; i++) {
      final filter = message[i];
      final events = await getRelayLocalDB().doQueryEvent(filter); 
      for (var event in events) {
        callback(connId, ["EVENT", subscriptionId, event]);
      }
    }
    callback(connId, ["EOSE", subscriptionId]);
  }

  /// Returns a [RelayLocalDB] instance.
  RelayLocalDB getRelayLocalDB();
}
