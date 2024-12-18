import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_quill/translations.dart';
import 'package:flutter_socks_proxy/socks_proxy.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/cache_store.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nostr_sdk/client_utils/keys.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostr_sdk/nostr.dart';
import 'package:nostr_sdk/relay_local/relay_local_db.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/content/trie_text_matcher/trie_text_matcher_builder.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/provider/badge_definition_provider.dart';
import 'package:nostrmo/provider/community_info_provider.dart';
import 'package:nostrmo/provider/community_list_provider.dart';
import 'package:nostrmo/provider/follow_new_event_provider.dart';
import 'package:nostrmo/provider/gift_wrap_provider.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/provider/mention_me_new_provider.dart';
import 'package:nostrmo/provider/music_provider.dart';
import 'package:nostrmo/provider/nwc_provider.dart';
import 'package:nostrmo/router/group/group_detail_widget.dart';
import 'package:nostrmo/router/group/group_edit_widget.dart';
import 'package:nostrmo/router/group/communities_widget.dart';
import 'package:nostrmo/router/group/group_members_widget.dart';
import 'package:nostrmo/router/login/login_widget.dart';
import 'package:nostrmo/router/thread_trace_router/thread_trace_widget.dart';
import 'package:nostrmo/router/follow_set/follow_set_feed_widget.dart';
import 'package:nostrmo/router/follow_set/follow_set_list_widget.dart';
import 'package:nostrmo/router/relayhub/relayhub_widget.dart';
import 'package:nostrmo/router/relays/relay_info_widget.dart';
import 'package:nostrmo/router/user/followed_widget.dart';
import 'package:nostrmo/router/user/followed_tags_list_widget.dart';
import 'package:nostrmo/router/user/user_history_contact_list_widget.dart';
import 'package:nostrmo/router/user/user_zap_list_widget.dart';
import 'package:nostrmo/router/web_utils/web_utils_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:window_manager/window_manager.dart';

import 'component/content/trie_text_matcher/trie_text_matcher.dart';
import 'consts/base.dart';
import 'consts/colors.dart';
import 'consts/router_path.dart';
import 'consts/theme_style.dart';
import 'data/db.dart';
import 'generated/l10n.dart';
import 'home_widget.dart';
import 'provider/badge_provider.dart';
import 'provider/community_approved_provider.dart';
import 'provider/contact_list_provider.dart';
import 'provider/data_util.dart';
import 'provider/dm_provider.dart';
import 'provider/event_reactions_provider.dart';
import 'provider/filter_provider.dart';
import 'provider/follow_event_provider.dart';
import 'provider/index_provider.dart';
import 'provider/link_preview_data_provider.dart';
import 'provider/list_provider.dart';
import 'provider/list_set_provider.dart';
import 'provider/mention_me_provider.dart';
import 'provider/metadata_provider.dart';
import 'provider/music_info_cache.dart';
import 'provider/pc_router_fake_provider.dart';
import 'provider/relay_provider.dart';
import 'provider/notice_provider.dart';
import 'provider/replaceable_event_provider.dart';
import 'provider/setting_provider.dart';
import 'provider/single_event_provider.dart';
import 'provider/url_speed_provider.dart';
import 'provider/webview_provider.dart';
import 'provider/wot_provider.dart';
import 'router/bookmark/bookmark_widget.dart';
import 'router/community/community_detail_widget.dart';
import 'router/dm/dm_detail_widget.dart';
import 'router/donate/donate_widget.dart';
import 'router/event_detail/event_detail_widget.dart';
import 'router/filter/filter_widget.dart';
import 'router/follow_set/follow_set_detail_widget.dart';
import 'router/nwc/nwc_setting_widget.dart';
import 'router/profile_editor/profile_editor_widget.dart';
import 'router/index/index_widget.dart';
import 'router/keybackup/key_backup_widget.dart';
import 'router/notice/notice_widget.dart';
import 'router/qrscanner/qrscanner_widget.dart';
import 'router/relays/relays_widget.dart';
import 'router/setting/setting_widget.dart';
import 'router/tag/tag_detail_widget.dart';
import 'router/thread/thread_detail_widget.dart';
import 'router/user/followed_communities_widget.dart';
import 'router/user/user_contact_list_widget.dart';
import 'router/user/user_relays_widget.dart';
import 'router/user/user_widget.dart';
import 'system_timer.dart';
import 'util/colors_util.dart';
import 'util/image/cache_manager_builder.dart';
import 'util/locale_util.dart';
import 'util/media_data_cache.dart';

