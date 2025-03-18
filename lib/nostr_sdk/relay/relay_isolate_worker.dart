import 'dart:convert';
import 'dart:isolate';
import 'dart:developer';
import 'package:flutter_socks_proxy/socks_proxy.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../event.dart';
import '../utils/string_util.dart';
import 'relay_isolate.dart';

class RelayIsolateWorker {
  RelayIsolateConfig config;

  WebSocketChannel? wsChannel;

  RelayIsolateWorker({
    required this.config,
  });

  Future<void> run() async {
    if (StringUtil.isNotBlank(config.network)) {
      // handle isolate network
      var network = config.network;
      network = network!.trim();
      SocksProxy.initProxy(proxy: network);
    }

    ReceivePort mainToSubReceivePort = ReceivePort();
    var mainToSubSendPort = mainToSubReceivePort.sendPort;
    config.subToMainSendPort.send(mainToSubSendPort);

    mainToSubReceivePort.listen(onMainToSubMessage);

    wsChannel = await handleWS();
  }

  void onMainToSubMessage(message) async {
    try {
      if (message is String) {
        // this is the msg need to sended.
        if (wsChannel != null) {
          wsChannel!.sink.add(message);
        }
      } else if (message is int) {
        // this is const msg.
        if (message == RelayIsolateMsgs.connect) {
          // receive the connect command!
          if (wsChannel == null || wsChannel!.closeCode != null) {
            // the websocket is close, close again and try to connect.
            _closeWS(wsChannel);
            wsChannel = await handleWS();
          } else {
            // TODO the websocket is connected, try to check or reconnect.
          }
        } else if (message == RelayIsolateMsgs.disconnect) {
          _closeWS(wsChannel);
          config.subToMainSendPort.send(RelayIsolateMsgs.disconnected);
        }
      }
    } catch (e) {
      // catch error on handle mainToSubMessage, close, and it will reconnect again.
      _closeWS(wsChannel);
      config.subToMainSendPort.send(RelayIsolateMsgs.disconnected);
    }
  }

  static void runRelayIsolate(RelayIsolateConfig config) {
    var worker = RelayIsolateWorker(config: config);
    worker.run();
  }

  Future<WebSocketChannel?> handleWS() async {
    String url = config.url;
    SendPort subToMainSendPort = config.subToMainSendPort;

    final wsUrl = Uri.parse(url);
    try {
      log("Begin to connect ${config.url}");
      wsChannel = WebSocketChannel.connect(wsUrl);
      wsChannel!.stream.listen((message) {
        List<dynamic> json = jsonDecode(message);
        if (json.length > 2) {
          final messageType = json[0];
          if (messageType == 'EVENT') {
            final event = Event.fromJson(json[2]);
            if (config.eventCheck) {
              // event need to check
              if (!event.isValid || !event.isSigned) {
                // check false
                return;
              }
            }
          }
        }
        subToMainSendPort.send(json);
      }, onError: (error) async {
        log("Websocket stream for $url error: $error");
        _closeWS(wsChannel);
        subToMainSendPort.send(RelayIsolateMsgs.disconnected);
      }, onDone: () {
        log("Websocket stream closed by remote $url");
        _closeWS(wsChannel);
        subToMainSendPort.send(RelayIsolateMsgs.disconnected);
      });
      await wsChannel!.ready;
      log("Connect complete! ${config.url}");
      subToMainSendPort.send(RelayIsolateMsgs.connected);

      return wsChannel;
    } catch (e) {
      _closeWS(wsChannel);
      subToMainSendPort.send(RelayIsolateMsgs.disconnected);
    }

    return null;
  }

  bool _closeWS(WebSocketChannel? wsChannel) {
    if (wsChannel == null) {
      return false;
    }

    try {
      wsChannel.sink.close();
    } catch (e) {
      log("ws close error: $e");
    }

    wsChannel = null;
    return true;
  }
}
