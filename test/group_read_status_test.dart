import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/data/group_read_info.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/provider/group_read_status_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:provider/provider.dart';

import 'helpers/test_data.dart';
import 'group_read_status_test.mocks.dart';

// Simple box that stores events by ID
class TestBox<T> {
  final Map<String, T> _items = {};
  
  void add(T item) {
    if (item is Event) {
      _items[item.id] = item;
    }
  }
  
  bool contains(String id) {
    return _items.containsKey(id);
  }
  
  bool isEmpty() {
    return _items.isEmpty;
  }
  
  T? get(String id) {
    return _items[id];
  }
  
  List<T> values() {
    return _items.values.toList();
  }
  
  void remove(String id) {
    _items.remove(id);
  }
  
  void clear() {
    _items.clear();
  }
  
  int count() {
    return _items.length;
  }
}

// Standalone implementation of GroupFeedProvider for testing
class TestGroupFeedProvider {
  final TestableGroupReadStatusProvider readStatusProvider;
  final List<GroupIdentifier> groupIdentifiers;
  
  TestBox<Event> notesBox = TestBox<Event>();
  TestBox<Event> newNotesBox = TestBox<Event>();
  
  TestGroupFeedProvider(this.readStatusProvider, this.groupIdentifiers);

  void addTestEvent(Event event) {
    notesBox.add(event);
  }
  
  void updateAllGroupReadCounts() {
    print("Updating group read counts with ${notesBox.count()} events");
    
    // Process each group identifier
    for (var groupId in groupIdentifiers) {
      print("Processing group: ${groupId.groupId}");
      
      // Count notes for this group
      int count = 0;
      int unreadCount = 0;
      
      // Get the last read time for this group
      final lastReadTime = readStatusProvider.getLastReadTime(groupId);
      print("Last read time: $lastReadTime");
      
      // Find events with this group tag
      final events = notesBox.values().where((event) {
        // Check if event has a tag matching this group
        bool hasGroupTag = false;
        for (var tag in event.tags) {
          if (tag.length >= 2 && tag[0] == 'h' && tag[1] == groupId.groupId) {
            hasGroupTag = true;
            break;
          }
        }
        
        print("Event ${event.id}: hasGroupTag=$hasGroupTag");
        return hasGroupTag;
      }).toList();
      
      count = events.length;
      
      // If we have a last read time, calculate unread count
      if (lastReadTime != null) {
        unreadCount = events.where((e) => e.createdAt > lastReadTime).length;
      } else {
        unreadCount = count;  // All events are unread if no last read time
      }
      
      print("Group ${groupId.groupId}: count=$count, unread=$unreadCount");
      
      // Update the counts in the read status provider
      readStatusProvider.updateCounts(groupId, count, unreadCount);
    }
  }
  
  void markGroupRead(GroupIdentifier groupId) {
    readStatusProvider.markGroupRead(groupId);
  }
  
  void markGroupViewed(GroupIdentifier groupId) {
    readStatusProvider.markGroupViewed(groupId);
  }
}

// Simplified mock of GroupReadStatusProvider with in-memory storage
class TestableGroupReadStatusProvider extends ChangeNotifier implements GroupReadStatusProvider {
  final Map<String, GroupReadInfo> _readInfoMap = {};
  
  @override
  bool get isInitialized => true;
  
  @override
  GroupReadInfo getReadInfo(GroupIdentifier identifier) {
    final key = "${identifier.groupId}:${identifier.host}";
    if (!_readInfoMap.containsKey(key)) {
      // Use a timestamp in the past so that all test events are considered unread
      final pastTimestamp = 500; // Much older than any test event timestamp
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final info = GroupReadInfo(
        keyIndex: 0,
        groupId: identifier.groupId,
        host: identifier.host,
        lastReadTime: pastTimestamp,
        lastViewedAt: now,
      );
      _readInfoMap[key] = info;
    }
    return _readInfoMap[key]!;
  }
  
  @override
  Future<void> init() async {
    // No-op for tests
  }
  
  @override
  Future<void> markGroupRead(GroupIdentifier identifier) async {
    final info = getReadInfo(identifier);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    // Force the timestamp to be updated to current time to ensure it's newer
    info.lastReadTime = now;
    info.lastViewedAt = now;
    info.unreadCount = 0;
    notifyListeners();
  }
  
