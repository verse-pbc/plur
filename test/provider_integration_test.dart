import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/provider/group_read_status_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:provider/provider.dart';

// Mock classes for testing
class MockNostr extends Mock implements Nostr {}

class MockEvent extends Mock implements Event {
  final String _id;
  final String _pubkey;
  final int _createdAt;
  final int _kind;
  final List<dynamic> _tags;
  final String _content;
  
  MockEvent(this._id, this._pubkey, this._createdAt, this._kind, this._tags, this._content);
  
  @override
  String get id => _id;
  
  @override
  String get pubkey => _pubkey;
  
  @override
  int get createdAt => _createdAt;
  
  @override
  int get kind => _kind;
  
  @override
  List<dynamic> get tags => _tags;
  
  @override
  String get content => _content;
}

void main() {
  group('Provider integration tests', () {
    late ListProvider listProvider;
    late GroupReadStatusProvider readStatusProvider;
    late GroupFeedProvider feedProvider;
    
    setUp(() {
      // Create provider instances in the correct order
      listProvider = ListProvider();
      readStatusProvider = GroupReadStatusProvider();
      // Create GroupFeedProvider with both dependencies
      feedProvider = GroupFeedProvider(listProvider, readStatusProvider);
    });
    
    testWidgets('Provider initialization and dependency injection',
        (WidgetTester tester) async {
      // Build testing widget with provider tree
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<ListProvider>.value(value: listProvider),
              ChangeNotifierProvider<GroupReadStatusProvider>.value(value: readStatusProvider),
              ChangeNotifierProvider<GroupFeedProvider>.value(value: feedProvider),
            ],
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  // Access all providers to check they're correctly registered
                  final listProv = Provider.of<ListProvider>(context, listen: false);
                  final readProv = Provider.of<GroupReadStatusProvider>(context, listen: false);
                  final feedProv = Provider.of<GroupFeedProvider>(context, listen: false);
                  
                  // Return a simple widget showing the providers are available
                  return Column(
                    children: [
                      Text('ListProvider: ${listProv.hashCode}'),
                      Text('ReadStatusProvider: ${readProv.hashCode}'),
                      Text('FeedProvider: ${feedProv.hashCode}'),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      
      // Verify providers are accessible
      expect(find.text('ListProvider: ${listProvider.hashCode}'), findsOneWidget);
      expect(find.text('ReadStatusProvider: ${readStatusProvider.hashCode}'), findsOneWidget);
      expect(find.text('FeedProvider: ${feedProvider.hashCode}'), findsOneWidget);
    });
    
    testWidgets('GroupFeedProvider registers callback with ListProvider',
        (WidgetTester tester) async {
      // Verify feedProvider registered a callback  
      expect(listProvider.onGroupsChanged != null, true);
      
      // Add a group to trigger the callback
      final groupId = GroupIdentifier('wss://test.relay', 'testgroup123');
      
      // Create an event handler to track if the refresh method is called
      bool refreshCalled = false;
      
      // Override the refresh method to track if it's called
      feedProvider.refresh = () {
        refreshCalled = true;
      };
      
      // Manually call the callback to simulate groups changing
      listProvider.onGroupsChanged!();
      
      // Verify refresh was called
      expect(refreshCalled, true);
    });
    
    testWidgets('GroupFeedProvider has readStatusProvider',
        (WidgetTester tester) async {
      // Verify feedProvider has the readStatusProvider  
      expect(feedProvider.readStatusProvider, readStatusProvider);
    });
    
    testWidgets('GroupFeedProvider properly disposes and unregisters callback',
        (WidgetTester tester) async {
      // Verify feedProvider registered a callback  
      expect(listProvider.onGroupsChanged != null, true);
      
      // Dispose the feed provider
      feedProvider.dispose();
      
      // Verify callback was unregistered
      expect(listProvider.onGroupsChanged, null);
    });
    
    testWidgets('Static cache persists after provider disposal',
        (WidgetTester tester) async {
      // Add a test event to the static cache
      final testEvent = MockEvent(
        'test123',
        'pubkey123',
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        EventKind.groupNote,
        [['h', 'testgroup123']],
        'Test content'
      );
      
      // Add to static cache
      GroupFeedProvider.staticEventCache[testEvent.id] = testEvent;
      
      // Verify event is in the cache
      expect(GroupFeedProvider.staticEventCache.containsKey(testEvent.id), true);
      
      // Dispose and create a new provider
      feedProvider.dispose();
      final newFeedProvider = GroupFeedProvider(listProvider, readStatusProvider);
      
      // Verify event is still in the static cache
      expect(GroupFeedProvider.staticEventCache.containsKey(testEvent.id), true);
      expect(newFeedProvider.staticEventCache.containsKey(testEvent.id), true);
    });
  });
}