late SharedPreferences sharedPreferences;

late SettingProvider settingProvider;

late MetadataProvider metadataProvider;

late ContactListProvider contactListProvider;

late FollowEventProvider followEventProvider;

late FollowNewEventProvider followNewEventProvider;

late MentionMeProvider mentionMeProvider;

late MentionMeNewProvider mentionMeNewProvider;

late DMProvider dmProvider;

late IndexProvider indexProvider;

late EventReactionsProvider eventReactionsProvider;

late NoticeProvider noticeProvider;

late SingleEventProvider singleEventProvider;

late RelayProvider relayProvider;

late FilterProvider filterProvider;

late LinkPreviewDataProvider linkPreviewDataProvider;

late BadgeDefinitionProvider badgeDefinitionProvider;

late MediaDataCache mediaDataCache;

late CacheStore imageCacheStore;

late CacheManager imageLocalCacheManager;

late PcRouterFakeProvider pcRouterFakeProvider;

late Map<String, WidgetBuilder> routes;

late WebViewProvider webViewProvider;

// late CustomEmojiProvider customEmojiProvider;

late CommunityApprovedProvider communityApprovedProvider;

late CommunityInfoProvider communityInfoProvider;

late CommunityListProvider communityListProvider;

late ReplaceableEventProvider replaceableEventProvider;

late ListProvider listProvider;

late ListSetProvider listSetProvider;

late BadgeProvider badgeProvider;

late GiftWrapProvider giftWrapProvider;

late MusicProvider musicProvider;

late UrlSpeedProvider urlSpeedProvider;

late NWCProvider nwcProvider;

late GroupProvider groupProvider;

MusicInfoCache musicInfoCache = MusicInfoCache();

RelayLocalDB? relayLocalDB;

Nostr? nostr;

bool dataSyncMode = false;

bool firstLogin = false;

// this user is new, should add follow suggest.
bool newUser = false;

late TrieTextMatcher defaultTrieTextMatcher;

