import 'package:nostrmo/util/hash_util.dart';

class Base {
  /// App name, visible in web browsers
  static const APP_NAME = "Plur";

  static const String PRIVACY_LINK =
      "https://www.nos.social/terms-of-service";

  static const double BASE_PADDING = 12;

  static const double BASE_PADDING_HALF = 6;

  static String INDEXS_EVENTS = "https://nostrmo.com/indexs/events.json";

  static String INDEXS_CONTACTS = "https://nostrmo.com/indexs/contacts.json";

  static String INDEXS_TOPICS = "https://nostrmo.com/indexs/topics.json";

  static String INDEXS_RELAYS = "https://nostrmo.com/indexs/relays.json";

  static String WEB_TOOLS = "https://nostrmo.com/indexs/webtools.json";

  static String IMAGE_PROXY_SERVICE = "https://imagebridge.nostrmo.com/";

  static String IMAGE_PROXY_SERVICE_KEY = "please_do_not_abuse_thanks";

  static String KEY_EKEY = HashUtil.md5("Jo49KwLvyhrsar");

  static String KEY_IV = "1681713832000000";

  static double BASE_FONT_SIZE = 15;

  static double BASE_FONT_SIZE_PC = 15;

  static double TABBAR_HEIGHT = 46;

  static int DEFAULT_DATA_INDEX = -1;
}
