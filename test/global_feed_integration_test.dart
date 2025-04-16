import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/data/join_group_parameters.dart';

@GenerateMocks([ListProvider, Nostr])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Global Feed Integration Tests', () {
    late ListProvider mockListProvider;
    late GroupFeedProvider groupFeedProvider;
    
    // Create a mock instance of Nostr for testing
    late Nostr mockNostr;
    
    // Global scope test data
    final testGroupId1 = "testgroup1";
    final testGroupId2 = "testgroup2";
    final defaultRelayAddress = "wss://relay.example.com";
    
    setUp(() {
      // Create mock ListProvider
      mockListProvider = MockListProvider();
      
      // Create sample GroupIdentifiers
      final groupIds = [
        GroupIdentifier(defaultRelayAddress, testGroupId1),
        GroupIdentifier(defaultRelayAddress, testGroupId2),
      ];
      
      // Configure the mock to return sample group identifiers
      when(mockListProvider.groupIdentifiers).thenReturn(groupIds);
      
      // Create the GroupFeedProvider with the mock ListProvider
      groupFeedProvider = GroupFeedProvider(mockListProvider);
      
      // Create and configure mock Nostr instance
      mockNostr = MockNostr();
    });
    
    test('GroupFeedProvider queries with correct group identifiers', () {
      // Verify that mock ListProvider returns the expected group identifiers
      expect(mockListProvider.groupIdentifiers.length, 2);
      expect(mockListProvider.groupIdentifiers[0].groupId, testGroupId1);
      expect(mockListProvider.groupIdentifiers[1].groupId, testGroupId2);
      
      // Manually call the doQuery method
      groupFeedProvider.doQuery(null);
      
      // Verify that the isLoading flag is set
      expect(groupFeedProvider.isLoading, true);
    });
    
    test('GroupFeedProvider correctly processes group posts', () {
      // Create sample group note event
      final groupNote = Event.fromJson({
        'id': '001',
        'pubkey': '0'.padLeft(64, '0'),
        'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'kind': EventKind.groupNote,
        'tags': [
          ['h', testGroupId1]
        ],
        'content': 'Test group post',
        'sig': '0'.padLeft(128, '0'),
      });
      
      // Process the event through onEvent
      groupFeedProvider.onEvent(groupNote);
      
      // Use a small delay to allow the event processing to complete
      Future.delayed(const Duration(milliseconds: 100), () {
        // Check that the event was processed and added to the notes box
        expect(groupFeedProvider.notesBox.contains('001'), true);
        
        // Check that isLoading has been set to false after receiving events
        expect(groupFeedProvider.isLoading, false);
      });
    });

    test('Global feed shows posts after subscribing to groups', () {
      // Create multiple sample group note events
      final event1 = Event.fromJson({
        'id': '001',
        'pubkey': '0'.padLeft(64, '0'),
        'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'kind': EventKind.groupNote,
        'tags': [
          ['h', testGroupId1]
        ],
        'content': 'Group 1 post',
        'sig': '0'.padLeft(128, '0'),
      });
      
      final event2 = Event.fromJson({
        'id': '002',
        'pubkey': '0'.padLeft(64, '0'),
        'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'kind': EventKind.groupNote,
        'tags': [
          ['h', testGroupId2]
        ],
        'content': 'Group 2 post',
        'sig': '0'.padLeft(128, '0'),
      });
      
      // Call subscribe and doQuery
      groupFeedProvider.subscribe();
      groupFeedProvider.doQuery(null);
      
      // Manually invoke onEvent for each event
      groupFeedProvider.onEvent(event1);
      groupFeedProvider.onEvent(event2);
      
      // Use a small delay to allow the event processing to complete
      Future.delayed(const Duration(milliseconds: 100), () {
        // Verify that both events were added to the notes box
        expect(groupFeedProvider.notesBox.contains('001'), true);
        expect(groupFeedProvider.notesBox.contains('002'), true);
        expect(groupFeedProvider.notesBox.length(), 2);
        
        // Verify that isLoading has been updated
        expect(groupFeedProvider.isLoading, false);
      });
    });
  });
}