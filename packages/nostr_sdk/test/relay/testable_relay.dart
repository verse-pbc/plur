import 'package:nostr_sdk/relay/relay.dart';
import 'package:nostr_sdk/relay/relay_status.dart';

/// A testable version of Relay that exposes internals for testing
class TestableRelay extends Relay {
  TestableRelay(String url, RelayStatus relayStatus) : super(url, relayStatus);

  bool _shouldConnectSucceed = true;

  @override
  Future<bool> connect() async => _shouldConnectSucceed;

  @override
  Future<bool> doConnect() async => true;

  @override
  Future<void> disconnect() async {}

  @override
  bool send(List<dynamic> message, {bool? forceSend}) => true;

  // Control test behavior
  void setShouldConnectSucceed(bool value) {
    _shouldConnectSucceed = value;
  }

  Duration calculateReconnectDelayForAttempt(int attemptNumber) {
    final oldAttempts = reconnectAttempts;
    reconnectAttempts = attemptNumber;
    final result = calculateReconnectDelay();
    reconnectAttempts = oldAttempts;
    return result;
  }
}
