import 'package:nostrmo/consts/thread_mode.dart';
import 'package:nostrmo/main.dart';

/// Defines the named routes used in the application.
class RouterPath {
  /// The root path of the application.
  static const String index = "/";

  /// The route path for the Login screen.
  static const String login = "/login";

  /// The route path for the Onboarding screen.
  static const String onboarding = "/onboarding";

  static const String editor = "/editor";
  static const String donate = "/donate";
  static const String notices = "/notices";
  static const String keyBackup = "/keyBackup";
  static const String relayhub = "/relayhub";
  static const String relays = "/relays";
  static const String filter = "/filter";
  static const String user = "/user";
  static const String profileEditor = "/profileEditor";
  static const String userContactList = "/userContactList";
  static const String userHistoryContactList = "/userHistoryContactList";
  static const String userZapList = "/userZapList";
  static const String userRelays = "/userRelays";
  static const String dmDetail = "/dmDetail";
  static const String threadDetail = "/threadDetail";
  static const String threadTrace = "/threadTrace";
  static const String eventDetail = "/eventDetail";
  static const String tagDetail = "/tagDetail";

  /// The route path for the Settings screen.
  static const String settings = "/settings";

  /// The route path for the Community Guidelines screen.
  static const String communityGuidelines = "/communityGuidelines";

  static const String qrScanner = "/qrScanner";
  static const String webUtils = "/webUtils";
  static const String relayInfo = "/relayInfo";
  static const String followedTagsList = "/followedTagsList";
  static const String communityDetail = "/communityDetail";
  static const String followedCommunities = "/followedCommunities";
  static const String followed = "/followed";
  static const String bookmark = "/bookmark";
  static const String followSetList = "/followSetList";
  static const String followSetDetail = "/followSetDetail";
  static const String followSetFeed = "/followSetFeed";
  static const String nwcSetting = "/nwcSetting";
  static const String groupAdmin = "/groupAdmin";
  static const String groupList = "/groupList";
  static const String groupDetail = "/groupDetail";
  static const String groupEdit = "/groupEdit";
  static const String groupMembers = "/groupMembers";
  static const String groupInfo = "/groupInfo";
  static const String pushNotificationTest = "/pushNotificationTest";

  static String getThreadDetailPath() {
    if (settingsProvider.threadMode == ThreadMode.fullMode) {
      return threadDetail;
    }

    return threadTrace;
  }
}
