import 'dart:developer';

import 'package:logging/logging.dart';

import '../relay/client_connected.dart';
import '../relay/relay.dart';
import '../relay/relay_info.dart';
import 'relay_local_db.dart';
import 'relay_local_mixin.dart';

/// Relay that stores messages to and retrieves them from a local database.
class RelayLocal extends Relay with RelayLocalMixin {
  /// Url to be used as url of the instance of [RelayLocal]
  static const localUrl = "Local Relay";

  /// Instance of the local database to store and retrieve events.
  RelayLocalDB relayLocalDB;

  /// Constructs a [RelayLocal] with the specified URL, relay status, and local
  /// database. A reusable URL can be found at [localUrl].
  RelayLocal(super.url, super.relayStatus, this.relayLocalDB) {
    super.relayStatus.connected = ClientConneccted.CONNECTED;
    info = RelayInfo(
      "Local Relay",
      "This is a local relay. It will cache some event.",
      "29320975df855fe34a7b45ada2421e2c741c37c0136901fe477133a91eb18b07",
      "29320975df855fe34a7b45ada2421e2c741c37c0136901fe477133a91eb18b07",
      ["1", "11", "12", "16", "33", "42", "45", "50", "95"],
      "Nostrmo",
      "0.1.0",
    );
  }

  /// Saves [event] in the local relay.
  void broadcastToLocal(Map<String, dynamic> event) {
    log(
      "Broadcasting event to local relay...\n\n${event.toString()}",
      level: Level.FINEST.value,
      name: "RelayLocal",
    );
    relayLocalDB.addEvent(event);
  }

  @override
  void callback(String? connId, List list) {
    onMessage!(this, list);
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> doConnect() async {
    return true;
  }

  @override
  RelayLocalDB getRelayLocalDB() {
    return relayLocalDB;
  }

  @override
  bool send(List message, {bool? forceSend}) {
    log(
      "Sending message to local relay...\n\n${message.toString()}",
      level: Level.FINEST.value,
      name: "RelayLocal",
    );
    if (message.isNotEmpty) {
      switch (message[0]) {
        case "EVENT":
          doEvent(null, message);
        case "REQ":
          doReq(null, message);
        case "COUNT":
          doCount(null, message);
        case "CLOSE":
        case "AUTH":
        // Don't cache this message
      }
    }
    return true;
  }
}
