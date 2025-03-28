import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:nostrmo/util/notification_util.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import '../helpers/test_data.dart';
import 'notification_util_test.mocks.dart';

@GenerateMocks([Nostr])
void main() {
  group('NotificationUtil Token Registration Tests', () {
    late MockNostr mockNostr;
    const testToken = 'test_fcm_token';
    const testRelayUrl = 'wss://test.relay';

    setUp(() {
      mockNostr = MockNostr();
      when(mockNostr.publicKey).thenReturn(TestData.alicePubkey);
    });

    test('registerTokenWithRelay success', () async {
      // Create a properly signed event for the mock response
      final event = Event(
        TestData.alicePubkey,
        3079,
        [
          [
            'expiration',
            (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 7 * 24 * 60 * 60)
                .toString()
          ]
        ],
        testToken,
      );
      event.sign(TestData.aliceSecretKey);

      when(mockNostr.sendEvent(any, tempRelays: [testRelayUrl]))
          .thenAnswer((_) async => event);

      final result = await NotificationUtil.registerTokenWithRelay(
        token: testToken,
        nostr: mockNostr,
        relayUrl: testRelayUrl,
      );
      expect(result, true);

      final eventCaptor =
          verify(mockNostr.sendEvent(captureAny, tempRelays: [testRelayUrl]))
              .captured
              .single as Event;
      expect(eventCaptor.kind, 3079);
      expect(eventCaptor.content, testToken);
      expect(eventCaptor.pubkey, TestData.alicePubkey);
    });

    test('registerTokenWithRelay failure', () async {
      when(mockNostr.sendEvent(any, tempRelays: [testRelayUrl]))
          .thenAnswer((_) async => null);

      final result = await NotificationUtil.registerTokenWithRelay(
        token: testToken,
        nostr: mockNostr,
        relayUrl: testRelayUrl,
      );
      expect(result, false);

      final eventCaptor =
          verify(mockNostr.sendEvent(captureAny, tempRelays: [testRelayUrl]))
              .captured
              .single as Event;
      expect(eventCaptor.kind, 3079);
      expect(eventCaptor.content, testToken);
      expect(eventCaptor.pubkey, TestData.alicePubkey);
    });

    test('registerTokenWithRelay throws exception', () async {
      when(mockNostr.sendEvent(any, tempRelays: [testRelayUrl]))
          .thenThrow(Exception('Test error'));

      final result = await NotificationUtil.registerTokenWithRelay(
        token: testToken,
        nostr: mockNostr,
        relayUrl: testRelayUrl,
      );
      expect(result, false);

      final eventCaptor =
          verify(mockNostr.sendEvent(captureAny, tempRelays: [testRelayUrl]))
              .captured
              .single as Event;
      expect(eventCaptor.kind, 3079);
      expect(eventCaptor.content, testToken);
      expect(eventCaptor.pubkey, TestData.alicePubkey);
    });

    test('deregisterTokenWithRelay success', () async {
      // Create a properly signed event for the mock response
      final event = Event(
        TestData.alicePubkey,
        3080,
        [
          [
            'expiration',
            (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 7 * 24 * 60 * 60)
                .toString()
          ]
        ],
        testToken,
      );
      event.sign(TestData.aliceSecretKey);

      when(mockNostr.sendEvent(any, tempRelays: [testRelayUrl]))
          .thenAnswer((_) async => event);

      final result = await NotificationUtil.deregisterTokenWithRelay(
        token: testToken,
        nostr: mockNostr,
        relayUrl: testRelayUrl,
      );
      expect(result, true);

      final eventCaptor =
          verify(mockNostr.sendEvent(captureAny, tempRelays: [testRelayUrl]))
              .captured
              .single as Event;
      expect(eventCaptor.kind, 3080);
      expect(eventCaptor.content, testToken);
      expect(eventCaptor.pubkey, TestData.alicePubkey);
    });

    test('deregisterTokenWithRelay failure', () async {
      when(mockNostr.sendEvent(any, tempRelays: [testRelayUrl]))
          .thenAnswer((_) async => null);

      final result = await NotificationUtil.deregisterTokenWithRelay(
        token: testToken,
        nostr: mockNostr,
        relayUrl: testRelayUrl,
      );
      expect(result, false);

      final eventCaptor =
          verify(mockNostr.sendEvent(captureAny, tempRelays: [testRelayUrl]))
              .captured
              .single as Event;
      expect(eventCaptor.kind, 3080);
      expect(eventCaptor.content, testToken);
      expect(eventCaptor.pubkey, TestData.alicePubkey);
    });

    test('deregisterTokenWithRelay throws exception', () async {
      when(mockNostr.sendEvent(any, tempRelays: [testRelayUrl]))
          .thenThrow(Exception('Test error'));

      final result = await NotificationUtil.deregisterTokenWithRelay(
        token: testToken,
        nostr: mockNostr,
        relayUrl: testRelayUrl,
      );
      expect(result, false);

      final eventCaptor =
          verify(mockNostr.sendEvent(captureAny, tempRelays: [testRelayUrl]))
              .captured
              .single as Event;
      expect(eventCaptor.kind, 3080);
      expect(eventCaptor.content, testToken);
      expect(eventCaptor.pubkey, TestData.alicePubkey);
    });

    test('registration events have valid expiration timestamps', () async {
      // Create properly signed events for the mock responses
      final registerEvent = Event(
        TestData.alicePubkey,
        3079,
        [
          [
            'expiration',
            (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 7 * 24 * 60 * 60)
                .toString()
          ]
        ],
        testToken,
      );
      registerEvent.sign(TestData.aliceSecretKey);

      final deregisterEvent = Event(
        TestData.alicePubkey,
        3080,
        [
          [
            'expiration',
            (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 7 * 24 * 60 * 60)
                .toString()
          ]
        ],
        testToken,
      );
      deregisterEvent.sign(TestData.aliceSecretKey);

      when(mockNostr.sendEvent(any, tempRelays: [testRelayUrl]))
          .thenAnswer((realInvocation) async {
        final event = realInvocation.positionalArguments[0] as Event;
        return event.kind == 3079 ? registerEvent : deregisterEvent;
      });

      // Perform registration and deregistration
      await NotificationUtil.registerTokenWithRelay(
        token: testToken,
        nostr: mockNostr,
        relayUrl: testRelayUrl,
      );
      await NotificationUtil.deregisterTokenWithRelay(
        token: testToken,
        nostr: mockNostr,
        relayUrl: testRelayUrl,
      );

      // Verify expiration timestamps
      final events =
          verify(mockNostr.sendEvent(captureAny, tempRelays: [testRelayUrl]))
              .captured;
      for (final event in events) {
        final expirationTag =
            (event as Event).tags.firstWhere((tag) => tag[0] == 'expiration');
        final expirationTimestamp = int.parse(expirationTag[1]);
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        // Verify expiration is approximately 7 days in the future (with 5 second tolerance)
        const sevenDaysInSeconds = 7 * 24 * 60 * 60;
        expect(
          (expirationTimestamp - now - sevenDaysInSeconds).abs(),
          lessThan(5), // 5 second tolerance
        );
      }
    });
  });
}
