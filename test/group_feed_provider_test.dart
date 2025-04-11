import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';

import 'group_feed_provider_test.mocks.dart';

@GenerateMocks([ListProvider])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GroupFeedProvider', () {
    late MockListProvider mockListProvider;
    late GroupFeedProvider groupFeedProvider;

    setUp(() {
      mockListProvider = MockListProvider();
      groupFeedProvider = GroupFeedProvider(mockListProvider);
    });

    test('Initial state is empty with loading indicator', () {
      expect(groupFeedProvider.notesBox.isEmpty(), true);
      expect(groupFeedProvider.newNotesBox.isEmpty(), true);
      expect(groupFeedProvider.isLoading, true);
    });

    test('Clear method empties boxes', () {
      // Add some test data first
      final event = Event.fromJson({
        'id': '0'.padLeft(64, '0'),
        'pubkey': '0'.padLeft(64, '0'),
        'created_at': 1000,
        'kind': EventKind.groupNote,
        'tags': [],
        'content': 'test',
        'sig': '0'.padLeft(128, '0'),
      });
      
      groupFeedProvider.notesBox.add(event);
      groupFeedProvider.newNotesBox.add(event);
      
      // Verify data was added
      expect(groupFeedProvider.notesBox.isEmpty(), false);
      expect(groupFeedProvider.newNotesBox.isEmpty(), false);
      
      // Clear and verify empty
      groupFeedProvider.clear();
      expect(groupFeedProvider.notesBox.isEmpty(), true);
      expect(groupFeedProvider.newNotesBox.isEmpty(), true);
    });

    test('isGroupNote correctly identifies group notes and replies', () {
      final noteEvent = Event.fromJson({
        'id': '0'.padLeft(64, '0'),
        'pubkey': '0'.padLeft(64, '0'),
        'created_at': 1000,
        'kind': EventKind.groupNote,
        'tags': [],
        'content': 'test note',
        'sig': '0'.padLeft(128, '0'),
      });
      
      final replyEvent = Event.fromJson({
        'id': '1'.padLeft(64, '0'),
        'pubkey': '0'.padLeft(64, '0'),
        'created_at': 1000,
        'kind': EventKind.groupNoteReply,
        'tags': [],
        'content': 'test reply',
        'sig': '0'.padLeft(128, '0'),
      });
      
      final otherEvent = Event.fromJson({
        'id': '2'.padLeft(64, '0'),
        'pubkey': '0'.padLeft(64, '0'),
        'created_at': 1000,
        'kind': EventKind.textNote,
        'tags': [],
        'content': 'not a group post',
        'sig': '0'.padLeft(128, '0'),
      });
      
      expect(groupFeedProvider.isGroupNote(noteEvent), true);
      expect(groupFeedProvider.isGroupNote(replyEvent), true);
      expect(groupFeedProvider.isGroupNote(otherEvent), false);
    });

    test('deleteEvent removes events from both boxes', () {
      // Add test events
      final event1 = Event.fromJson({
        'id': 'event1',
        'pubkey': '0'.padLeft(64, '0'),
        'created_at': 1000,
        'kind': EventKind.groupNote,
        'tags': [],
        'content': 'test1',
        'sig': '0'.padLeft(128, '0'),
      });
      
      final event2 = Event.fromJson({
        'id': 'event2',
        'pubkey': '0'.padLeft(64, '0'),
        'created_at': 1000,
        'kind': EventKind.groupNote,
        'tags': [],
        'content': 'test2',
        'sig': '0'.padLeft(128, '0'),
      });
      
      groupFeedProvider.notesBox.add(event1);
      groupFeedProvider.notesBox.add(event2);
      groupFeedProvider.newNotesBox.add(event1);
      
      // Delete one event
      groupFeedProvider.deleteEvent(event1);
      
      // Check event was removed from both boxes
      expect(groupFeedProvider.notesBox.contains('event1'), false);
      expect(groupFeedProvider.notesBox.contains('event2'), true);
      expect(groupFeedProvider.newNotesBox.contains('event1'), false);
    });

    test('mergeNewEvent moves events from newNotesBox to notesBox', () {
      // Add test events
      final event1 = Event.fromJson({
        'id': 'event1',
        'pubkey': '0'.padLeft(64, '0'),
        'created_at': 1000,
        'kind': EventKind.groupNote,
        'tags': [],
        'content': 'test1',
        'sig': '0'.padLeft(128, '0'),
      });
      
      final event2 = Event.fromJson({
        'id': 'event2',
        'pubkey': '0'.padLeft(64, '0'),
        'created_at': 1000,
        'kind': EventKind.groupNote,
        'tags': [],
        'content': 'test2',
        'sig': '0'.padLeft(128, '0'),
      });
      
      groupFeedProvider.notesBox.add(event1);
      groupFeedProvider.newNotesBox.add(event2);
      
      // Merge new events
      groupFeedProvider.mergeNewEvent();
      
      // Check events were merged correctly
      expect(groupFeedProvider.notesBox.contains('event1'), true);
      expect(groupFeedProvider.notesBox.contains('event2'), true);
      expect(groupFeedProvider.newNotesBox.isEmpty(), true);
    });
  });
}