import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/features/communities/community_list_item_widget.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/provider/group_read_status_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'community_list_item_test.mocks.dart';

@GenerateMocks([GroupFeedProvider, GroupReadStatusProvider])
void main() {
  testWidgets('CommunityListItemWidget displays post counts correctly',
  (WidgetTester tester) async {
    // Create mock providers
    final mockGroupFeedProvider = MockGroupFeedProvider();
    final mockReadStatusProvider = MockGroupReadStatusProvider();
    
    // Create test group identifier
    final groupIdentifier = GroupIdentifier('relay1', 'group1');
    
    // Create test metadata
    final metadata = GroupMetadata.createNew('group1', 'Test Group');
    metadata.picture = 'https://example.com/pic.jpg';
    
    // Set up the mock behavior
    when(mockReadStatusProvider.getPostCount(groupIdentifier)).thenReturn(5);
    when(mockReadStatusProvider.getUnreadCount(groupIdentifier)).thenReturn(3);
    when(mockReadStatusProvider.hasUnread(groupIdentifier)).thenReturn(true);
    
    // Build the widget tree
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<GroupFeedProvider>.value(
                value: mockGroupFeedProvider,
              ),
              ChangeNotifierProvider<GroupReadStatusProvider>.value(
                value: mockReadStatusProvider,
              ),
            ],
            child: Material(
              child: ListView(
                children: [
                  CommunityListItemWidget(groupIdentifier, index: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    
    // Wait for all async operations to complete
    await tester.pumpAndSettle();
    
    // Debug: Find all Text widgets and print their data
    print("--- All Text widgets ---");
    final textWidgets = tester.widgetList<Text>(find.byType(Text));
    for (var text in textWidgets) {
      print("Text: '${text.data}'");
    }
    
    // Look for the post count indicator (should be "5")
    final postCountFinder = find.text('5');
    expect(postCountFinder, findsOneWidget);
    
    // The post count should be displayed in red (indicating unread posts)
    // To verify this, we need to check the container color
    final containerFinder = find.ancestor(
      of: postCountFinder,
      matching: find.byType(Container),
    ).first;
    
    final Container container = tester.widget(containerFinder);
    final BoxDecoration decoration = container.decoration as BoxDecoration;
    
    // The container should have red color
    expect(decoration.color, equals(Colors.red));
  });

  testWidgets('CommunityListItemWidget handles no unread posts correctly',
  (WidgetTester tester) async {
    // Create mock providers
    final mockGroupFeedProvider = MockGroupFeedProvider();
    final mockReadStatusProvider = MockGroupReadStatusProvider();
    
    // Create test group identifier
    final groupIdentifier = GroupIdentifier('relay1', 'group1');
    
    // Set up the mock behavior - no unread posts
    when(mockReadStatusProvider.getPostCount(groupIdentifier)).thenReturn(5);
    when(mockReadStatusProvider.getUnreadCount(groupIdentifier)).thenReturn(0);
    when(mockReadStatusProvider.hasUnread(groupIdentifier)).thenReturn(false);
    
    // Build the widget tree
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<GroupFeedProvider>.value(
                value: mockGroupFeedProvider,
              ),
              ChangeNotifierProvider<GroupReadStatusProvider>.value(
                value: mockReadStatusProvider,
              ),
            ],
            child: Material(
              child: ListView(
                children: [
                  CommunityListItemWidget(groupIdentifier, index: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    
    // Wait for all async operations to complete
    await tester.pumpAndSettle();
    
    // Look for the post count indicator (should be "5")
    final postCountFinder = find.text('5');
    expect(postCountFinder, findsOneWidget);
    
    // The container should have gray color for read posts
    final containerFinder = find.ancestor(
      of: postCountFinder,
      matching: find.byType(Container),
    ).first;
    
    final Container container = tester.widget(containerFinder);
    final BoxDecoration decoration = container.decoration as BoxDecoration;
    
    // For no unread posts, the color should be gray
    expect(decoration.color, equals(Colors.grey[300]));
  });

  testWidgets('CommunityListItemWidget falls back to direct count when provider is unavailable',
  (WidgetTester tester) async {
    // Create mock providers
    final mockGroupFeedProvider = MockGroupFeedProvider();
    
    // Create test group identifier
    final groupIdentifier = GroupIdentifier('relay1', 'group1');
    
    // Mock the behavior for the fallback path
    // This tests the _getNotificationCount method
    when(mockGroupFeedProvider.notesBox).thenReturn(EventMemBox(sortAfterAdd: false));
    
    // Add some mock events to notesBox (we'll need to modify the test for this)
    // Since we can't directly add to the mock's notesBox, we'll need to mock the counts
    
    // Build the widget without the read status provider
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<GroupFeedProvider>.value(
                value: mockGroupFeedProvider,
              ),
              // No GroupReadStatusProvider provided
            ],
            child: Material(
              child: ListView(
                children: [
                  CommunityListItemWidget(groupIdentifier, index: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    
    // Wait for all async operations to complete
    await tester.pumpAndSettle();
    
    // This test would verify the fallback behavior, but requires more mocking
    // of the EventMemBox which is challenging with the current setup
  });
}