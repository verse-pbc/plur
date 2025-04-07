import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/main.dart' as app;

import 'helpers/test_data.dart';
import 'group_feed_provider_test.mocks.dart';

@GenerateMocks([ListProvider, Nostr])
void main() {
  late MockListProvider mockListProvider;
  late MockNostr mockNostr;
  late GroupFeedProvider groupFeedProvider;

  setUp(() {
    mockListProvider = MockListProvider();
    mockNostr = MockNostr();
    
    // Setup mock Nostr methods
    when(mockNostr.query(any, any, 
        tempRelays: anyNamed('tempRelays'),
        relayTypes: anyNamed('relayTypes'),
        sendAfterAuth: anyNamed('sendAfterAuth')))
        .thenReturn('query-id');
        
    when(mockNostr.subscribe(any, any,
        id: anyNamed('id'),
        relayTypes: anyNamed('relayTypes'),
        tempRelays: anyNamed('tempRelays'),
        sendAfterAuth: anyNamed('sendAfterAuth')))
        .thenReturn('subscription-id');
        
    // Set global nostr instance
    app.nostr = mockNostr;
    
    groupFeedProvider = GroupFeedProvider(mockListProvider);
  });

  test('doQuery fetches posts from all communities', () {
    // Setup multiple group identifiers
    final group1 = GroupIdentifier('wss://relay1.com', 'group1');
    final group2 = GroupIdentifier('wss://relay2.com', 'group2');
    final group3 = GroupIdentifier('wss://relay3.com', 'group3');
    
    when(mockListProvider.groupIdentifiers).thenReturn([group1, group2, group3]);
    
    // Call the method under test
    groupFeedProvider.doQuery(null);
    
    // Verify that query was called
    verify(mockNostr.query(any, any, 
      tempRelays: anyNamed('tempRelays'),
      relayTypes: anyNamed('relayTypes'),
      sendAfterAuth: anyNamed('sendAfterAuth'))).called(greaterThan(0));
  });

  test('subscribe creates subscriptions for all communities', () {
    // Setup multiple group identifiers
    final group1 = GroupIdentifier('wss://relay1.com', 'group1');
    final group2 = GroupIdentifier('wss://relay2.com', 'group2');
    
    when(mockListProvider.groupIdentifiers).thenReturn([group1, group2]);
    
    // Call the method under test
    groupFeedProvider.subscribe();
    
    // Verify that subscribe was called
    verify(mockNostr.subscribe(any, any,
      id: anyNamed('id'),
      tempRelays: anyNamed('tempRelays'),
      relayTypes: anyNamed('relayTypes'),
      sendAfterAuth: anyNamed('sendAfterAuth'))).called(greaterThan(0));
  });
  
  test('onNewEvent adds events to newNotesBox', () {
    // Create a sample event
    final eventJson = TestData.groupNoteJson;
    final event = Event.fromJson(eventJson);
    
    // Mock publicKey since it's used in onNewEvent
    when(mockNostr.publicKey).thenReturn(TestData.alicePubkey);
    
    // Call the method
    groupFeedProvider.onNewEvent(event);
    
    // Verify event was added to newNotesBox
    expect(groupFeedProvider.newNotesBox.length(), 1);
    expect(groupFeedProvider.newNotesBox.getById(event.id), isNotNull);
  });
  
  test('mergeNewEvent moves events from newNotesBox to notesBox', () {
    // Create sample events
    final eventJson = TestData.groupNoteJson;
    final event = Event.fromJson(eventJson);
    
    // Add to newNotesBox
    groupFeedProvider.newNotesBox.add(event);
    expect(groupFeedProvider.newNotesBox.length(), 1);
    expect(groupFeedProvider.notesBox.length(), 0);
    
    // Call merge
    groupFeedProvider.mergeNewEvent();
    
    // Verify events moved
    expect(groupFeedProvider.newNotesBox.length(), 0);
    expect(groupFeedProvider.notesBox.length(), 1);
    expect(groupFeedProvider.notesBox.getById(event.id), isNotNull);
  });
}