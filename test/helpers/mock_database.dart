import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';

/// Mock database helper for testing database operations in memory
class MockDatabase {
  static Database? _db;
  static final String _testDbName = "test_nostrmo.db";
  static bool _initialized = false;
  
  /// Initialize a real in-memory SQLite database for testing
  static Future<Database> openTestDatabase() async {
    if (!_initialized) {
      try {
        // Initialize FFI
        sqfliteFfiInit();
        
        // Set global factory to FFI
        databaseFactory = databaseFactoryFfi;
        
        _initialized = true;
      } catch (e) {
        print("Error initializing FFI: $e");
      }
    }
    
    // If we already have a database, return it
    if (_db != null) {
      return _db!;
    }
    
    // Get a temp directory for the test database
    final dbPath = inMemoryDatabasePath;
    
    // Create the database in memory
    try {
      _db = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            // Create tables needed for tests
            await db.execute(
              "create table group_read_info("
              "key_index INTEGER, "
              "group_id TEXT NOT NULL, "
              "host TEXT NOT NULL, "
              "last_read_time INTEGER NOT NULL, "
              "post_count INTEGER DEFAULT 0, "
              "unread_count INTEGER DEFAULT 0, "
              "last_viewed_at INTEGER NOT NULL, "
              "PRIMARY KEY (key_index, group_id, host)"
              ");"
            );
            
            await db.execute(
              "create index group_read_info_key_index on group_read_info (key_index);"
            );
            
            await db.execute(
              "create index group_read_info_group_id on group_read_info (group_id);"
            );
            
            // Create event table for tests
            await db.execute(
              "create table event("
              "key_index INTEGER, "
              "id TEXT, "
              "pubkey TEXT, "
              "created_at INTEGER, "
              "kind INTEGER, "
              "tags TEXT, "
              "content TEXT);"
            );
            
            await db.execute(
              "create index event_date_index on event (key_index, kind, created_at);"
            );
          }
        )
      );
      
      return _db!;
    } catch (e) {
      print("Error creating test database: $e");
      rethrow;
    }
  }
  
  /// Reset the test database by clearing all data
  static Future<void> resetDatabase() async {
    if (_db != null) {
      try {
        await _db!.execute("DELETE FROM group_read_info");
        await _db!.execute("DELETE FROM event");
      } catch (e) {
        print("Error resetting database: $e");
      }
    }
  }
  
  /// Close the test database
  static Future<void> closeDatabase() async {
    if (_db != null) {
      try {
        await _db!.close();
        _db = null;
      } catch (e) {
        print("Error closing database: $e");
      }
    }
  }
  
  /// Mock DB singleton to override the main DB class
  static void mockDbOperations() {
    // This method can be used to override the real DB operations if needed
  }
}