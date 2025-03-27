import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_sdk/relay/relay_status.dart';
import 'testable_relay.dart';

void main() {
  group('Relay reconnection logic', () {
    late TestableRelay relay;
    late RelayStatus relayStatus;

    setUp(() {
      relayStatus = RelayStatus('wss://test.relay.com');
      relay = TestableRelay('wss://test.relay.com', relayStatus);
    });

    test('onError sets the waiting reconnect flag with reconnect=true', () {
      // Act
      relay.onError('Test error', reconnect: true);

      // Assert
      expect(relay.waitingReconnect, isTrue);
    });

    test('onError does not set the waiting reconnect flag with reconnect=false',
        () {
      // Act
      relay.onError('Test error', reconnect: false);

      // Assert
      expect(relay.waitingReconnect, isFalse);
    });

    test('reconnect attempts counter increases with each error', () async {
      // Simulate 3 consecutive errors
      relay.onError('Test error 1', reconnect: true);
      expect(relay.reconnectAttempts, equals(1));

      // Reset waiting flag to simulate a new error after the reconnect timer
      relay.waitingReconnect = false;

      relay.onError('Test error 2', reconnect: true);
      expect(relay.reconnectAttempts, equals(2));

      // Reset waiting flag to simulate a new error after the reconnect timer
      relay.waitingReconnect = false;

      relay.onError('Test error 3', reconnect: true);
      expect(relay.reconnectAttempts, equals(3));
    });

    test('reconnect attempts counter resets after successful connection',
        () async {
      // Simulate errors
      relay.onError('Test error 1', reconnect: true);
      relay.onError('Test error 2',
          reconnect: false); // This shouldn't increase the counter
      expect(relay.reconnectAttempts, equals(1));

      // Simulate successful connection
      relay.resetReconnectAttempts();

      // Check counter reset
      expect(relay.reconnectAttempts, equals(0));
    });

    test(
        'reconnection delay follows immediate, short, then exponential pattern up to max',
        () {
      // First attempt should reconnect immediately (0 delay)
      final delay1 = relay.calculateReconnectDelayForAttempt(1);
      expect(delay1, equals(Duration.zero));

      // Second attempt should wait 1 second
      final delay2 = relay.calculateReconnectDelayForAttempt(2);
      expect(delay2, equals(const Duration(seconds: 1)));

      // Third attempt should start exponential backoff
      final delay3 = relay.calculateReconnectDelayForAttempt(3);
      final delay4 = relay.calculateReconnectDelayForAttempt(4);
      final delay5 = relay.calculateReconnectDelayForAttempt(5);
      // Test that higher attempts are properly capped at 32 seconds
      final delay8 = relay.calculateReconnectDelayForAttempt(8);

      // Check specific delays (accounting for ±10% jitter)
      // Third attempt: 1 * 2^1 = 2 seconds ±10%
      expect(delay3.inMilliseconds >= 1800, isTrue,
          reason: "Third attempt delay too short: ${delay3.inMilliseconds}ms");
      expect(delay3.inMilliseconds <= 2200, isTrue,
          reason: "Third attempt delay too long: ${delay3.inMilliseconds}ms");

      // Fourth attempt: 1 * 2^2 = 4 seconds ±10%
      expect(delay4.inMilliseconds >= 3600, isTrue,
          reason: "Fourth attempt delay too short: ${delay4.inMilliseconds}ms");
      expect(delay4.inMilliseconds <= 4400, isTrue,
          reason: "Fourth attempt delay too long: ${delay4.inMilliseconds}ms");

      // Fifth attempt: 1 * 2^3 = 8 seconds ±10%
      expect(delay5.inMilliseconds >= 7200, isTrue,
          reason: "Fifth attempt delay too short: ${delay5.inMilliseconds}ms");
      expect(delay5.inMilliseconds <= 8800, isTrue,
          reason: "Fifth attempt delay too long: ${delay5.inMilliseconds}ms");

      expect(delay8.inMilliseconds >= 28800, isTrue, // 32s * 0.9 = 28.8s
          reason: "Eighth attempt delay too short: ${delay8.inMilliseconds}ms");
      expect(delay8.inMilliseconds <= 35200, isTrue, // 32s * 1.1 = 35.2s
          reason: "Eighth attempt delay too long: ${delay8.inMilliseconds}ms");
    });
  });
}