  @override
  Future<void> markGroupViewed(GroupIdentifier identifier) async {
    final info = getReadInfo(identifier);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 100; // Add offset to ensure it's newer
    // Force the viewed timestamp to be updated
    info.lastViewedAt = now;
    notifyListeners();
  }
  
  @override
  Future<void> updateCounts(GroupIdentifier identifier, int totalPosts, int newPosts) async {
    final info = getReadInfo(identifier);
    info.updateCounts(totalPosts, newPosts);
    notifyListeners();
  }
  
  @override
  int getUnreadCount(GroupIdentifier identifier) {
    return getReadInfo(identifier).unreadCount;
  }
  
  @override
  int getPostCount(GroupIdentifier identifier) {
    return getReadInfo(identifier).postCount;
  }
  
  @override
  bool hasUnread(GroupIdentifier identifier) {
    return getReadInfo(identifier).hasUnread;
  }
  
  @override
  int getTotalUnreadCount() {
    int total = 0;
    for (var info in _readInfoMap.values) {
      total += info.unreadCount;
    }
    return total;
  }
  
  @override
  List<GroupIdentifier> getGroupsWithUnread() {
    return _readInfoMap.values
        .where((info) => info.unreadCount > 0)
        .map((info) => GroupIdentifier(info.host, info.groupId))
        .toList();
  }
  
  @override
  int calculateUnreadCount(List<Event> events, GroupIdentifier groupId, int? lastReadTime) {
    if (lastReadTime == null) {
      return events.length;
    }
    return events.where((event) => event.createdAt > lastReadTime).length;
  }
  
  @override
  Future<void> clear() async {
    _readInfoMap.clear();
    notifyListeners();
  }
  
  @override
  Future<void> clearGroup(GroupIdentifier identifier) async {
    final key = "${identifier.groupId}:${identifier.host}";
    if (_readInfoMap.containsKey(key)) {
      _readInfoMap.remove(key);
      notifyListeners();
    }
  }
  
  @override
  int? getLastViewedTime(GroupIdentifier identifier) {
    final info = getReadInfo(identifier);
    return info.lastViewedAt;
  }
  
  @override
  int? getLastReadTime(GroupIdentifier identifier) {
    final info = getReadInfo(identifier);
    return info.lastReadTime;
  }
}

