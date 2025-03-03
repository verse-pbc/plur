import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'platform_util.dart';

class SqliteUtil {
  static void configSqliteFactory() {
    if (PlatformUtil.isWeb()) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (PlatformUtil.isWindowsOrLinux()) {
      // Initialize FFI
      sqfliteFfiInit();
      // Change the default factory
      databaseFactory = databaseFactoryFfi;
    }
  }
}
