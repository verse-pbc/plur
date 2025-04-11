import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/provider/index_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';

// Simple wrapper function to avoid having to modify the GroupFeedProvider
GroupFeedProvider createTestGroupFeedProvider() {
  return GroupFeedProvider(ListProvider());
}

/// Tests for the performance optimizations made to tab switching
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tab Switching Performance', () {
    test('IndexProvider should maintain tab information', () {
      final indexProvider = IndexProvider();
      
      // Check initial state
      expect(indexProvider.currentTap, 0);
      expect(indexProvider.previousTap, 0);
      
      // Set community view mode and verify it changes
      indexProvider.setCommunityViewMode(CommunityViewMode.feed);
      expect(indexProvider.communityViewMode, CommunityViewMode.feed);
      
      // Change back
      indexProvider.setCommunityViewMode(CommunityViewMode.grid);
      expect(indexProvider.communityViewMode, CommunityViewMode.grid);
    });

    test('GroupFeedProvider should handle clearData with preserveCache', () {
      // Create a test event
      final testEvent = Event.fromJson({
        'id': '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        'pubkey': '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        'created_at': 1000,
        'kind': EventKind.groupNote,
        'tags': [],
        'content': 'Test content',
        'sig': '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
      });
      
      // Create a provider with our factory function
      final provider = createTestGroupFeedProvider();
      
      // Set up the provider with an event
      provider.notesBox.add(testEvent);
      
      // Normally notesBox should have the event
      expect(provider.notesBox.isEmpty(), false);
      
      // Clear with preserve flag
      provider.clearData(preserveCache: true);
      
      // notesBox should be empty
      expect(provider.notesBox.isEmpty(), true);
    });
  });
}