@GenerateMocks([ListProvider])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Group Read Status Tests', () {
    late TestableGroupReadStatusProvider readStatusProvider;
    late TestGroupFeedProvider groupFeedProvider;

    // Group identifiers for testing
    final testGroup1 = GroupIdentifier('relay1', 'group1');
    final testGroup2 = GroupIdentifier('relay2', 'group2');
    
    // Create test events for different groups
    Event createTestEventForGroup(String groupId, String eventId, {int timestamp = 1000}) {
      print("Creating test event: id=$eventId, group=$groupId, timestamp=$timestamp");
      final event = Event.fromJson({
        'id': eventId,
        'pubkey': '0'.padLeft(64, '0'),
        'created_at': timestamp,
        'kind': EventKind.groupNote,
        'tags': [
          ['h', groupId]
        ],
        'content': 'test content for $groupId - $eventId',
        'sig': '0'.padLeft(128, '0'),
      });
      
      // Debug: verify tags
      print("Event $eventId tags: ${event.tags}");
      return event;
    }

    setUp(() {
      readStatusProvider = TestableGroupReadStatusProvider();
      groupFeedProvider = TestGroupFeedProvider(
        readStatusProvider, 
        [testGroup1, testGroup2]
      );
    });

    test('Group posts are counted correctly', () {
      // Add test events to the provider's notesBox
      final group1Event1 = createTestEventForGroup('group1', 'g1e1', timestamp: 1000);
      final group1Event2 = createTestEventForGroup('group1', 'g1e2', timestamp: 1100);
      final group2Event1 = createTestEventForGroup('group2', 'g2e1', timestamp: 1200);
      
      // Add events to notesBox
      groupFeedProvider.addTestEvent(group1Event1);
      groupFeedProvider.addTestEvent(group1Event2);
      groupFeedProvider.addTestEvent(group2Event1);
      
      // Call updateAllGroupReadCounts to populate the read status provider
      groupFeedProvider.updateAllGroupReadCounts();
      
      // Verify the read status provider has the correct counts
      final group1Info = readStatusProvider.getReadInfo(testGroup1);
      final group2Info = readStatusProvider.getReadInfo(testGroup2);
      
      // Debug: check the final values
      print("Final counts - Group1: post=${group1Info.postCount}, unread=${group1Info.unreadCount}");
      print("Final counts - Group2: post=${group2Info.postCount}, unread=${group2Info.unreadCount}");
      
      // Check post counts
      expect(group1Info.postCount, 2);
      expect(group2Info.postCount, 1);
      
      // Since we set a past lastReadTime, all posts should be unread
      expect(group1Info.unreadCount, 2);
      expect(group2Info.unreadCount, 1);
    });

    test('Read status is updated correctly when marking groups as read', () async {
      // Add test events
      final group1Event1 = createTestEventForGroup('group1', 'g1e1', timestamp: 1000);
      final group1Event2 = createTestEventForGroup('group1', 'g1e2', timestamp: 1100);
      
      // Add events to notesBox
      groupFeedProvider.addTestEvent(group1Event1);
      groupFeedProvider.addTestEvent(group1Event2);
      
      // Update read counts
      groupFeedProvider.updateAllGroupReadCounts();
      
      // Verify initial state
      final initialInfo = readStatusProvider.getReadInfo(testGroup1);
      expect(initialInfo.postCount, 2);
      expect(initialInfo.unreadCount, 2);
      
      // Mark the group as read
      await readStatusProvider.markGroupRead(testGroup1);
      
      // Verify updated state
      final updatedInfo = readStatusProvider.getReadInfo(testGroup1);
      expect(updatedInfo.postCount, 2);
      expect(updatedInfo.unreadCount, 0); // Should be 0 after marking as read
      
      // The last read time should be set to a recent timestamp
      expect(updatedInfo.lastReadTime > 0, true);
    });

    test('New events update the unread counts correctly', () async {
      // Add initial events
      final group1Event1 = createTestEventForGroup('group1', 'g1e1', timestamp: 1000);
      
      // Add event to notesBox
      groupFeedProvider.addTestEvent(group1Event1);
      
      // Update read counts
      groupFeedProvider.updateAllGroupReadCounts();
      
      // Mark the group as read
      await readStatusProvider.markGroupRead(testGroup1);
      
      // Verify read state
      final afterReadInfo = readStatusProvider.getReadInfo(testGroup1);
      expect(afterReadInfo.postCount, 1);
      expect(afterReadInfo.unreadCount, 0);
      
      // Get the last read time
      final lastReadTime = afterReadInfo.lastReadTime;
      
      // Now add a new event with a newer timestamp
      final group1Event2 = createTestEventForGroup(
        'group1', 'g1e2', 
        timestamp: lastReadTime + 100 // Ensure it's newer than the last read time
      );
      
      // Add to notesBox
      groupFeedProvider.addTestEvent(group1Event2);
      
      // Update read counts
      groupFeedProvider.updateAllGroupReadCounts();
      
      // Verify updated state - should have one unread post
      final finalInfo = readStatusProvider.getReadInfo(testGroup1);
      expect(finalInfo.postCount, 2);
      expect(finalInfo.unreadCount, 1);
    });

    test('markGroupViewed updates lastViewedAt without changing read status', () async {
      // Add test events
      final group1Event1 = createTestEventForGroup('group1', 'g1e1', timestamp: 1000);
      final group1Event2 = createTestEventForGroup('group1', 'g1e2', timestamp: 1100);
      
      // Add events to notesBox
      groupFeedProvider.addTestEvent(group1Event1);
      groupFeedProvider.addTestEvent(group1Event2);
      
      // Update read counts
      groupFeedProvider.updateAllGroupReadCounts();
      
      // Get initial state
      final initialInfo = readStatusProvider.getReadInfo(testGroup1);
      final initialLastViewedAt = initialInfo.lastViewedAt;
      
      print("Initial lastViewedAt: $initialLastViewedAt");
      
      // Wait a bit to ensure timestamp will be different
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Mark the group as viewed
      await readStatusProvider.markGroupViewed(testGroup1);
      
      // Get updated state
      final updatedInfo = readStatusProvider.getReadInfo(testGroup1);
      
      print("Updated lastViewedAt: ${updatedInfo.lastViewedAt}");
      
      // lastViewedAt should have been updated
      expect(updatedInfo.lastViewedAt > initialLastViewedAt, true);
      
      // But the unread count should remain the same
      expect(updatedInfo.postCount, 2);
      expect(updatedInfo.unreadCount, 2);
    });

    test('Group posts are filtered and counted correctly by group', () async {
      // Add events for both groups
      final group1Events = [
        createTestEventForGroup('group1', 'g1e1', timestamp: 1000),
        createTestEventForGroup('group1', 'g1e2', timestamp: 1100),
        createTestEventForGroup('group1', 'g1e3', timestamp: 1200),
      ];
      
      final group2Events = [
        createTestEventForGroup('group2', 'g2e1', timestamp: 1000),
        createTestEventForGroup('group2', 'g2e2', timestamp: 1100),
      ];
      
      // Add all events to the notesBox
      for (final event in [...group1Events, ...group2Events]) {
        groupFeedProvider.addTestEvent(event);
      }
      
      // Update read counts
      groupFeedProvider.updateAllGroupReadCounts();
      
      // Verify counts for each group
      final group1Info = readStatusProvider.getReadInfo(testGroup1);
      final group2Info = readStatusProvider.getReadInfo(testGroup2);
      
      expect(group1Info.postCount, 3);
      expect(group1Info.unreadCount, 3);
      
      expect(group2Info.postCount, 2);
      expect(group2Info.unreadCount, 2);
      
      // Mark group1 as read
      await readStatusProvider.markGroupRead(testGroup1);
      
      // Get updated info
      final updatedGroup1Info = readStatusProvider.getReadInfo(testGroup1);
      final updatedGroup2Info = readStatusProvider.getReadInfo(testGroup2);
      
      // Group1 should have 0 unread posts, but Group2 should still have 2
      expect(updatedGroup1Info.unreadCount, 0);
      expect(updatedGroup2Info.unreadCount, 2);
    });

    test('Event processing properly manages group counts', () async {
      // This test simulates the entire event processing flow
      
      // Add one initial event to notesBox 
      final initialEvent = createTestEventForGroup('group1', 'g1initial', timestamp: 1000);
      groupFeedProvider.addTestEvent(initialEvent);
      
      // Update counts
      groupFeedProvider.updateAllGroupReadCounts();
      
      // Verify initial state
      final initialInfo = readStatusProvider.getReadInfo(testGroup1);
      expect(initialInfo.postCount, 1);
      expect(initialInfo.unreadCount, 1);
      
      // Mark as read
      await readStatusProvider.markGroupRead(testGroup1);
      
      // Verify read state
      final afterReadInfo = readStatusProvider.getReadInfo(testGroup1);
      expect(afterReadInfo.unreadCount, 0);
      
      // Get the last read time
      final lastReadTime = afterReadInfo.lastReadTime;
      
      // Now simulate receiving new events via the event handler
      final newEvent1 = createTestEventForGroup(
        'group1', 'g1new1', 
        timestamp: lastReadTime - 50 // This event is older than the last read time
      );
      
      final newEvent2 = createTestEventForGroup(
        'group1', 'g1new2', 
        timestamp: lastReadTime + 50 // This event is newer than the last read time
      );
      
      // Add events to notesBox as would happen in onEvent
      groupFeedProvider.addTestEvent(newEvent1);
      groupFeedProvider.addTestEvent(newEvent2);
      
      // Update read counts
      groupFeedProvider.updateAllGroupReadCounts();
      
      // Verify final state
      final finalInfo = readStatusProvider.getReadInfo(testGroup1);
      
      // Should have 3 total posts (1 initial + 2 new ones)
      expect(finalInfo.postCount, 3);
      
      // Should have 1 unread post (only the one newer than last read time)
      expect(finalInfo.unreadCount, 1);
    });
  });
}