late WotProvider wotProvider;

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  try {
    MediaKit.ensureInitialized();
  } catch (e) {
    log("MediaKit init error $e");
  }

  if (!PlatformUtil.isWeb() && PlatformUtil.isPC()) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: Base.APP_NAME,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  if (PlatformUtil.isWeb()) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (PlatformUtil.isWindowsOrLinux()) {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory
    databaseFactory = databaseFactoryFfi;
  }

  try {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
  } catch (e) {
    print(e);
  }

  var dbInitTask = DB.getCurrentDatabase();
  var dataUtilTask = DataUtil.getInstance();
  var relayLocalDBTask = RelayLocalDB.init();
  var dataFutureResultList =
      await Future.wait([dbInitTask, dataUtilTask, relayLocalDBTask]);
  relayLocalDB = dataFutureResultList[2] as RelayLocalDB?;
  sharedPreferences = dataFutureResultList[1] as SharedPreferences;

  var settingTask = SettingProvider.getInstance();
  var metadataTask = MetadataProvider.getInstance();
  var futureResultList = await Future.wait([settingTask, metadataTask]);
  settingProvider = futureResultList[0] as SettingProvider;
  metadataProvider = futureResultList[1] as MetadataProvider;
  contactListProvider = ContactListProvider.getInstance();
  followEventProvider = FollowEventProvider();
  followNewEventProvider = FollowNewEventProvider();
  mentionMeProvider = MentionMeProvider();
  mentionMeNewProvider = MentionMeNewProvider();
  dmProvider = DMProvider();
  indexProvider = IndexProvider(
    indexTap: settingProvider.defaultIndex,
  );
  eventReactionsProvider = EventReactionsProvider();
  noticeProvider = NoticeProvider();
  singleEventProvider = SingleEventProvider();
  relayProvider = RelayProvider.getInstance();
  filterProvider = FilterProvider.getInstance();
  linkPreviewDataProvider = LinkPreviewDataProvider();
  badgeDefinitionProvider = BadgeDefinitionProvider();
  mediaDataCache = MediaDataCache();
  CacheManagerBuilder.build();
  pcRouterFakeProvider = PcRouterFakeProvider();
  webViewProvider = WebViewProvider.getInstance();
  // customEmojiProvider = CustomEmojiProvider.load();
  communityApprovedProvider = CommunityApprovedProvider();
  communityInfoProvider = CommunityInfoProvider();
  communityListProvider = CommunityListProvider();
  replaceableEventProvider = ReplaceableEventProvider();
  listProvider = ListProvider();
  listSetProvider = ListSetProvider();
  badgeProvider = BadgeProvider();
  giftWrapProvider = GiftWrapProvider();
  musicProvider = MusicProvider();
  urlSpeedProvider = UrlSpeedProvider();
  nwcProvider = NWCProvider()..init();
  groupProvider = GroupProvider();
  wotProvider = WotProvider();

  defaultTrieTextMatcher = TrieTextMatcherBuilder.build();

  if (StringUtil.isNotBlank(settingProvider.network)) {
    var network = settingProvider.network;
    network = network!.trim();
    SocksProxy.initProxy(proxy: network);
  }

  if (StringUtil.isNotBlank(settingProvider.privateKey)) {
    nostr = await relayProvider.genNostrWithKey(settingProvider.privateKey!);

    if (nostr != null && settingProvider.wotFilter == OpenStatus.OPEN) {
      var pubkey = nostr!.publicKey;
      wotProvider.init(pubkey);
    }
  }

  FlutterNativeSplash.remove();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  static const platform = MethodChannel('com.example.app/deeplink');
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  MyApp() {
    platform.setMethodCallHandler(_handleDeepLink);
  }

  void joinGroupExample(BuildContext context, String host, String groupId) {
    final listProvider = Provider.of<ListProvider>(context, listen: false);
    final groupIdentifier = GroupIdentifier(host, groupId);
    listProvider.joinGroup(groupIdentifier);
  }

  Future<void> _handleDeepLink(MethodCall call) async {
    if (call.method == 'onDeepLink') {
      final String link = call.arguments;
      print('Received deep link: $link');

      Uri uri = Uri.parse(link);
      if (uri.scheme == 'plur' && uri.host == 'join-community') {
        String? groupId = uri.queryParameters['group-id'];
        String? code = uri.queryParameters['code'];
        // Handle the extracted parameters
        print('Group ID: $groupId');
        print('Code: $code');

        if (groupId == null || groupId.isEmpty) {
          print('Group ID is null or empty, aborting.');
          return;
        }

        final context = navigatorKey.currentContext;
        if (context != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            joinGroupExample(context, 'wss://relay.groups.nip29.com', groupId);
          });
        } else {
          print('Context is null, waiting for app to initialize...');
        }
      }
    }
  }

  @override
  State<StatefulWidget> createState() => _MyApp();
}

class _MyApp extends State<MyApp> {
  reload() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Locale? _locale;
    if (StringUtil.isNotBlank(settingProvider.i18n)) {
      for (var item in S.delegate.supportedLocales) {
        if (item.languageCode == settingProvider.i18n &&
            item.countryCode == settingProvider.i18nCC) {
          _locale = Locale(settingProvider.i18n!, settingProvider.i18nCC);
          break;
        }
      }
    }
    setGetTimeAgoDefaultLocale(_locale);

    var lightTheme = getLightTheme();
    var darkTheme = getDarkTheme();
    ThemeData defaultTheme;
    ThemeData? defaultDarkTheme;
    if (settingProvider.themeStyle == ThemeStyle.LIGHT) {
      defaultTheme = lightTheme;
    } else if (settingProvider.themeStyle == ThemeStyle.DARK) {
      defaultTheme = darkTheme;
    } else {
      defaultTheme = lightTheme;
      defaultDarkTheme = darkTheme;
    }

