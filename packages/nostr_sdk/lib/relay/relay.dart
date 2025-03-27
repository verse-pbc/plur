import 'dart:developer';

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

  Relay(this.url, this.relayStatus) {
    _connectImplementation = _defaultConnectImplementation;
  }

  /// The method to call connect function by framework.
  Future<bool> connect() async {
    return _connectImplementation();
  }

  /// Implementation function that can be replaced in tests
  late Future<bool> Function() _connectImplementation;

  /// For testing - allows replacing the connect implementation
  void setConnectImplementation(Future<bool> Function() implementation) {
    _connectImplementation = implementation;
  }

  /// Reset to the default connect implementation
  void resetConnectImplementation() {
    _connectImplementation = _defaultConnectImplementation;
  }

  /// Default implementation of connect
  Future<bool> _defaultConnectImplementation() async {
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

  /// The medhod called after relay connect success.
  Future onConnected() async {
    for (var message in pendingMessages) {
      // TODO To check result? and how to handle if send fail?
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

  bool _waitingReconnect = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  /// For testing purposes - expose the waiting reconnect state
  bool get isWaitingReconnect => _waitingReconnect;

  /// For testing purposes - expose reconnect attempts
  int get reconnectAttempts => _reconnectAttempts;

  /// For testing purposes - expose max reconnect attempts
  int get maxReconnectAttempts => _maxReconnectAttempts;

  /// For testing purposes - set the waiting reconnect flag
  void setWaitingReconnect(bool value) => _waitingReconnect = value;

  /// The base delay in seconds before attempting to reconnect after an error
  /// Can be overridden in subclasses for testing
  int get reconnectBaseDelayInSeconds => 10;

  /// Reset reconnect attempt counter
  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }

  /// Calculate delay using exponential backoff with jitter
  Duration _calculateReconnectDelay() {
    // First attempt: reconnect immediately
    if (_reconnectAttempts <= 1) return Duration.zero;

    // Second attempt: wait just 1 second
    if (_reconnectAttempts == 2) return const Duration(seconds: 1);

    // For subsequent attempts, use exponential backoff
    // Exponential backoff: baseDelay * 2^(attempt-2)
    // We subtract 2 from the attempt count since we're starting exponential backoff
    // from the third attempt onward
    final int adjustedAttempt = _reconnectAttempts - 2;
    final double backoffFactor =
        adjustedAttempt > 8 ? 256.0 : (1 << adjustedAttempt).toDouble();
    final int delaySeconds =
        (reconnectBaseDelayInSeconds * backoffFactor).round();
    final int cappedDelaySeconds = delaySeconds > 300 ? 300 : delaySeconds;

    // Add jitter (±10% variation) to prevent reconnection storms
    final random =
        (DateTime.now().microsecondsSinceEpoch % 1000) / 10000; // 0.0-0.1
    final jitterFactor = 0.9 + random * 0.2; // 0.9-1.1

    return Duration(
        milliseconds: (cappedDelaySeconds * 1000 * jitterFactor).round());
  }

  /// For testing - expose the calculate reconnect delay method
  Duration calculateReconnectDelayForAttempt(int attemptNumber) {
    final oldAttempts = _reconnectAttempts;
    _reconnectAttempts = attemptNumber;
    final result = _calculateReconnectDelay();
    _reconnectAttempts = oldAttempts;
    return result;
  }

  void onError(String errMsg, {bool reconnect = true}) {
    log("relay error: $errMsg");
    relayStatus.onError();
    relayStatus.connected = ClientConneccted.UN_CONNECT;
    if (relayStatusCallback != null) {
      relayStatusCallback!();
    }
    disconnect();

    if (reconnect && !_waitingReconnect) {
      _reconnectAttempts++;
      _waitingReconnect = true;

      // If we've reached or exceeded maximum reconnect attempts, log and don't attempt again
      if (_reconnectAttempts >= _maxReconnectAttempts) {
        log("Maximum reconnect attempts ($_maxReconnectAttempts) reached for $url, giving up.");
        _waitingReconnect = false;
        return;
      }

      final delay = _calculateReconnectDelay();

      if (delay.inMilliseconds == 0) {
        log("Reconnecting immediately (attempt #$_reconnectAttempts) for $url");
      } else {
        log("Scheduling reconnect attempt #$_reconnectAttempts for $url in ${delay.inSeconds}s");
      }

      Future.delayed(delay, () {
        _waitingReconnect = false;
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
