import 'package:nostrmo/util/hash_util.dart';

/// Top-level contants.
class Base {
  /// App name, visible in web browsers.
  static const appName = "Plur";

  /// Link to terms of service.
  static const String privacyLink = "https://www.nos.social/terms-of-service";

  /// Standard padding to use when composing screens.
  static const double basePadding = 12;

  /// Half of [basePadding].
  static const double basePaddingHalf = 6;

  /// Url used by [GlobalEventsWidget].
  static String indexsEvents = "https://nostrmo.com/indexs/events.json";

  /// Url used by [GlobalUsersWidget] and [FollowSuggestWidget].
  static String indexsContacts = "https://nostrmo.com/indexs/contacts.json";

  /// Url used by [GlobalTagsWidget].
  static String indexsTopics = "https://nostrmo.com/indexs/topics.json";

  /// Url used by [RelayhubWidget].
  static String indexsRelays = "https://nostrmo.com/indexs/relays.json";

  /// Url used by [WebUtilsWidget].
  static String webTools = "https://nostrmo.com/indexs/webtools.json";

  /// Url used by [RetryHttpFileService].
  static String imageProxyService = "https://imagebridge.nostrmo.com/";

  /// Key used by [RetryHttpFileService].
  static String imageProxyServiceKey = "please_do_not_abuse_thanks";

  /// Key to use in AES encryption along with [keyIV].
  static String keyEKey = HashUtil.md5("Jo49KwLvyhrsar");

  /// Initialization vector to use in AES encryption along with [keyEKey].
  static String keyIV = "1681713832000000";

  /// Font size used by [SettingsProvider].
  static double baseFontSize = 15;

  /// Font size used by [SettingsProvider] in big screens.
  static double baseFontSizePC = 15;

  /// Height of tab bar.
  static double tabBarHeight = 46;

  /// Default index to use when inserting to the events database.
  static int defaultDataIndex = -1;

  /// Maximum width that the view should expand to on bigger screens.
  static const double maxScreenWidth = 600;
}
