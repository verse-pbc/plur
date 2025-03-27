import 'dart:developer';
import 'package:meta/meta.dart';

import '../subscription.dart';
import 'client_connected.dart';
import 'relay_info.dart';
import 'relay_info_util.dart';
import 'relay_status.dart';

enum WriteAccess { readOnly, writeOnly, readWrite, nothing }

abstract class Relay {
  final String url;

  RelayStatus relayStatus;

  RelayInfo? info;

  // to hold the message when the ws havn't connected and should be send after connected.
  List<List<dynamic>> pendingMessages = [];

  // to hold the message when the ws havn't authed and should be send after auth.
  List<List<dynamic>> pendingAuthedMessages = [];

  Function(Relay, List<dynamic>)? onMessage;

  // subscriptions
  final Map<String, Subscription> _subscriptions = {};

  // quries
  final Map<String, Subscription> _queries = {};

  Relay(this.url, this.relayStatus);

  /// The method to call connect function by framework.
  Future<bool> connect() async {
    try {
      relayStatus.authed = false;
      var result = await doConnect();
      if (result) {
        try {
          onConnected();
        } catch (e) {
          log("onConnected exception: $e");
        }
      }
      return result;
    } catch (e) {
      log("connection fail: $e");
      disconnect();
      return false;
    }
  }

  /// The method implement by different relays to do some real when it connecting.
  Future<bool> doConnect();

  /// The method called after relay connect success.
  Future onConnected() async {
    for (var message in pendingMessages) {
      var result = send(message);
      if (!result) {
        log("message send fail onConnected");
      }
    }

    pendingMessages.clear();
  }

  Future<void> getRelayInfo(url) async {
    info ??= await RelayInfoUtil.get(url);
  }

  bool send(List<dynamic> message, {bool? forceSend});

  Future<void> disconnect();

  /// Whether we are waiting to reconnect to this relay (due to exponential
  /// backoff from a previous error)
  @visibleForTesting
  bool waitingReconnect = false;

  /// The number of times we've attempted to reconnect to this relay since the
  /// last successful connection.
  @visibleForTesting
  int reconnectAttempts = 0;

  /// The maximum time we will wait before attempting to reconnect to
  /// this relay.
  static const int maxDelaySeconds = 32;

  /// The base delay in seconds before attempting to reconnect after an error
  /// We set this to 0 while testing to reconnect immediately.
  @visibleForTesting
  int reconnectBaseDelay = 1;

  /// Reset reconnect attempt counter
  void resetReconnectAttempts() {
    reconnectAttempts = 0;
  }

  /// Calculate delay using exponential backoff with jitter
  @protected
  Duration calculateReconnectDelay() {
    // First attempt: reconnect immediately
    if (reconnectAttempts <= 1) return Duration.zero;

    // Second attempt: wait just 1 second
    if (reconnectAttempts == 2) return const Duration(seconds: 1);

    // For subsequent attempts, use exponential backoff
    // Exponential backoff: baseDelay * 2^(attempt-2)
    // We subtract 2 from the attempt count since we're starting exponential
    // backoff from the third attempt onward.
    final int adjustedAttempt = reconnectAttempts - 2;
    final double backoffFactor = (1 << adjustedAttempt).toDouble();
    final int delaySeconds = (reconnectBaseDelay * backoffFactor).round();
    final int cappedDelaySeconds =
        delaySeconds > maxDelaySeconds ? maxDelaySeconds : delaySeconds;

    // Add jitter (±10% variation) to prevent reconnection storms
    final random =
        (DateTime.now().microsecondsSinceEpoch % 1000) / 10000; // 0.0-0.1
    final jitterFactor = 0.9 + random * 0.2; // 0.9-1.1

    return Duration(
        milliseconds: (cappedDelaySeconds * 1000 * jitterFactor).round());
  }

  void onError(String errMsg, {bool reconnect = true}) {
    log("relay error: $errMsg");
    relayStatus.onError();
    relayStatus.connected = ClientConneccted.UN_CONNECT;
    if (relayStatusCallback != null) {
      relayStatusCallback!();
    }
    disconnect();

    if (reconnect && !waitingReconnect) {
      reconnectAttempts++;
      waitingReconnect = true;

      final delay = calculateReconnectDelay();

      if (delay.inMilliseconds == 0) {
        log("Reconnecting immediately (attempt #$reconnectAttempts) for $url");
      } else {
        log("Scheduling reconnect attempt #$reconnectAttempts for $url in ${delay.inSeconds}s");
      }

      Future.delayed(delay, () {
        waitingReconnect = false;
        connect().then((success) {
          if (success) {
            // Reset attempt counter on successful connection
            resetReconnectAttempts();
          }
        });
      });
    }
  }

  /// Returns a list of all active subscriptions for this relay connection.
  List<Subscription> get subscriptions => _subscriptions.values.toList();

  /// Stores a new subscription in the relay's subscription map.
  void saveSubscription(Subscription subscription) {
    _subscriptions[subscription.id] = subscription;
  }

  /// Attempts to close a subscription with the given ID.
  /// Sends a CLOSE message to the relay if subscription exists
  /// Returns true if subscription was found and closed, false otherwise
  bool closeSubscriptionIfNeeded(String id) {
    // all subscription should be close
    var sub = _subscriptions.remove(id);
    if (sub != null) {
      send(["CLOSE", id]);
      return true;
    }
    return false;
  }

  /// Checks if this relay has any active subscriptions.
  bool get hasSubscription => _subscriptions.isNotEmpty;

  void saveQuery(Subscription subscription) {
    _queries[subscription.id] = subscription;
  }

  bool checkAndCompleteQuery(String id) {
    // all subscription should be close
    var sub = _queries.remove(id);
    if (sub != null) {
      send(["CLOSE", id]);
      return true;
    }
    return false;
  }

  bool checkQuery(String id) {
    return _queries[id] != null;
  }

  Subscription? getRequestSubscription(String id) {
    return _queries[id];
  }

  Function? relayStatusCallback;

  void dispose() {}
}
