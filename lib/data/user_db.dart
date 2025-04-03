import 'package:nostrmo/data/user.dart';
import 'package:sqflite/sqflite.dart';

import 'db.dart';

class UserDB {
  static Future<List<User>> all({DatabaseExecutor? db}) async {
    List<User> objs = [];
    Database db = await DB.getCurrentDatabase();
    List<Map<String, dynamic>> list =
        await db.rawQuery("select * from metadata");
    for (var i = 0; i < list.length; i++) {
      var json = list[i];
      objs.add(User.fromJson(json));
    }
    return objs;
  }

  static Future<User?> get(String pubkey, {DatabaseExecutor? db}) async {
    db = await DB.getDB(db);
    var list =
        await db.query("metadata", where: "pub_key = ?", whereArgs: [pubkey]);
    if (list.isNotEmpty) {
      return User.fromJson(list[0]);
    }
    return null;
  }

  static Future<int> insert(User o, {DatabaseExecutor? db}) async {
    db = await DB.getDB(db);
    return await db.insert("metadata", o.toFullJson());
  }

  static Future update(User o, {DatabaseExecutor? db}) async {
    db = await DB.getDB(db);
    await db.update("metadata", o.toJson(),
        where: "pub_key = ?", whereArgs: [o.pubkey]);
  }

  static Future<void> deleteAll({DatabaseExecutor? db}) async {
    db = await DB.getDB(db);
    db.execute("delete from metadata");
  }
}