    routes = {
      RouterPath.INDEX: (context) => IndexWidget(reload: reload),
      RouterPath.LOGIN: (context) => LoginSignupWidget(),
      RouterPath.DONATE: (context) => const DonateWidget(),
      RouterPath.USER: (context) => const UserWidget(),
      RouterPath.USER_CONTACT_LIST: (context) => const UserContactListWidget(),
      RouterPath.USER_HISTORY_CONTACT_LIST: (context) =>
          const UserHistoryContactListWidget(),
      RouterPath.USER_ZAP_LIST: (context) => const UserZapListWidget(),
      RouterPath.USER_RELAYS: (context) => const UserRelayWidget(),
      RouterPath.DM_DETAIL: (context) => const DMDetailWidget(),
      RouterPath.THREAD_DETAIL: (context) => ThreadDetailWidget(),
      RouterPath.THREAD_TRACE: (context) => const ThreadTraceWidget(),
      RouterPath.EVENT_DETAIL: (context) => const EventDetailWidget(),
      RouterPath.TAG_DETAIL: (context) => const TagDetailWidget(),
      RouterPath.NOTICES: (context) => const NoticeWidget(),
      RouterPath.KEY_BACKUP: (context) => const KeyBackupWidget(),
      RouterPath.RELAYHUB: (context) => const RelayhubWidget(),
      RouterPath.RELAYS: (context) => const RelaysWidget(),
      RouterPath.FILTER: (context) => const FilterWidget(),
      RouterPath.PROFILE_EDITOR: (context) => const ProfileEditorWidget(),
      RouterPath.SETTING: (context) => SettingWidget(indexReload: reload),
      RouterPath.QRSCANNER: (context) => const QRScannerWidget(),
      RouterPath.WEBUTILS: (context) => const WebUtilsWidget(),
      RouterPath.RELAY_INFO: (context) => const RelayInfoWidget(),
      RouterPath.FOLLOWED_TAGS_LIST: (context) =>
          const FollowedTagsListWidget(),
      RouterPath.COMMUNITY_DETAIL: (context) => const CommunityDetailWidget(),
      RouterPath.FOLLOWED_COMMUNITIES: (context) =>
          const FollowedCommunitiesWidget(),
      RouterPath.FOLLOWED: (context) => const FollowedWidget(),
      RouterPath.BOOKMARK: (context) => const BookmarkWidget(),
      RouterPath.FOLLOW_SET_LIST: (context) => const FollowSetListWidget(),
      RouterPath.FOLLOW_SET_DETAIL: (context) => const FollowSetDetailWidget(),
      RouterPath.FOLLOW_SET_FEED: (context) => const FollowSetFeedWidget(),
      RouterPath.NWC_SETTING: (context) => const NwcSettingWidget(),
      RouterPath.GROUP_LIST: (context) => const CommunitiesWidget(),
      RouterPath.GROUP_DETAIL: (context) => const GroupDetailWidget(),
      RouterPath.GROUP_EDIT: (context) => const GroupEditWidget(),
      RouterPath.GROUP_MEMBERS: (context) => const GroupMembersWidget(),
    };

