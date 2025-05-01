import 'package:nostr_sdk/nostr_sdk.dart';

/// Data model for tracking group read/unread status and post counts
class GroupReadInfo {
  /// The key index for multi-account support
  int? keyIndex;
  
  /// The group identifier
  String groupId;
  
  /// The relay host
  String host;
  
  /// Timestamp of the last read post
  int lastReadTime;
  
  /// Total number of posts in the group
  int postCount;
  
  /// Number of unread posts in the group
  int unreadCount;
  
  /// When the user last viewed this group
  int lastViewedAt;

  GroupReadInfo({
    this.keyIndex,
    required this.groupId,
    required this.host,
    required this.lastReadTime,
    this.postCount = 0,
    this.unreadCount = 0,
    required this.lastViewedAt,
  });

  /// Create from a GroupIdentifier with default values
  factory GroupReadInfo.fromGroupIdentifier(
    GroupIdentifier identifier, {
    int? keyIndex,
    int? timestamp,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return GroupReadInfo(
      keyIndex: keyIndex,
      groupId: identifier.groupId,
      host: identifier.host,
      lastReadTime: timestamp ?? now,
      lastViewedAt: now,
    );
  }

  /// Create from a database record
  GroupReadInfo.fromJson(Map<String, dynamic> json)
      : keyIndex = json['key_index'],
        groupId = json['group_id'],
        host = json['host'],
        lastReadTime = json['last_read_time'],
        postCount = json['post_count'] ?? 0,
        unreadCount = json['unread_count'] ?? 0,
        lastViewedAt = json['last_viewed_at'];

  /// Convert to a database record
  Map<String, dynamic> toJson() {
    return {
      'key_index': keyIndex,
      'group_id': groupId,
      'host': host,
      'last_read_time': lastReadTime,
      'post_count': postCount,
      'unread_count': unreadCount,
      'last_viewed_at': lastViewedAt,
    };
  }
  
  /// Get GroupIdentifier from this read info
  GroupIdentifier toGroupIdentifier() {
    return GroupIdentifier(host, groupId);
  }
  
  /// Check if this group has been read recently
  bool get hasUnread => unreadCount > 0;
  
  /// Check if this group has any posts
  bool get hasPosts => postCount > 0;
  
  /// Get the percentage of read posts
  double get readPercentage {
    if (postCount == 0) return 1.0;
    return (postCount - unreadCount) / postCount;
  }
  
  /// Mark this group as fully read
  void markRead() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    lastReadTime = now;
    lastViewedAt = now;
    unreadCount = 0;
  }
  
  /// Mark this group as viewed (without marking all posts as read)
  void markViewed() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    lastViewedAt = now;
  }
  
  /// Update the post counts
  void updateCounts(int totalPosts, int newPosts) {
    postCount = totalPosts;
    unreadCount = newPosts;
  }
  
  @override
  String toString() {
    return 'GroupReadInfo{groupId: $groupId, postCount: $postCount, unreadCount: $unreadCount}';
  }
}