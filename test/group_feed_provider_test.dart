import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';

import 'helpers/test_data.dart';

// Create manual mocks instead of using @GenerateMocks
class MockListProvider extends Mock implements ListProvider {
  @override
  List<GroupIdentifier> get groupIdentifiers => _groupIds;
  final List<GroupIdentifier> _groupIds = [];
  
  void addGroupIdentifier(GroupIdentifier id) {
    _groupIds.add(id);
  }
}

class MockNostr extends Mock implements Nostr {}
void main() {
  late MockListProvider mockListProvider;
  // Not used directly, but kept for future test extensions
  // ignore: unused_local_variable
  late MockNostr mockNostr;
  late GroupFeedProvider groupFeedProvider;

  setUp(() {
    mockListProvider = MockListProvider();
    mockNostr = MockNostr();
    groupFeedProvider = GroupFeedProvider();

    // Setup provider with mocks
    groupFeedProvider.setListProvider(mockListProvider);
  });

  tearDown(() {
    TestData.clearMocks();
  });

  group('GroupFeedProvider', () {
    test('should initialize with empty note boxes', () {
      expect(groupFeedProvider.notesBox.all().length, 0);
      expect(groupFeedProvider.newNotesBox.all().length, 0);
    });

    test('isGroupEvent should correctly identify group events', () {
      // Create a GROUP_NOTE event with correct 'h' tag
      final groupNoteEvent = Event(
        TestData.alicePubkey,
        EventKind.GROUP_NOTE,
        [
          ['h', 'group1']
        ],
        'content',
      );
      
      // Create a non-group event
      final nonGroupEvent = Event(
        TestData.alicePubkey,
        1, // Regular note kind
        [],
        'content',
      );
      
      // Add group1 to the mock list provider
      mockListProvider.addGroupIdentifier(GroupIdentifier('relay.com', 'group1'));
      
      // No debug output in production code
      
      // Manually set the groups in the provider
      groupFeedProvider.groupIdentifiers.add(GroupIdentifier('relay.com', 'group1'));
      
      // Test identification
      expect(groupFeedProvider.isGroupEvent(groupNoteEvent), true, reason: "Should identify a group note");
      expect(groupFeedProvider.isGroupEvent(nonGroupEvent), false, reason: "Should not identify a regular note");
    });
    
    test('mergeNewEvent should move events from newNotesBox to notesBox', () {
      // Create test events
      final event1 = Event(TestData.alicePubkey, EventKind.GROUP_NOTE, [['h', 'group1']], 'content1');
      final event2 = Event(TestData.bobPubkey, EventKind.GROUP_NOTE, [['h', 'group1']], 'content2');
      
      // Add group to the provider and mock
      mockListProvider.addGroupIdentifier(GroupIdentifier('relay.com', 'group1'));
      groupFeedProvider.groupIdentifiers.add(GroupIdentifier('relay.com', 'group1'));
      
      // Add events to newNotesBox
      groupFeedProvider.newNotesBox.add(event1);
      groupFeedProvider.newNotesBox.add(event2);
      
      // Verify events are in newNotesBox
      expect(groupFeedProvider.newNotesBox.all().length, 2);
      expect(groupFeedProvider.notesBox.all().length, 0);
      
      // Call mergeNewEvent
      groupFeedProvider.mergeNewEvent();
      
      // Verify events were moved to notesBox
      expect(groupFeedProvider.newNotesBox.all().length, 0);
      expect(groupFeedProvider.notesBox.all().length, 2);
    });
  });
}