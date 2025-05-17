import 'package:flutter/foundation.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:sqflite/sqflite.dart';

import 'db.dart';
import 'group_read_info.dart';
import '../util/app_logger.dart';

/// Database access class for GroupReadInfo
class GroupReadInfoDB {
  static const String _tableName = "group_read_info";

  /// Get all group read info for a key index
  static Future<List<GroupReadInfo>> all(int keyIndex,
      {DatabaseExecutor? db}) async {
    db = await DB.getDB(db);
    List<GroupReadInfo> results = [];
    
    var sql = "SELECT * FROM $_tableName WHERE key_index = ?";
    List<Map<String, dynamic>> list = await db.rawQuery(sql, [keyIndex]);
    
    for (var item in list) {
      results.add(GroupReadInfo.fromJson(item));
    }
    return results;
  }

  /// Get group read info for a specific group
  static Future<GroupReadInfo?> get(
    int keyIndex, 
    String groupId, 
    String host,
    {DatabaseExecutor? db}
  ) async {
    db = await DB.getDB(db);
    var list = await db.query(
      _tableName,
      where: "key_index = ? AND group_id = ? AND host = ?", 
      whereArgs: [keyIndex, groupId, host]
    );
    
    if (list.isNotEmpty) {
      return GroupReadInfo.fromJson(list.first);
    }
    return null;
  }

  /// Get group read info by GroupIdentifier
  static Future<GroupReadInfo?> getByIdentifier(
    int keyIndex,
    GroupIdentifier identifier,
    {DatabaseExecutor? db}
  ) async {
    return await get(keyIndex, identifier.groupId, identifier.host, db: db);
  }

  /// Insert or update group read info
  static Future<void> insertOrUpdate(
    GroupReadInfo info, 
    {DatabaseExecutor? db}
  ) async {
    db = await DB.getDB(db);
    try {
      await db.insert(
        _tableName, 
        info.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      logger.e("Error inserting group read info", e);
    }
  }

  /// Update the last read time for a group
  static Future<void> updateLastReadTime(
    int keyIndex,
    String groupId,
    String host,
    int timestamp,
    {DatabaseExecutor? db}
  ) async {
    db = await DB.getDB(db);
    try {
      await db.update(
        _tableName,
        {"last_read_time": timestamp},
        where: "key_index = ? AND group_id = ? AND host = ?",
        whereArgs: [keyIndex, groupId, host],
      );
    } catch (e) {
      logger.e("Error updating last read time", e);
    }
  }

  /// Update the last viewed timestamp for a group
  static Future<void> updateLastViewedAt(
    int keyIndex,
    String groupId,
    String host,
    {DatabaseExecutor? db}
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    db = await DB.getDB(db);
    try {
      await db.update(
        _tableName,
        {"last_viewed_at": now},
        where: "key_index = ? AND group_id = ? AND host = ?",
        whereArgs: [keyIndex, groupId, host],
      );
    } catch (e) {
      logger.e("Error updating last viewed at", e);
    }
  }

  /// Update post counts for a group
  static Future<void> updateCounts(
    int keyIndex,
    String groupId,
    String host,
    int postCount,
    int unreadCount,
    {DatabaseExecutor? db}
  ) async {
    db = await DB.getDB(db);
    try {
      await db.update(
        _tableName,
        {
          "post_count": postCount,
          "unread_count": unreadCount,
        },
        where: "key_index = ? AND group_id = ? AND host = ?",
        whereArgs: [keyIndex, groupId, host],
      );
    } catch (e) {
      logger.e("Error updating counts", e);
    }
  }

  /// Mark a group as fully read, clearing unread count
  static Future<void> markAsRead(
    int keyIndex,
    String groupId,
    String host,
    {DatabaseExecutor? db}
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    db = await DB.getDB(db);
    try {
      await db.update(
        _tableName,
        {
          "unread_count": 0,
          "last_read_time": now,
          "last_viewed_at": now,
        },
        where: "key_index = ? AND group_id = ? AND host = ?",
        whereArgs: [keyIndex, groupId, host],
      );
    } catch (e) {
      logger.e("Error marking group as read", e);
    }
  }
  
  /// Mark a group as read by GroupIdentifier
  static Future<void> markAsReadByIdentifier(
    int keyIndex,
    GroupIdentifier identifier,
    {DatabaseExecutor? db}
  ) async {
    await markAsRead(keyIndex, identifier.groupId, identifier.host, db: db);
  }

  /// Delete all records for a key index
  static Future<void> deleteAll(int keyIndex, {DatabaseExecutor? db}) async {
    db = await DB.getDB(db);
    try {
      await db.delete(
        _tableName, 
        where: "key_index = ?", 
        whereArgs: [keyIndex]
      );
    } catch (e) {
      logger.e("Error deleting all group read info", e);
    }
  }
  
  /// Delete a specific group's read info
  static Future<void> delete(
    int keyIndex,
    String groupId,
    String host,
    {DatabaseExecutor? db}
  ) async {
    db = await DB.getDB(db);
    try {
      await db.delete(
        _tableName,
        where: "key_index = ? AND group_id = ? AND host = ?",
        whereArgs: [keyIndex, groupId, host],
      );
    } catch (e) {
      logger.e("Error deleting group read info", e);
    }
  }
  
  /// Delete read info by GroupIdentifier
  static Future<void> deleteByIdentifier(
    int keyIndex,
    GroupIdentifier identifier,
    {DatabaseExecutor? db}
  ) async {
    await delete(keyIndex, identifier.groupId, identifier.host, db: db);
  }
}