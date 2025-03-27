import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_sdk/relay/relay.dart';
import 'package:nostr_sdk/relay/relay_status.dart';
import 'testable_relay.dart';

void main() {
  group('Relay reconnection logic', () {
    late TestableRelay relay;
    late RelayStatus relayStatus;

    setUp(() {
      relayStatus = RelayStatus('wss://test.relay.com');
      relay = TestableRelay('wss://test.relay.com', relayStatus);

      // Set a short delay for faster tests
      relay.reconnectBaseDelayInSeconds = 0;
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

    test('stops reconnecting after maximum attempts', () {
      const maxAttempts = Relay.maxReconnectAttempts;

      // Override waiting reconnect flag for testing
      for (var i = 0; i < maxAttempts + 1; i++) {
        relay.waitingReconnect = false;
        relay.onError('Test error $i', reconnect: true);
      }

      // Should have reached max attempts
      expect(relay.reconnectAttempts, equals(maxAttempts));

      // The last error should not have scheduled a reconnect
      expect(relay.waitingReconnect, isFalse);
    });

    test(
        'reconnection delay follows immediate, short, then exponential pattern',
        () {
      // Set a fixed base delay to make calculations predictable
      relay.reconnectBaseDelayInSeconds = 10;

      // First attempt should reconnect immediately (0 delay)
      final delay1 = relay.calculateReconnectDelayForAttempt(1);
      expect(delay1, equals(Duration.zero));

      // Second attempt should wait 1 second
      final delay2 = relay.calculateReconnectDelayForAttempt(2);
      expect(delay2, equals(const Duration(seconds: 1)));

      // Third attempt should start exponential backoff (10 seconds)
      final delay3 = relay.calculateReconnectDelayForAttempt(3);

      // Fourth attempt (10 * 2 = 20 seconds)
      final delay4 = relay.calculateReconnectDelayForAttempt(4);

      // Fifth attempt (10 * 4 = 40 seconds)
      final delay5 = relay.calculateReconnectDelayForAttempt(5);

      // Verify exponential increase (accounting for jitter)
      expect(delay3.inMilliseconds > delay2.inMilliseconds, isTrue);
      expect(delay4.inMilliseconds > delay3.inMilliseconds, isTrue);
      expect(delay5.inMilliseconds > delay4.inMilliseconds, isTrue);

      // Check that the exponential pattern is roughly correct
      // We allow for jitter (±10%)
      // Third attempt should use exponential backoff with a factor of 2^1 = 2
      // The delay should be roughly 2 * base delay = 20 seconds with some jitter
      final int approxDelay3Seconds = delay3.inMilliseconds ~/ 1000;
      expect(approxDelay3Seconds >= 18, isTrue,
          reason: "Third attempt delay too short: ${delay3.inSeconds}s");
      expect(approxDelay3Seconds <= 22, isTrue,
          reason: "Third attempt delay too long: ${delay3.inSeconds}s");

      // Fourth attempt should use exponential backoff with a factor of 2^2 = 4
      // The delay should be roughly 4 * base delay = 40 seconds with some jitter
      final int approxDelay4Seconds = delay4.inMilliseconds ~/ 1000;
      expect(approxDelay4Seconds >= 36, isTrue,
          reason: "Fourth attempt delay too short: ${delay4.inSeconds}s");
      expect(approxDelay4Seconds <= 44, isTrue,
          reason: "Fourth attempt delay too long: ${delay4.inSeconds}s");

      // Fifth attempt should use exponential backoff with a factor of 2^3 = 8
      // The delay should be roughly 8 * base delay = 80 seconds with some jitter
      final int approxDelay5Seconds = delay5.inMilliseconds ~/ 1000;
      expect(approxDelay5Seconds >= 72, isTrue,
          reason: "Fifth attempt delay too short: ${delay5.inSeconds}s");
      expect(approxDelay5Seconds <= 88, isTrue,
          reason: "Fifth attempt delay too long: ${delay5.inSeconds}s");
    });
  });
}
