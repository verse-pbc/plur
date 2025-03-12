import 'package:nostrmo/util/hash_util.dart';

class Base {
  /// App name, visible in web browsers
  static const appName = "Plur";

  static const String privacyLink =
      "https://www.nos.social/terms-of-service";

  static const double basePadding = 12;

  static const double basePaddingHalf = 6;

  static String indexsEvents = "https://nostrmo.com/indexs/events.json";

  static String indexsContacts = "https://nostrmo.com/indexs/contacts.json";

  static String indexsTopics = "https://nostrmo.com/indexs/topics.json";

  static String indexsRelays = "https://nostrmo.com/indexs/relays.json";

  static String webTools = "https://nostrmo.com/indexs/webtools.json";

  static String imageProxyService = "https://imagebridge.nostrmo.com/";

  static String imageProxyServiceKey = "please_do_not_abuse_thanks";

  static String keyEKey = HashUtil.md5("Jo49KwLvyhrsar");

  static String KEY_IV = "1681713832000000";

  static double BASE_FONT_SIZE = 15;

  static double BASE_FONT_SIZE_PC = 15;

  static double TABBAR_HEIGHT = 46;

  static int DEFAULT_DATA_INDEX = -1;
}
