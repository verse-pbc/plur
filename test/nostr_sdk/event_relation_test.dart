import 'package:flutter_test/flutter_test.dart';
import '../../lib/nostr_sdk/event_relation.dart';
import '../../lib/nostr_sdk/event.dart';
import '../helpers/test_data.dart';

void main() {
  group('EventRelation', () {
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
  });
} 