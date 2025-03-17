import 'package:shared_preferences/shared_preferences.dart';

class DataUtil {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> getInstance() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }
}

class DataKey {
  static const String setting = "setting";

  static const String contactLists = "contactLists";

  static const String blockList = "blockList";

  static const String dirtywordList = "dirtywordList";

  static const String customEmojiList = "customEmojiList";

  static const String cacheRelays = "cacheRelays";

  static const String wotPre = "wot_";
}
