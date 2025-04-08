import 'dart:convert';
import 'dart:developer';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'client_connected.dart';
import 'relay.dart';
import 'relay_status.dart';

class RelayBase extends Relay {
  RelayBase(String url, RelayStatus relayStatus) : super(url, relayStatus);

  WebSocketChannel? _wsChannel;

  @override
  Future<bool> doConnect() async {
    if (_wsChannel != null && _wsChannel!.closeCode == null) {
      log("connection break: $url");
      return true;
    }

    try {
      relayStatus.connected = ClientConnected.connecting;
      getRelayInfo(url);

      final wsUrl = Uri.parse(url);
      log("Connect begin: $url");
      _wsChannel = WebSocketChannel.connect(wsUrl);
      log("Connect complete: $url");
      _wsChannel!.stream.listen((message) {
        if (onMessage != null) {
          final List<dynamic> json = jsonDecode(message);
          onMessage!(this, json);
        }
      }, onError: (error) async {
        log("Websocket error $url: $error");
        onError("Websocket error $url", shouldReconnect: true);
      }, onDone: () {
        onError("Websocket stream closed by remote: $url",
            shouldReconnect: true);
      });
      relayStatus.connected = ClientConnected.connected;
      if (relayStatusCallback != null) {
        relayStatusCallback!();
      }
      return true;
    } catch (e) {
      onError(e.toString(), shouldReconnect: true);
    }
    return false;
  }

  @override
  bool send(List<dynamic> message, {bool? forceSend}) {
    if (forceSend == true ||
        (_wsChannel != null &&
            relayStatus.connected == ClientConnected.connected)) {
      try {
        final encoded = jsonEncode(message);
        _wsChannel!.sink.add(encoded);
        return true;
      } catch (e) {
        onError(e.toString(), shouldReconnect: true);
      }
    }
    return false;
  }

  @override
  Future<void> disconnect() async {
    try {
      relayStatus.connected = ClientConnected.disconnected;
      if (_wsChannel != null) {
        await _wsChannel!.sink.close();
      }
    } finally {
      _wsChannel = null;
    }
  }
}
