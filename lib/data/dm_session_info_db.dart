import 'package:nostrmo/data/dm_session_info.dart';
import 'package:sqflite/sqflite.dart';
import '../util/app_logger.dart';

import 'db.dart';

class DMSessionInfoDB {
  static Future<List<DMSessionInfo>> all(int keyIndex,
      {DatabaseExecutor? db}) async {
    db = await DB.getDB(db);
    List<DMSessionInfo> l = [];
    List<dynamic> args = [keyIndex];

    var sql = "select * from dm_session_info where key_index = ?";

    List<Map<String, dynamic>> list = await db.rawQuery(sql, args);
    for (var listObj in list) {
      l.add(DMSessionInfo.fromJson(listObj));
    }
    return l;
  }

  static Future<int> insert(DMSessionInfo o, {DatabaseExecutor? db}) async {
    db = await DB.getDB(db);
    var jsonObj = o.toJson();
    return await db.insert(
      "dm_session_info", 
      jsonObj,
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  static Future<int> update(DMSessionInfo o, {DatabaseExecutor? db}) async {
    // Check if keyIndex and pubkey are not null before updating
    if (o.keyIndex == null || o.pubkey == null) {
      logger.w("Cannot update DMSessionInfo with null keyIndex or pubkey");
      return 0; // Return 0 rows affected
    }
    
    db = await DB.getDB(db);
    var jsonObj = o.toJson();
    return await db.update(
      "dm_session_info",
      jsonObj,
      where: "key_index = ? and pubkey = ?",
      whereArgs: [o.keyIndex, o.pubkey],
    );
  }

  static Future<void> deleteAll(int keyIndex, {DatabaseExecutor? db}) async {
    db = await DB.getDB(db);
    db.execute("delete from dm_session_info where key_index = ?", [keyIndex]);
  }
}
