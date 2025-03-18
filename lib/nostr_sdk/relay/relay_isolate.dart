import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:isolate';

import 'package:logging/logging.dart';

import 'client_connected.dart';
import 'relay.dart';
import 'relay_isolate_worker.dart';
import 'relay_status.dart';

// The real relay, whick is run in other isolate.
// It can move jsonDecode and event id check and sign check from main Isolate
class RelayIsolate extends Relay {
  bool eventSignCheck;

  String? relayNetwork;

  RelayIsolate(
    String url,
    RelayStatus relayStatus, {
    this.eventSignCheck = false,
    this.relayNetwork,
  }) : super(url, relayStatus);

  Isolate? isolate;

  ReceivePort? subToMainReceivePort;

  SendPort? mainToSubSendPort;

  Completer<bool>? relayConnectResultComplete;

  @override
  Future<bool> doConnect() async {
    if (subToMainReceivePort == null) {
      relayStatus.connected = ClientConneccted.CONNECTING;
      getRelayInfo(url);

      // never run isolate, begin to run
      subToMainReceivePort = ReceivePort("relay_stm_$url");
      subToMainListener(subToMainReceivePort!);

      relayConnectResultComplete = Completer();
      isolate = await Isolate.spawn(
        RelayIsolateWorker.runRelayIsolate,
        RelayIsolateConfig(
          url: url,
          subToMainSendPort: subToMainReceivePort!.sendPort,
          eventCheck: eventSignCheck,
          network: relayNetwork,
        ),
      );
      // isolate has run and return a completer.future, wait for subToMain msg to complete this completer.
      return await relayConnectResultComplete!.future;
    } else {
      // the isolate had bean run
      if (relayStatus.connected == ClientConneccted.CONNECTED) {
        // relay has bean connected, return true, but also send a connect message.
        mainToSubSendPort!.send(RelayIsolateMsgs.connect);
        return true;
      } else {
        // haven't connected
        if (relayConnectResultComplete != null) {
          return relayConnectResultComplete!.future;
        } else {
          // this maybe relay had disconnect after connected, try to connected again.
          if (mainToSubSendPort != null) {
            relayStatus.connected = ClientConneccted.CONNECTING;
            // send connect msg
            mainToSubSendPort!.send(RelayIsolateMsgs.connect);
            // wait connected msg.
            relayConnectResultComplete = Completer();
            return await relayConnectResultComplete!.future;
          }
        }
      }
    }

    return false;
  }

  @override
  Future<void> disconnect() async {
    if (relayStatus.connected != ClientConneccted.UN_CONNECT) {
      relayStatus.connected = ClientConneccted.UN_CONNECT;
      if (mainToSubSendPort != null) {
        mainToSubSendPort!.send(RelayIsolateMsgs.disconnect);
      }
    }
  }

  @override
  bool send(List message, {bool? forceSend}) {
    if (forceSend == true ||
        (mainToSubSendPort != null &&
            relayStatus.connected == ClientConneccted.CONNECTED)) {
      final encoded = jsonEncode(message);
      log(
        "Sending message to $url...\n\n$encoded", 
        level: Level.FINEST.value, 
        name: "RelayIsolate",
      );
      mainToSubSendPort!.send(encoded);
      return true;
    }

    return false;
  }

  void subToMainListener(ReceivePort receivePort) {
    receivePort.listen((message) {
      if (message is int) {
        // this is const msg.
        if (message == RelayIsolateMsgs.connected) {
          relayStatus.connected = ClientConneccted.CONNECTED;
          if (relayStatusCallback != null) {
            relayStatusCallback!();
          }
          _relayConnectComplete(true);
        } else if (message == RelayIsolateMsgs.disconnected) {
          onError("Websocket error $url", reconnect: true);
          _relayConnectComplete(false);
        }
      } else if (message is List && onMessage != null) {
        onMessage!(this, message);
      } else if (message is SendPort) {
        mainToSubSendPort = message;
      }
    });
  }

  void _relayConnectComplete(bool result) {
    if (relayConnectResultComplete != null) {
      relayConnectResultComplete!.complete(result);
      relayConnectResultComplete = null;
    }
  }

  @override
  void dispose() {
    if (isolate != null) {
      isolate!.kill();
    }
  }
}

class RelayIsolateConfig {
  final String url;
  final SendPort subToMainSendPort;
  final bool eventCheck;
  String? network;

  RelayIsolateConfig({
    required this.url,
    required this.subToMainSendPort,
    required this.eventCheck,
    this.network,
  });
}

class RelayIsolateMsgs {
  /// Message for opening a connection.
  static const int connect = 1;

  /// Message for closing a connection.
  static const int disconnect = 2;

  /// Message that signals that a connection is open.
  static const int connected = 101;

  /// Message that signals that a connection is closed.
  static const int disconnected = 102;
}
