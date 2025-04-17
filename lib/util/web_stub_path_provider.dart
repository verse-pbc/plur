// Web stub for path_provider
// This file provides stub implementations for path_provider methods
// used on web platform where they don't natively exist

import 'dart:async';

// Simple directory class that mimics the real one
class Directory {
  final String path;
  Directory(this.path);
  
  bool existsSync() => false;
  void createSync({bool recursive = false}) {}
}

// Mock implementations of path_provider functions
Future<Directory> getApplicationDocumentsDirectory() async {
  return Directory('');
}

Future<Directory> getTemporaryDirectory() async {
  return Directory('');
}

Future<Directory> getApplicationSupportDirectory() async {
  return Directory('');
}

Future<Directory> getLibraryDirectory() async {
  return Directory('');
}

Future<Directory> getExternalStorageDirectory() async {
  return Directory('');
}

Future<List<Directory>> getExternalCacheDirectories() async {
  return [];
}

Future<List<Directory>> getExternalStorageDirectories({StorageDirectory? type}) async {
  return [];
}

Future<Directory> getDownloadsDirectory() async {
  return Directory('');
}

// Enum to match the real API
enum StorageDirectory {
  music,
  podcasts,
  ringtones,
  alarms,
  notifications,
  pictures,
  movies,
  downloads,
  dcim,
  documents
}