    return MultiProvider(
      providers: [
        ListenableProvider<SettingProvider>.value(
          value: settingProvider,
        ),
        ListenableProvider<MetadataProvider>.value(
          value: metadataProvider,
        ),
        ListenableProvider<IndexProvider>.value(
          value: indexProvider,
        ),
        ListenableProvider<ContactListProvider>.value(
          value: contactListProvider,
        ),
        ListenableProvider<FollowEventProvider>.value(
          value: followEventProvider,
        ),
        ListenableProvider<FollowNewEventProvider>.value(
          value: followNewEventProvider,
        ),
        ListenableProvider<MentionMeProvider>.value(
          value: mentionMeProvider,
        ),
        ListenableProvider<MentionMeNewProvider>.value(
          value: mentionMeNewProvider,
        ),
        ListenableProvider<DMProvider>.value(
          value: dmProvider,
        ),
        ListenableProvider<EventReactionsProvider>.value(
          value: eventReactionsProvider,
        ),
        ListenableProvider<NoticeProvider>.value(
          value: noticeProvider,
        ),
        ListenableProvider<SingleEventProvider>.value(
          value: singleEventProvider,
        ),
        ListenableProvider<RelayProvider>.value(
          value: relayProvider,
        ),
        ListenableProvider<FilterProvider>.value(
          value: filterProvider,
        ),
        ListenableProvider<LinkPreviewDataProvider>.value(
          value: linkPreviewDataProvider,
        ),
        ListenableProvider<BadgeDefinitionProvider>.value(
          value: badgeDefinitionProvider,
        ),
        ListenableProvider<PcRouterFakeProvider>.value(
          value: pcRouterFakeProvider,
        ),
        ListenableProvider<WebViewProvider>.value(
          value: webViewProvider,
        ),
        ListenableProvider<CommunityApprovedProvider>.value(
          value: communityApprovedProvider,
        ),
        ListenableProvider<CommunityInfoProvider>.value(
          value: communityInfoProvider,
        ),
        ListenableProvider<CommunityListProvider>.value(
          value: communityListProvider,
        ),
        ListenableProvider<ReplaceableEventProvider>.value(
          value: replaceableEventProvider,
        ),
        ListenableProvider<ListProvider>.value(
          value: listProvider,
        ),
        ListenableProvider<ListSetProvider>.value(
          value: listSetProvider,
        ),
        ListenableProvider<BadgeProvider>.value(
          value: badgeProvider,
        ),
        ListenableProvider<MusicProvider>.value(
          value: musicProvider,
        ),
        ListenableProvider<UrlSpeedProvider>.value(
          value: urlSpeedProvider,
        ),
        ListenableProvider<GroupProvider>.value(
          value: groupProvider,
        ),
      ],
      child: HomeWidget(
        locale: _locale,
        theme: defaultTheme,
        child: MaterialApp(
          navigatorKey: MyApp.navigatorKey,
          builder: BotToastInit(),
          navigatorObservers: [
            BotToastNavigatorObserver(),
            webViewProvider.webviewNavigatorObserver,
          ],
          // showPerformanceOverlay: true,
          debugShowCheckedModeBanner: false,
          locale: _locale,
          title: Base.APP_NAME,
          localizationsDelegates: const [
            S.delegate,
            FlutterQuillLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          theme: defaultTheme,
          darkTheme: defaultDarkTheme,
          initialRoute: RouterPath.INDEX,
          routes: routes,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    SystemTimer.run();
  }

  @override
  void dispose() {
    super.dispose();
    SystemTimer.stopTask();
  }

  ThemeData getLightTheme() {
    Color color500 = _getMainColor();
    MaterialColor themeColor = ColorList.getThemeColor(color500.value);

    Color mainTextColor = Colors.black;
    Color hintColor = Colors.grey;
    var scaffoldBackgroundColor = Colors.grey[100];
    Color cardColor = Colors.white;

    if (settingProvider.mainFontColor != null) {
      mainTextColor = Color(settingProvider.mainFontColor!);
    }
    if (settingProvider.hintFontColor != null) {
      hintColor = Color(settingProvider.hintFontColor!);
    }
    if (settingProvider.cardColor != null) {
      cardColor = Color(settingProvider.cardColor!);
    }

    double baseFontSize = settingProvider.fontSize;

    var textTheme = TextTheme(
      bodyLarge: TextStyle(fontSize: baseFontSize + 2, color: mainTextColor),
      bodyMedium: TextStyle(fontSize: baseFontSize, color: mainTextColor),
      bodySmall: TextStyle(fontSize: baseFontSize - 2, color: mainTextColor),
    );
    var titleTextStyle = TextStyle(
      color: mainTextColor,
    );

    if (settingProvider.fontFamily != null) {
      textTheme =
          GoogleFonts.getTextTheme(settingProvider.fontFamily!, textTheme);
      titleTextStyle = GoogleFonts.getFont(settingProvider.fontFamily!,
          textStyle: titleTextStyle);
    }

    if (StringUtil.isNotBlank(settingProvider.backgroundImage)) {
      scaffoldBackgroundColor = Colors.transparent;
      cardColor = cardColor.withOpacity(0.6);
    }

    return ThemeData(
      platform: TargetPlatform.iOS,
      primarySwatch: themeColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: themeColor[500]!,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      primaryColor: themeColor[500],
      appBarTheme: AppBarTheme(
        backgroundColor: cardColor,
        titleTextStyle: titleTextStyle,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerColor: ColorsUtil.hexToColor("#DFE1EB"),
      cardColor: cardColor,
      textTheme: textTheme,
      hintColor: hintColor,
      buttonTheme: const ButtonThemeData(),
      shadowColor: Colors.black.withOpacity(0.2),
      tabBarTheme: TabBarTheme(
        indicatorColor: Colors.white,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerHeight: 0,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[200],
      ),
    );
  }

  ThemeData getDarkTheme() {
    Color color500 = _getMainColor();
    MaterialColor themeColor = ColorList.getThemeColor(color500.value);

    Color? mainTextColor;
    Color? topFontColor = Colors.grey[200];
    Color hintColor = Colors.grey;
    var scaffoldBackgroundColor = const Color.fromARGB(255, 40, 40, 40);
    Color cardColor = Colors.black;

    if (settingProvider.mainFontColor != null) {
      mainTextColor = Color(settingProvider.mainFontColor!);
    }
    if (settingProvider.hintFontColor != null) {
      hintColor = Color(settingProvider.hintFontColor!);
    }
    if (settingProvider.cardColor != null) {
      cardColor = Color(settingProvider.cardColor!);
    }

    double baseFontSize = settingProvider.fontSize;

    var textTheme = TextTheme(
      bodyLarge: TextStyle(fontSize: baseFontSize + 2, color: mainTextColor),
      bodyMedium: TextStyle(fontSize: baseFontSize, color: mainTextColor),
      bodySmall: TextStyle(fontSize: baseFontSize - 2, color: mainTextColor),
    );
    var titleTextStyle = TextStyle(
      color: topFontColor,
    );

    if (settingProvider.fontFamily != null) {
      textTheme =
          GoogleFonts.getTextTheme(settingProvider.fontFamily!, textTheme);
      titleTextStyle = GoogleFonts.getFont(settingProvider.fontFamily!,
          textStyle: titleTextStyle);
    }

    if (StringUtil.isNotBlank(settingProvider.backgroundImage)) {
      scaffoldBackgroundColor = Colors.transparent;
      cardColor = cardColor.withOpacity(0.6);
    }

    return ThemeData(
      platform: TargetPlatform.iOS,
      primarySwatch: themeColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: themeColor[500]!,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      primaryColor: themeColor[500],
      appBarTheme: AppBarTheme(
        backgroundColor: cardColor,
        titleTextStyle: titleTextStyle,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerColor: Colors.grey[200],
      cardColor: cardColor,
      textTheme: textTheme,
      hintColor: hintColor,
      shadowColor: Colors.white.withOpacity(0.3),
      tabBarTheme: TabBarTheme(
        indicatorColor: Colors.white,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerHeight: 0,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[200],
      ),
    );
  }

  void setGetTimeAgoDefaultLocale(Locale? locale) {
    String? localeName = Intl.defaultLocale;
    if (locale != null) {
      localeName = LocaleUtil.getLocaleKey(locale);
    }

    if (StringUtil.isNotBlank(localeName)) {
      if (GetTimeAgoSupportLocale.containsKey(localeName)) {
        GetTimeAgo.setDefaultLocale(localeName!);
      } else if (localeName == "zh_tw") {
        GetTimeAgo.setDefaultLocale("zh_tr");
      }
    }
  }
}

Color _getMainColor() {
  Color color500 = const Color(0xff519495);
  if (settingProvider.themeColor != null) {
    color500 = Color(settingProvider.themeColor!);
  }
  return color500;
}

final Map<String, int> GetTimeAgoSupportLocale = {
  'ar': 1,
  'en': 1,
  'es': 1,
  'fr': 1,
  'hi': 1,
  'pt': 1,
  'br': 1,
  'zh': 1,
  'zh_tr': 1,
  'ja': 1,
  'oc': 1,
  'ko': 1,
  'de': 1,
  'id': 1,
  'tr': 1,
  'ur': 1,
  'vi': 1,
};
