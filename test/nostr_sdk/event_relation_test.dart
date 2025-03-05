import 'package:flutter_test/flutter_test.dart';
import 'package:nostrmo/nostr_sdk/event_kind.dart';
import 'package:nostrmo/nostr_sdk/nip19/nip19.dart';
import '../../lib/nostr_sdk/event_relation.dart';
import '../../lib/nostr_sdk/event.dart';
import '../helpers/test_data.dart';

void main() {

  group('EventRelation tag processing', () {
    test('processes p tag correctly', () {
      const pubkey = TestData.bobPubkey;
      
      // Case 1: When content doesn't contain nip19 references
      var testEvent = Event.create(
        pubkey: TestData.alicePubkey,
        kind: 1,
        tags: [['p', pubkey]],
        content: 'random content',
      );
      var relation = EventRelation.fromEvent(testEvent);
      expect(relation.tagPList, contains(pubkey));

      // Case 2: When content contains nip19 reference - should skip
      testEvent = Event.create(
        pubkey: TestData.alicePubkey,
        kind: 1,
        tags: [['p', pubkey]],
        content: 'nostr:${Nip19.encodePubKey(pubkey)}',
      );
      relation = EventRelation.fromEvent(testEvent);
      expect(relation.tagPList, isEmpty);
    });

    test('processes e tag correctly', () {
      // Case 1: Basic e tag
      var testEvent = Event.create(
        pubkey: TestData.alicePubkey,
        kind: 1,
        tags: [['e', 'event123']],
        content: 'test content',
      );
      var relation = EventRelation.fromEvent(testEvent);
      expect(relation.rootId, 'event123');

      // Case 2: Root marker
      testEvent = Event.create(
        pubkey: TestData.alicePubkey,
        kind: 1,
        tags: [['e', 'root123', 'relay.com', 'root']],
        content: 'test content',
      );
      relation = EventRelation.fromEvent(testEvent);
      expect(relation.rootId, equals('root123'));
      expect(relation.rootRelayAddr, equals('relay.com'));

      // Case 3: Reply marker
      testEvent = Event.create(
        pubkey: TestData.alicePubkey,
        kind: 1,
        tags: [['e', 'reply123', 'relay.com', 'reply']],
        content: 'test content',
      );
      testEvent.sources = ['wss://test.relay'];
      relation = EventRelation.fromEvent(testEvent);
      expect(relation.replyId, equals('reply123'));
      expect(relation.replyRelayAddr, equals('relay.com'));

      // Case 4: Mention marker should be skipped
      testEvent = Event.create(
        pubkey: TestData.alicePubkey,
        kind: 1,
        tags: [['e', 'mention123', 'relay.com', 'mention']],
        content: 'test content',
      );
      relation = EventRelation.fromEvent(testEvent);
      expect(relation.tagEList, isEmpty);
    });

    test('processes subject tag', () {
      var testEvent = Event.create(
        pubkey: TestData.alicePubkey,
        kind: 1,
        tags: [['subject', 'Test Subject']],
        content: 'test content',
      );
      var relation = EventRelation.fromEvent(testEvent);
      expect(relation.subject, equals('Test Subject'));
    });

    test('processes content-warning tag', () {
      var testEvent = Event.create(
        pubkey: TestData.alicePubkey,
        kind: 1,
        tags: [['content-warning', 'any value']],
        content: 'test content',
      );
      var relation = EventRelation.fromEvent(testEvent);
      expect(relation.warning, isTrue);
    });

    test('processes a tag', () {
      var testEvent = Event.create(
        pubkey: TestData.alicePubkey,
        kind: 1,
        tags: [['a', '30023:abc123:test']],
        content: 'test content',
      );
      var relation = EventRelation.fromEvent(testEvent);
      expect(relation.aId, isNotNull);
      expect(relation.aId?.toAString(), equals('30023:abc123:test'));
    });

    test('processes zap tag', () {
      var testEvent = Event.create(
        pubkey: TestData.alicePubkey,
        kind: 1,
        tags: [['zap', TestData.bobPubkey, 'relay.com', '2.0']],
        content: 'test content',
      );
      var relation = EventRelation.fromEvent(testEvent);
      expect(relation.zapInfos, hasLength(1));
    });

    test('processes description tag for zap event', () {
      var testEvent = Event.create(
        pubkey: TestData.alicePubkey,
        kind: EventKind.ZAP,
        tags: [['description', '{"content":"inner zap content","other":"value"}']],
        content: '{"content":"test zap content","other":"value"}',
      );
      testEvent.sources = ['wss://test.relay'];
      var relation = EventRelation.fromEvent(testEvent);
      expect(relation.innerZapContent, equals('inner zap content'));
    });

    test('processes imeta tag', () {
      var testEvent = Event.create(
        pubkey: TestData.alicePubkey,
        kind: 1,
        tags: [['imeta', 'url image.com/image.jpg', 'dim 123x456', 'size 1000']],
        content: 'test content',
      );
      var relation = EventRelation.fromEvent(testEvent);
      expect(relation.fileMetadatas, isNotEmpty);
      final metadata = relation.fileMetadatas['image.com/image.jpg'];
      expect(metadata, isNotNull);
      expect(metadata?.url, equals('image.com/image.jpg'));
      expect(metadata?.dim, equals('123x456'));
      expect(metadata?.size, equals("1000"));
    });


    test('correctly parses group identifier from h tag', () {
      // Arrange
      final eventJson = TestData.groupNoteJson;
      const relay = "wss://communities.nos.social";

      // Act
      final event = Event.fromJson(eventJson);
      event.sources = [relay];
      final relation = EventRelation.fromEvent(event);

      // Assert
      expect(relation.groupIdentifier?.groupId, equals("SW8N7TKHLDVZ"));
      expect(relation.groupIdentifier?.host, equals(relay));
    });

    test("groupIdentifier fails to parse when we can't find relay", () {
      // Arrange
      final eventJson = TestData.groupNoteJson;

      // Act
      final event = Event.fromJson(eventJson);
      final relation = EventRelation.fromEvent(event);

      // Assert
      expect(relation.groupIdentifier, isNull);
    });

    test('ignores unknown tags', () {
      var testEvent = Event.create(
        pubkey: TestData.alicePubkey,
        kind: 1,
        tags: [['unknown', 'value']],
        content: 'test content',
      );
      var relation = EventRelation.fromEvent(testEvent);
      expect(relation.tagPList, isEmpty);
      expect(relation.tagEList, isEmpty);
      expect(relation.subject, isNull);
      expect(relation.warning, isFalse);
      expect(relation.aId, isNull);
      expect(relation.zapInfos, isEmpty);
      expect(relation.fileMetadatas, isEmpty);
      expect(relation.groupIdentifier, isNull);
    });
  });
} 