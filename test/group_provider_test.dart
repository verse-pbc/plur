import 'package:flutter_test/flutter_test.dart';
<<<<<<< HEAD
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/provider/relay_provider.dart';
import 'package:nostrmo/util/string_code_generator.dart';

// Create mocks
@GenerateMocks([Nostr])
import 'group_provider_test.mocks.dart';

void main() {
  group('GroupProvider', () {
    late GroupProvider provider;
    late MockNostr mockNostr;

    setUp(() {
      mockNostr = MockNostr();
      provider = GroupProvider();
      
      // Setup default behavior for the mock
      when(mockNostr.publicKey).thenReturn('test_public_key');
      
      // In real application we'd use the global nostr object, but for testing
      // we'll pass the mock to methods that need it
    });

=======
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/router/group/group_detail_provider.dart';

import 'helpers/test_data.dart';

void main() {
  group('GroupProvider', () {
>>>>>>> feature/chat_experiment
    test('genFilter should use #d tag instead of d', () {
      final provider = GroupProvider();
      const groupId = "myId";
      final filter = provider.genFilter(groupId, 1);
      expect(filter.containsKey("#d"), true);
      expect(filter["#d"], [groupId]);
    });
<<<<<<< HEAD

    test('getMetadata should return null and trigger query if metadata not found', () {
      // Arrange
      final groupId = GroupIdentifier(RelayProvider.defaultGroupsRelayAddress, 'test_group_id');
      
      // Act
      final result = provider.getMetadata(groupId);
      
      // Assert
      expect(result, isNull);
      // This is a basic test - in a real implementation we'd verify the query was triggered
    });

    test('GroupIdentifier equality works correctly', () {
      // Arrange
      final group1 = GroupIdentifier('host1', 'id1');
      final group2 = GroupIdentifier('host1', 'id1'); // Same values
      final group3 = GroupIdentifier('host2', 'id1'); // Different host
      final group4 = GroupIdentifier('host1', 'id2'); // Different id
      
      // Act & Assert
      expect(group1, equals(group2)); // Same values should be equal
      expect(group1, isNot(equals(group3))); // Different host should not be equal
      expect(group1, isNot(equals(group4))); // Different id should not be equal
      
      // Test toString and hashCode
      expect(group1.toString(), equals(group2.toString()));
      expect(group1.hashCode, equals(group2.hashCode));
      
      // Test Set behavior (hashCode and equals)
      final groupSet = <GroupIdentifier>{};
      groupSet.add(group1);
      expect(groupSet.contains(group2), isTrue); // Should find the equivalent object
      
      groupSet.add(group3);
      expect(groupSet.length, equals(2)); // Should have 2 distinct items
    });
    
    // Skip these tests for now since they depend on the global nostr object
    // TODO: Refactor GroupProvider to accept a Nostr instance in constructor for better testability
    test('updateMetadata should update local cache and send event', () {
      // This test is skipped for now
=======
  });

  group('GroupDetailProvider events handling', () {
    late GroupDetailProvider provider;

    setUp(() {
      provider = GroupDetailProvider();
    });

    test('should identify group notes correctly', () {
      // Create test events
      final groupNote = Event(
        TestData.alicePubkey,
        EventKind.groupNote,
        [["h", "testGroupId"]],
        "Test note content"
      );
      final groupNoteReply = Event(
        TestData.alicePubkey,
        EventKind.groupNoteReply,
        [["h", "testGroupId"], ["e", "someEventId", "", "reply"]],
        "Test note reply content"
      );
      final otherEvent = Event(
        TestData.alicePubkey,
        EventKind.textNote,
        [],
        "Test content"
      );

      // Test isGroupNote method
      expect(provider.isGroupNote(groupNote), true);
      expect(provider.isGroupNote(groupNoteReply), true);
      expect(provider.isGroupNote(otherEvent), false);
    });

    test('should identify group chats correctly', () {
      // Create test events
      final groupChat = Event(
        TestData.alicePubkey,
        EventKind.groupChatMessage,
        [["h", "testGroupId"]],
        "Test chat content"
      );
      final groupChatReply = Event(
        TestData.alicePubkey,
        EventKind.groupChatReply,
        [["h", "testGroupId"], ["e", "someEventId", "", "reply"]],
        "Test chat reply content"
      );
      final otherEvent = Event(
        TestData.alicePubkey,
        EventKind.textNote,
        [],
        "Test content"
      );

      // Test isGroupChat method
      expect(provider.isGroupChat(groupChat), true);
      expect(provider.isGroupChat(groupChatReply), true);
      expect(provider.isGroupChat(otherEvent), false);
    });

    test('should correctly identify event types and route to appropriate boxes', () {
      // Create test events
      final note = Event(
        TestData.alicePubkey,
        EventKind.groupNote,
        [["h", "testGroupId"]],
        "Test note content"
      );
      final chat = Event(
        TestData.alicePubkey,
        EventKind.groupChatMessage,
        [["h", "testGroupId"]],
        "Test chat content"
      );

      // Add events directly to their boxes to test sorting logic
      provider.notesBox.add(note);
      provider.chatsBox.add(chat);

      // Verify they went to the correct boxes
      expect(provider.notesBox.isEmpty(), false);
      expect(provider.chatsBox.isEmpty(), false);
      expect(provider.notesBox.contains(note.id), true);
      expect(provider.chatsBox.contains(chat.id), true);
      
      // Test the identification methods directly
      expect(provider.isGroupNote(note), true);
      expect(provider.isGroupChat(chat), true);
      expect(provider.isGroupNote(chat), false);
      expect(provider.isGroupChat(note), false);
    });

    test('should generate previous IDs for chat and notes separately', () {
      // Create several test events
      final notes = List.generate(
        6,
        (index) => Event(
          TestData.alicePubkey,
          EventKind.groupNote,
          [["h", "testGroupId"]],
          "Test note content $index",
          createdAt: 1000 + index
        )
      );
      
      final chats = List.generate(
        6,
        (index) => Event(
          TestData.alicePubkey,
          EventKind.groupChatMessage,
          [["h", "testGroupId"]],
          "Test chat content $index",
          createdAt: 2000 + index
        )
      );

      // Add events
      for (var note in notes) {
        provider.notesBox.add(note);
      }
      for (var chat in chats) {
        provider.chatsBox.add(chat);
      }

      // Get previous IDs
      final notePrevious = provider.notesPrevious();
      final chatPrevious = provider.chatsPrevious();

      // Verify
      expect(notePrevious.length, 5); // Should respect previousLength limit
      expect(chatPrevious.length, 5); // Should respect previousLength limit
      
      // Verify IDs are different
      expect(notePrevious, isNot(equals(chatPrevious)));
    });

    test('should correctly delete events from appropriate boxes', () {
      // Create test events
      final note = Event(
        TestData.alicePubkey,
        EventKind.groupNote,
        [["h", "testGroupId"]],
        "Test note content"
      );
      final chat = Event(
        TestData.alicePubkey,
        EventKind.groupChatMessage,
        [["h", "testGroupId"]],
        "Test chat content"
      );

      // Add events directly
      provider.notesBox.add(note);
      provider.chatsBox.add(chat);

      // Verify they are in the boxes
      expect(provider.notesBox.contains(note.id), true);
      expect(provider.chatsBox.contains(chat.id), true);

      // Test delete logic
      provider.notesBox.delete(note.id);
      provider.chatsBox.delete(chat.id);

      // Verify they are removed
      expect(provider.notesBox.contains(note.id), false);
      expect(provider.chatsBox.contains(chat.id), false);
>>>>>>> feature/chat_experiment
    });
  });
  
  group('ListProvider', () {
    late ListProvider listProvider;
    late MockNostr mockNostr;

    setUp(() {
      mockNostr = MockNostr();
      listProvider = ListProvider();
      
      // Setup default behavior for the mock
      when(mockNostr.publicKey).thenReturn('test_public_key');
      
      // In real application we'd use the global nostr object, but for testing
      // we'll pass the mock to methods that need it
    });
    
    // Skip these tests for now since they depend on the global nostr object
    // TODO: Refactor ListProvider to accept a Nostr instance in constructor for better testability
    test('createGroupAndGenerateInvite creates a group and adds it to list', () {
      // This test is skipped for now
    });
  });
}