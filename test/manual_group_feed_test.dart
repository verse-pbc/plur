import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/data/join_group_parameters.dart';

void main() {
  group('Group tag validation tests', () {
    test('hasValidGroupTag correctly validates group tags', () {
      // Setup
      final groupIdentifiers = [
        GroupIdentifier('relay1', 'group1'),
        GroupIdentifier('relay2', 'group2'),
      ];
      
      // Test event with valid group tag
      final validEvent = Event.fromJson({
        'id': 'valid',
        'pubkey': '0'.padLeft(64, '0'),
        'created_at': 1000,
        'kind': EventKind.groupNote,
        'tags': [
          ['h', 'group1'] // Valid tag
        ],
        'content': 'test with valid tag',
        'sig': '0'.padLeft(128, '0'),
      });
      
      // Test event with invalid group tag
      final invalidEvent = Event.fromJson({
        'id': 'invalid',
        'pubkey': '0'.padLeft(64, '0'),
        'created_at': 1000,
        'kind': EventKind.groupNote,
        'tags': [
          ['h', 'group3'] // Invalid tag
        ],
        'content': 'test with invalid tag',
        'sig': '0'.padLeft(128, '0'),
      });
      
      // Test event with no group tag
      final noTagEvent = Event.fromJson({
        'id': 'notag',
        'pubkey': '0'.padLeft(64, '0'),
        'created_at': 1000,
        'kind': EventKind.groupNote,
        'tags': [],
        'content': 'test with no tags',
        'sig': '0'.padLeft(128, '0'),
      });
      
      // Test event with mixed tags
      final mixedTagsEvent = Event.fromJson({
        'id': 'mixed',
        'pubkey': '0'.padLeft(64, '0'),
        'created_at': 1000,
        'kind': EventKind.groupNote,
        'tags': [
          ['p', 'somePubkey'],  // Irrelevant tag
          ['h', 'group3'],      // Invalid group tag
          ['h', 'group1'],      // Valid group tag
          ['e', 'someEventId']  // Another irrelevant tag
        ],
        'content': 'test with mixed tags',
        'sig': '0'.padLeft(128, '0'),
      });
      
      // Test validation function similar to the one in GroupFeedProvider
      bool hasValidGroupTag(Event e) {
        for (var tag in e.tags) {
          if (tag is List && tag.isNotEmpty && tag.length > 1 && 
              tag[0] == "h" && 
              groupIdentifiers.any((g) => g.groupId == tag[1])) {
            return true;
          }
        }
        return false;
      }
      
      // Verify our validation function works correctly
      expect(hasValidGroupTag(validEvent), true);
      expect(hasValidGroupTag(invalidEvent), false);
      expect(hasValidGroupTag(noTagEvent), false);
      expect(hasValidGroupTag(mixedTagsEvent), true); // Should be true since it has one valid tag
      
      // Test with malformed tags
      final malformedTagsEvent = Event.fromJson({
        'id': 'malformed',
        'pubkey': '0'.padLeft(64, '0'),
        'created_at': 1000,
        'kind': EventKind.groupNote,
        'tags': [
          ['h'],               // Malformed tag (no value)
          ['', 'group1'],      // Malformed tag (empty type)
          ['h', '']            // Malformed tag (empty value)
        ],
        'content': 'test with malformed tags',
        'sig': '0'.padLeft(128, '0'),
      });
      
      expect(hasValidGroupTag(malformedTagsEvent), false);
    });
    
    test('isGroupNote correctly identifies group notes and replies', () {
      // Test function similar to the one in GroupFeedProvider
      bool isGroupNote(Event e) {
        return e.kind == EventKind.groupNote || e.kind == EventKind.groupNoteReply;
      }
      
      // Test with different event kinds
      final groupNoteEvent = Event.fromJson({
        'id': 'groupNote',
        'pubkey': '0'.padLeft(64, '0'),
        'created_at': 1000,
        'kind': EventKind.groupNote,
        'tags': [],
        'content': 'group note',
        'sig': '0'.padLeft(128, '0'),
      });
      
      final groupReplyEvent = Event.fromJson({
        'id': 'groupReply',
        'pubkey': '0'.padLeft(64, '0'),
        'created_at': 1000,
        'kind': EventKind.groupNoteReply,
        'tags': [],
        'content': 'group reply',
        'sig': '0'.padLeft(128, '0'),
      });
      
      final textNoteEvent = Event.fromJson({
        'id': 'textNote',
        'pubkey': '0'.padLeft(64, '0'),
        'created_at': 1000,
        'kind': EventKind.textNote,
        'tags': [],
        'content': 'text note',
        'sig': '0'.padLeft(128, '0'),
      });
      
      // Test validation
      expect(isGroupNote(groupNoteEvent), true);
      expect(isGroupNote(groupReplyEvent), true);
      expect(isGroupNote(textNoteEvent), false);
    });
    
    test('Event filtering logic works correctly', () {
      // Setup
      final groupIdentifiers = [
        GroupIdentifier('relay1', 'group1'),
        GroupIdentifier('relay2', 'group2'),
      ];
      
      // Test validation functions
      bool isGroupNote(Event e) {
        return e.kind == EventKind.groupNote || e.kind == EventKind.groupNoteReply;
      }
      
      bool hasValidGroupTag(Event e) {
        for (var tag in e.tags) {
          if (tag is List && tag.isNotEmpty && tag.length > 1 && 
              tag[0] == "h" && 
              groupIdentifiers.any((g) => g.groupId == tag[1])) {
            return true;
          }
        }
        return false;
      }
      
      // Create test events
      final validGroupNoteEvent = Event.fromJson({
        'id': 'validGroupNote',
        'pubkey': '0'.padLeft(64, '0'),
        'created_at': 1000,
        'kind': EventKind.groupNote,
        'tags': [
          ['h', 'group1']
        ],
        'content': 'valid group note',
        'sig': '0'.padLeft(128, '0'),
      });
      
      final invalidGroupNoteEvent = Event.fromJson({
        'id': 'invalidGroupNote',
        'pubkey': '0'.padLeft(64, '0'),
        'created_at': 1000,
        'kind': EventKind.groupNote,
        'tags': [
          ['h', 'group3']
        ],
        'content': 'invalid group note',
        'sig': '0'.padLeft(128, '0'),
      });
      
      final textNoteEvent = Event.fromJson({
        'id': 'textNote',
        'pubkey': '0'.padLeft(64, '0'),
        'created_at': 1000,
        'kind': EventKind.textNote,
        'tags': [
          ['h', 'group1']
        ],
        'content': 'text note (not a group note)',
        'sig': '0'.padLeft(128, '0'),
      });
      
      // Create a simple EventMemBox implementation to simulate notesBox/newNotesBox
      final Set<String> notesBox = {};
      
      // Simulate the event filtering logic
      // Similar to what happens in the GroupFeedProvider
      void processEvent(Event e) {
        if (isGroupNote(e) && hasValidGroupTag(e)) {
          notesBox.add(e.id);
        }
      }
      
      // Process the events
      processEvent(validGroupNoteEvent);
      processEvent(invalidGroupNoteEvent);
      processEvent(textNoteEvent);
      
      // Verify the results
      expect(notesBox.contains('validGroupNote'), true);
      expect(notesBox.contains('invalidGroupNote'), false);
      expect(notesBox.contains('textNote'), false);
    });
  });
}