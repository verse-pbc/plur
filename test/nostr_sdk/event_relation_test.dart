import 'package:flutter_test/flutter_test.dart';
import '../../lib/nostr_sdk/event_relation.dart';
import '../../lib/nostr_sdk/event.dart';
import '../helpers/test_data.dart';

void main() {
  group('EventRelation', () {
    test('correctly parses group ID from h tag', () {
      // Arrange
      final eventJson = TestData.groupNoteJson;

      // Act
      final event = Event.fromJson(eventJson);
      final relation = EventRelation.fromEvent(event);

      // Assert
      expect(relation.groupIdentifier?.groupId, equals("SW8N7TKHLDVZ"));
      expect(relation.groupIdentifier?.host, equals(""));
    });
  });
} 