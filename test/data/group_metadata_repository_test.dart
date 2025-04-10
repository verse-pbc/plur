import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:nostrmo/data/group_metadata_repository.dart';
import 'package:nostrmo/main.dart';
import '../helpers/test_data.dart';
import 'group_metadata_repository_test.mocks.dart';

/// Tests for the GroupMetadataRepository class
@GenerateNiceMocks([MockSpec<Nostr>()])
void main() {
  group('GroupMetadataRepository', () {
    late GroupMetadataRepository repository;
    late MockNostr mockNostr;

    // Test data
    const testPubkey = TestData.alicePubkey;
    const groupId = "test-group-123";
    const host = "wss://test.relay";
    late GroupIdentifier identifier;

    setUp(() {
      mockNostr = MockNostr();
      when(mockNostr.publicKey).thenReturn(testPubkey);
      nostr = mockNostr;
      repository = GroupMetadataRepository();
      identifier = GroupIdentifier(host, groupId);
    });

    /// Custom matcher for verifying event tags
    Matcher hasEventTag(String key, String value) => predicate<Event>(
          (event) => event.tags.any((t) => t[0] == key && t[1] == value),
          'has tag [$key, $value]',
        );

    /// Custom matcher for verifying exact number of tags
    Matcher hasTagCount(int count) => predicate<Event>(
          (event) => event.tags.length == count,
          'has exactly $count tags',
        );

    /// Custom matcher for verifying exact tag matches
    Matcher hasExactTags(List<List<String>> expectedTags) {
      final matchers = <Matcher>[
        hasTagCount(expectedTags.length),
        ...expectedTags.map((tag) => hasEventTag(tag[0], tag[1])),
      ];
      return allOf(matchers);
    }

    test('fetchGroupMetadata correctly parses metadata', () async {
      // Arrange
      final testEvent = Event.create(
        pubkey: testPubkey,
        kind: EventKind.groupMetadata,
        tags: [
          ["d", groupId],
          ["name", "Pizza Lovers"],
          ["picture", "https://pizza.com/pizza.png"],
          ["about", "a group for people who love pizza"],
          ["guidelines", "Rule #1: No pineapple"],
          ["public"],
          ["open"],
        ],
        content: "",
      );

      when(mockNostr.queryEvents(
        any,
        tempRelays: [host],
        targetRelays: [host],
        relayTypes: RelayType.onlyTemp,
        sendAfterAuth: true,
      )).thenAnswer((_) async => [testEvent]);

      // Act
      final result = await repository.fetchGroupMetadata(identifier);

      // Assert
      expect(result, isNotNull);
      expect(result!.groupId, equals(groupId));
      expect(result.name, equals("Pizza Lovers"));
      expect(result.picture, equals("https://pizza.com/pizza.png"));
      expect(result.about, equals("a group for people who love pizza"));
      expect(result.communityGuidelines, equals("Rule #1: No pineapple"));
      expect(result.public, isTrue);
      expect(result.open, isTrue);
    });

    test('setGroupMetadata correctly publishes metadata', () async {
      // Arrange
      final metadata = GroupMetadata(
        groupId,
        0,
        name: "Pizza Lovers",
        picture: "https://pizza.com/pizza.png",
        about: "a group for people who love pizza",
        communityGuidelines: "Rule #1: No pineapple",
        public: true,
        open: true,
      );

      final mockEvent = Event.create(
        pubkey: testPubkey,
        kind: EventKind.groupEditMetadata,
        tags: [],
        content: "",
      );

      when(mockNostr.sendEvent(
        any,
        tempRelays: [host],
        targetRelays: [host],
      )).thenAnswer((_) async => mockEvent);

      // Act
      final result = await repository.setGroupMetadata(metadata, host);

      // Assert
      expect(result, isTrue);

      final expectedTags = [
        ["h", groupId],
        ["name", "Pizza Lovers"],
        ["picture", "https://pizza.com/pizza.png"],
        ["about", "a group for people who love pizza"],
        ["guidelines", "Rule #1: No pineapple"],
      ];

      // Verify the event was created with exactly the expected tags
      verify(mockNostr.sendEvent(
        argThat(
          allOf(
            predicate<Event>((e) => e.kind == EventKind.groupEditMetadata),
            hasExactTags(expectedTags),
          ),
        ),
        tempRelays: [host],
        targetRelays: [host],
      )).called(1);
    });

    test('fetchGroupMetadata returns null when no event is found', () async {
      // Arrange
      when(mockNostr.queryEvents(
        any,
        tempRelays: [host],
        targetRelays: [host],
        relayTypes: RelayType.onlyTemp,
        sendAfterAuth: true,
      )).thenAnswer((_) async => []);

      // Act
      final result = await repository.fetchGroupMetadata(identifier);

      // Assert
      expect(result, isNull);
    });

    test('setGroupMetadata returns false when event sending fails', () async {
      // Arrange
      final metadata = GroupMetadata(
        groupId,
        0,
        name: "Pizza Lovers",
      );

      when(mockNostr.sendEvent(
        any,
        tempRelays: [host],
        targetRelays: [host],
      )).thenAnswer((_) async => null);

      // Act
      final result = await repository.setGroupMetadata(metadata, host);

      // Assert
      expect(result, isFalse);
    });
  });
}
