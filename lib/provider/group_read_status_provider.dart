import 'package:flutter/foundation.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../data/group_read_info.dart';
import '../data/group_read_info_db.dart';

/// Provider that manages the read/unread status for groups
class GroupReadStatusProvider extends ChangeNotifier {
  final int _keyIndex;
  Map<String, GroupReadInfo> _groupReadInfo = {};
  bool _isLoaded = false;
  bool _isInitializing = false;

  GroupReadStatusProvider({int keyIndex = 0}) : _keyIndex = keyIndex;

  /// Get a unique key from group ID and host
  String _getKey(String groupId, String host) => "$groupId:$host";
  
  /// Get a unique key from a GroupIdentifier
  String _getKeyFromIdentifier(GroupIdentifier identifier) => 
      _getKey(identifier.groupId, identifier.host);

  /// Initialize the provider by loading data from database
  Future<void> init() async {
    if (_isLoaded || _isInitializing) return;
    
    _isInitializing = true;
    try {
      final allInfo = await GroupReadInfoDB.all(_keyIndex);
      for (var info in allInfo) {
        _groupReadInfo[_getKey(info.groupId, info.host)] = info;
      }
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint("Error initializing GroupReadStatusProvider: $e");
    } finally {
      _isInitializing = false;
    }
  }

  /// Check if the provider has been initialized
  bool get isInitialized => _isLoaded;

  /// Get read info for a group
  GroupReadInfo getReadInfo(GroupIdentifier identifier) {
    final key = _getKeyFromIdentifier(identifier);
    if (!_groupReadInfo.containsKey(key)) {
      // Create new info if it doesn't exist
      final info = GroupReadInfo.fromGroupIdentifier(
        identifier,
        keyIndex: _keyIndex,
      );
      _groupReadInfo[key] = info;
      // Save to DB
      GroupReadInfoDB.insertOrUpdate(info);
    }
    return _groupReadInfo[key]!;
  }

  /// Get unread count for a specific group
  int getUnreadCount(GroupIdentifier identifier) {
    final key = _getKeyFromIdentifier(identifier);
    if (_groupReadInfo.containsKey(key)) {
      return _groupReadInfo[key]!.unreadCount;
    }
    return 0;
  }

  /// Get post count for a specific group
  int getPostCount(GroupIdentifier identifier) {
    final key = _getKeyFromIdentifier(identifier);
    if (_groupReadInfo.containsKey(key)) {
      return _groupReadInfo[key]!.postCount;
    }
    return 0;
  }

  /// Check if a group has unread posts
  bool hasUnread(GroupIdentifier identifier) {
    final key = _getKeyFromIdentifier(identifier);
    if (_groupReadInfo.containsKey(key)) {
      return _groupReadInfo[key]!.unreadCount > 0;
    }
    return false;
  }

  /// Mark a group as viewed (without marking all posts as read)
  Future<void> markGroupViewed(GroupIdentifier identifier) async {
    final key = _getKeyFromIdentifier(identifier);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    if (_groupReadInfo.containsKey(key)) {
      final info = _groupReadInfo[key]!;
      info.lastViewedAt = now;
      await GroupReadInfoDB.updateLastViewedAt(
        _keyIndex, 
        identifier.groupId, 
        identifier.host
      );
    } else {
      final info = GroupReadInfo.fromGroupIdentifier(
        identifier,
        keyIndex: _keyIndex,
        timestamp: now,
      );
      _groupReadInfo[key] = info;
      await GroupReadInfoDB.insertOrUpdate(info);
    }
    
    notifyListeners();
  }

  /// Mark all posts in a group as read
  Future<void> markGroupRead(GroupIdentifier identifier) async {
    final key = _getKeyFromIdentifier(identifier);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    if (_groupReadInfo.containsKey(key)) {
      final info = _groupReadInfo[key]!;
      info.lastReadTime = now;
      info.lastViewedAt = now;
      info.unreadCount = 0;
      
      await GroupReadInfoDB.markAsRead(
        _keyIndex, 
        identifier.groupId, 
        identifier.host
      );
    } else {
      final info = GroupReadInfo.fromGroupIdentifier(
        identifier,
        keyIndex: _keyIndex,
        timestamp: now,
      );
      _groupReadInfo[key] = info;
      await GroupReadInfoDB.insertOrUpdate(info);
    }
    
    notifyListeners();
  }

  /// Update post counts based on new data
  Future<void> updateCounts(
    GroupIdentifier identifier, 
    int totalPosts, 
    int newPosts
  ) async {
    final key = _getKeyFromIdentifier(identifier);
    
    if (_groupReadInfo.containsKey(key)) {
      final info = _groupReadInfo[key]!;
      // Only notify if counts changed
      bool changed = info.postCount != totalPosts || info.unreadCount != newPosts;
      
      info.postCount = totalPosts;
      info.unreadCount = newPosts;
      
      await GroupReadInfoDB.updateCounts(
        _keyIndex,
        identifier.groupId,
        identifier.host,
        totalPosts,
        newPosts,
      );
      
      if (changed) {
        notifyListeners();
      }
    } else {
      final info = GroupReadInfo.fromGroupIdentifier(
        identifier,
        keyIndex: _keyIndex,
      );
      info.postCount = totalPosts;
      info.unreadCount = newPosts;
      _groupReadInfo[key] = info;
      
      await GroupReadInfoDB.insertOrUpdate(info);
      notifyListeners();
    }
  }

  /// Get total unread count across all groups
  int getTotalUnreadCount() {
    int total = 0;
    for (var info in _groupReadInfo.values) {
      total += info.unreadCount;
    }
    return total;
  }
  
  /// Get all groups with unread posts
  List<GroupIdentifier> getGroupsWithUnread() {
    return _groupReadInfo.values
        .where((info) => info.unreadCount > 0)
        .map((info) => GroupIdentifier(info.host, info.groupId))
        .toList();
  }
  
  /// Calculate unread posts for a list of events and a group
  int calculateUnreadCount(List<Event> events, GroupIdentifier groupId, int? lastReadTime) {
    if (lastReadTime == null) {
      // If no last read time, all posts are unread
      return events.length;
    }
    
    return events.where((event) => event.createdAt > lastReadTime).length;
  }

  /// Clear all data
  Future<void> clear() async {
    await GroupReadInfoDB.deleteAll(_keyIndex);
    _groupReadInfo.clear();
    notifyListeners();
  }
  
  /// Clear data for a specific group
  Future<void> clearGroup(GroupIdentifier identifier) async {
    final key = _getKeyFromIdentifier(identifier);
    if (_groupReadInfo.containsKey(key)) {
      _groupReadInfo.remove(key);
      await GroupReadInfoDB.deleteByIdentifier(_keyIndex, identifier);
      notifyListeners();
    }
  }
  
  /// Get when a group was last viewed
  int? getLastViewedTime(GroupIdentifier identifier) {
    final key = _getKeyFromIdentifier(identifier);
    if (_groupReadInfo.containsKey(key)) {
      return _groupReadInfo[key]!.lastViewedAt;
    }
    return null;
  }
  
  /// Get when a group was last read
  int? getLastReadTime(GroupIdentifier identifier) {
    final key = _getKeyFromIdentifier(identifier);
    if (_groupReadInfo.containsKey(key)) {
      return _groupReadInfo[key]!.lastReadTime;
    }
    return null;
  }
}