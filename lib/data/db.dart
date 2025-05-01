import 'dart:io';

import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';

class DB {
  // Update version to 2 to trigger database migration
  static const _version = 2;

  static const _dbName = "nostrmo.db";

  static Database? _database;

  static init() async {
    String path = _dbName;

    if (!PlatformUtil.isWeb()) {
      var databasesPath = await getDatabasesPath();
      path = join(databasesPath, _dbName);
    }

    try {
      _database = await openDatabase(
        path, 
        version: _version, 
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      if (Platform.isLinux) {
        // maybe it need install sqlite first, but this command need run by root.
        await run('sudo apt-get -y install libsqlite3-0 libsqlite3-dev');
        _database = await openDatabase(
          path, 
          version: _version, 
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        );
      }
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    // init db
    db.execute(
        "create table metadata(pub_key      TEXT not null primary key,banner       TEXT,website      TEXT,lud16        TEXT,lud06        TEXT,nip05        TEXT,picture      TEXT,display_name TEXT,about        TEXT,name         TEXT,updated_at   datetime, valid  INTEGER);");
    db.execute(
        "create table event(key_index  INTEGER, id         text,pubkey     text,created_at integer,kind       integer,tags       text,content    text);");
    db.execute(
        "create unique index event_key_index_id_uindex on event (key_index, id);");
    db.execute(
        "create index event_date_index    on event (key_index, kind, created_at);");
    db.execute(
        "create index event_pubkey_index    on event (key_index, kind, pubkey, created_at);");
    db.execute(
        "create table dm_session_info(key_index  INTEGER, pubkey      text    not null,readed_time integer not null,value1      text,value2      text,value3      text);");
    db.execute(
        "create unique index dm_session_info_uindex on dm_session_info (key_index, pubkey);");
        
    // Add group_read_info table for tracking group activity
    db.execute(
        "create table group_read_info("
        "key_index INTEGER, "
        "group_id TEXT NOT NULL, "
        "host TEXT NOT NULL, "
        "last_read_time INTEGER NOT NULL, "
        "post_count INTEGER DEFAULT 0, "
        "unread_count INTEGER DEFAULT 0, "
        "last_viewed_at INTEGER NOT NULL, "
        "PRIMARY KEY (key_index, group_id, host)"
        ");");
    db.execute(
        "create index group_read_info_key_index on group_read_info (key_index);");
    db.execute(
        "create index group_read_info_group_id on group_read_info (group_id);");
  }
  
  // Handle database migrations
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add group_read_info table for existing installations
      try {
        await db.execute(
          "create table if not exists group_read_info("
          "key_index INTEGER, "
          "group_id TEXT NOT NULL, "
          "host TEXT NOT NULL, "
          "last_read_time INTEGER NOT NULL, "
          "post_count INTEGER DEFAULT 0, "
          "unread_count INTEGER DEFAULT 0, "
          "last_viewed_at INTEGER NOT NULL, "
          "PRIMARY KEY (key_index, group_id, host)"
          ");");
        await db.execute(
          "create index if not exists group_read_info_key_index on group_read_info (key_index);");
        await db.execute(
          "create index if not exists group_read_info_group_id on group_read_info (group_id);");
      } catch (e) {
        print("Error during migration to v2: $e");
      }
    }
  }

  static Future<Database> getCurrentDatabase() async {
    if (_database == null) {
      await init();
    }
    return _database!;
  }

  /// Returns an existing database executor if provided, otherwise returns the current database
  /// Important: When using transactions, always pass the transaction object to nested operations
  static Future<DatabaseExecutor> getDB(DatabaseExecutor? db) async {
    if (db != null) {
      return db;
    }
    return getCurrentDatabase();
  }
  
  /// Executes database operations in a transaction to prevent database locking
  /// This method should be used when performing multiple related database operations
  static Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await getCurrentDatabase();
    return await db.transaction(action);
  }

  static void close() {
    _database?.close();
    _database = null;
  }
}
