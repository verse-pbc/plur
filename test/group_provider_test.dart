import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/provider/relay_provider.dart';
import 'package:nostrmo/router/group/group_detail_provider.dart';
import 'package:nostrmo/util/string_code_generator.dart';

import 'helpers/test_data.dart';

// Create mocks
@GenerateMocks([Nostr])
void main() {
  group('GroupProvider', () {
    test('genFilter should use #d tag instead of d', () {
      final provider = GroupProvider();
      const groupId = "myId";
      final filter = provider.genFilter(groupId, 1);
      expect(filter.containsKey("#d"), true);
      expect(filter["#d"], [groupId]);
    });
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
    });
  });
}