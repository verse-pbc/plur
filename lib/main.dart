import 'dart:developer';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_quill/translations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_socks_proxy/socks_proxy.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/cache_store.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/styled_bot_toast.dart';
import 'package:nostrmo/util/error_logger.dart';
import 'package:nostrmo/util/notification_util.dart';
import 'package:nostrmo/component/content/trie_text_matcher/trie_text_matcher_builder.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/data/join_group_parameters.dart';
import 'package:nostrmo/provider/badge_definition_provider.dart';
import 'package:nostrmo/provider/community_info_provider.dart';
import 'package:nostrmo/provider/community_list_provider.dart';
import 'package:nostrmo/provider/follow_new_event_provider.dart';
import 'package:nostrmo/provider/gift_wrap_provider.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/provider/mention_me_new_provider.dart';
import 'package:nostrmo/provider/music_provider.dart';
import 'package:nostrmo/provider/nwc_provider.dart';
import 'package:nostrmo/router/group/group_admin/group_admin_screen.dart';
import 'package:nostrmo/router/group/group_detail_widget.dart';
import 'package:nostrmo/router/group/group_edit_widget.dart';
import 'package:nostrmo/router/group/group_members/group_members_screen.dart';
import 'package:nostrmo/router/group/group_info/group_info_screen.dart';
import 'package:nostrmo/router/group/invite_people_widget.dart';
import 'package:nostrmo/router/login/login_widget.dart';
import 'package:nostrmo/router/onboarding/onboarding_screen.dart';
import 'package:nostrmo/router/settings/development/push_notification_test_widget.dart';
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
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:window_manager/window_manager.dart';

// Conditionally import Sentry only on supported platforms
// This prevents compile-time errors on iOS/macOS
import 'dart:async';
import 'sentry_import_helper.dart' if (dart.library.io) 'sentry_import_helper_stub.dart';

import 'component/content/trie_text_matcher/trie_text_matcher.dart';
import 'consts/base.dart';
import 'consts/router_path.dart';
import 'consts/theme_style.dart';
import 'data/db.dart';
import 'features/communities/communities_screen.dart';
import 'features/community_guidelines/community_guidelines_screen.dart';
import 'util/firebase_options.dart';
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
import 'provider/user_provider.dart';
import 'provider/music_info_cache.dart';
import 'provider/pc_router_fake_provider.dart';
import 'provider/relay_provider.dart';
import 'provider/notice_provider.dart';
import 'provider/replaceable_event_provider.dart';
import 'provider/settings_provider.dart';
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
import 'router/settings/settings_widget.dart';
import 'router/tag/tag_detail_widget.dart';
import 'router/thread/thread_detail_widget.dart';
import 'router/user/followed_communities_widget.dart';
import 'router/user/user_contact_list_widget.dart';
import 'router/user/user_relays_widget.dart';
import 'router/user/user_widget.dart';
import 'system_timer.dart';
import 'util/image/cache_manager_builder.dart';
import 'util/locale_util.dart';
import 'util/media_data_cache.dart';
import 'util/theme_util.dart';

late SharedPreferences sharedPreferences;

late SettingsProvider settingsProvider;

late UserProvider userProvider;

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

// Global variables - we're not creating custom getters/setters for testing
// Instead we'll directly mock these in tests
Nostr? nostr;

bool dataSyncMode = false;

bool firstLogin = false;

// this user is new, should add follow suggest.
bool newUser = false;

late TrieTextMatcher defaultTrieTextMatcher;

late WotProvider wotProvider;

Future<void> initializeProviders({bool isTesting = false}) async {
  try {
    log("Starting provider initialization");
    var dbInitTask = DB.getCurrentDatabase();
    var dataUtilTask = DataUtil.getInstance();
    var relayLocalDBTask = RelayLocalDB.init();
    log("Waiting for database initialization results...");
    var dataFutureResultList =
        await Future.wait([dbInitTask, dataUtilTask, relayLocalDBTask]);
    relayLocalDB = dataFutureResultList[2] as RelayLocalDB?;
    sharedPreferences = dataFutureResultList[1] as SharedPreferences;
    log("Database initialization completed");

  var settingTask = SettingsProvider.getInstance();
  var userTask = UserProvider.getInstance();
  var futureResultList = await Future.wait([settingTask, userTask]);
  settingsProvider = futureResultList[0] as SettingsProvider;
  userProvider = futureResultList[1] as UserProvider;
  contactListProvider = ContactListProvider.getInstance();
  followEventProvider = FollowEventProvider();
  followNewEventProvider = FollowNewEventProvider();
  mentionMeProvider = MentionMeProvider();
  mentionMeNewProvider = MentionMeNewProvider();
  dmProvider = DMProvider();
  indexProvider = IndexProvider(
    indexTap: settingsProvider.defaultIndex,
  );
  eventReactionsProvider = EventReactionsProvider();
  noticeProvider = NoticeProvider();
  singleEventProvider = SingleEventProvider();
  relayProvider = RelayProvider.getInstance();
  filterProvider = FilterProvider.getInstance();
  linkPreviewDataProvider = LinkPreviewDataProvider();
  badgeDefinitionProvider = BadgeDefinitionProvider();
  mediaDataCache = MediaDataCache();
  if (!isTesting) {
    CacheManagerBuilder.build();
  }
  pcRouterFakeProvider = PcRouterFakeProvider();
  webViewProvider = WebViewProvider.getInstance();
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
    log("Provider initialization completed");
  } catch (e, stackTrace) {
    log("Error during provider initialization: $e");
    log("Stack trace: $stackTrace");
  }
}

Future<void> main() async {
  try {
    // Initialize our comprehensive error logger
    ErrorLogger.init();
    log("Error logger initialized");
    
    log("Starting application initialization");
    WidgetsFlutterBinding.ensureInitialized();
    log("Flutter binding initialized");
    
    try {
      MediaKit.ensureInitialized();
      log("MediaKit initialized");
    } catch (e, stack) {
      ErrorLogger.logError("MediaKit initialization failed", e, stack);
    }

    // Using Google Fonts for font loading
    log("Using Google Fonts 'Nunito' throughout the app");

    log("Initializing Firebase...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    log("Firebase initialized");

    if (!PlatformUtil.isWeb() && PlatformUtil.isPC()) {
      log("Initializing window manager for desktop");
      await windowManager.ensureInitialized();

      WindowOptions windowOptions = const WindowOptions(
        size: Size(1280, 800),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
        title: Base.appName,
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
      log("Window manager initialized");
    }

    if (PlatformUtil.isWeb()) {
      log("Setting up web-specific database");
      databaseFactory = databaseFactoryFfiWeb;
    } else if (PlatformUtil.isWindowsOrLinux()) {
      log("Setting up Windows/Linux-specific database");
      // Initialize FFI
      sqfliteFfiInit();
      // Change the default factory
      databaseFactory = databaseFactoryFfi;
    }

    try {
      log("Setting system UI mode");
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
      log("System UI mode set");
    } catch (e) {
      log('Error setting system UI mode: $e');
    }

    log("Starting provider initialization...");
    await initializeProviders();
    log("Providers initialized");

    if (StringUtil.isNotBlank(settingsProvider.network)) {
      log("Initializing network proxy");
      var network = settingsProvider.network;
      network = network!.trim();
      SocksProxy.initProxy(proxy: network);
      log("Network proxy initialized");
    }

    if (StringUtil.isNotBlank(settingsProvider.privateKey)) {
      log("Generating Nostr with key");
      nostr = await relayProvider.genNostrWithKey(settingsProvider.privateKey!);
      log("Nostr initialized");

      if (nostr != null && settingsProvider.wotFilter == OpenStatus.open) {
        log("Initializing WoT provider");
        var pubkey = nostr!.publicKey;
        wotProvider.init(pubkey);
        log("WoT provider initialized");
      }
    }
  } catch (e, stackTrace) {
    log("!!!CRITICAL ERROR!!! in main initialization: $e");
    log("Stack trace: $stackTrace");
  }

  // Hides the splash and runs the app.
  void startApp() {
    try {
      log("Removing splash screen...");
      FlutterNativeSplash.remove();
      log("Splash screen removed successfully");
    } catch (e) {
      log("Error removing splash screen: $e");
    }
    
    log("Starting application...");
    runApp(
      const riverpod.ProviderScope(
        child: MyApp(),
      ),
    );
    log("Application started");
  }

  // Skip Sentry on iOS and macOS to avoid build issues
  bool skipSentry = false;
  
  try {
    // Check if we're on iOS or macOS
    if (Platform.isIOS || Platform.isMacOS) {
      skipSentry = true;
      log("Skipping Sentry initialization on iOS/macOS");
    }
  } catch (e) {
    // If Platform is not available (like on web), continue with normal flow
    log("Error checking platform: $e");
  }
  
  if (!skipSentry && const bool.hasEnvironment("SENTRY_DSN")) {
    try {
      await SentryFlutter.init(
        (options) {
          // environment can also be set with SENTRY_ENVIRONMENT in our secret .env files
          options.environment = const String.fromEnvironment('ENVIRONMENT',
              defaultValue: 'production');
        },
        appRunner: () {
          startApp();
        },
      );
    } catch (e) {
      log("Error initializing Sentry: $e");
      startApp();
    }
  } else {
    startApp();
  }
}

class MyApp extends StatefulWidget {
  static const platform = MethodChannel('com.example.app/deeplink');
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyApp();
}

class _MyApp extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    SystemTimer.run();

    MyApp.platform.setMethodCallHandler(_handleDeepLink);

    NotificationUtil.setUp();
  }

  void _joinGroup(
    BuildContext context,
    String host,
    String groupId,
    String? code,
  ) {
    final listProvider = Provider.of<ListProvider>(context, listen: false);
    final groupIdentifier = JoinGroupParameters(host, groupId, code: code);
    listProvider.joinGroup(groupIdentifier, context: context);
  }

  Future<void> _handleDeepLink(MethodCall call) async {
    if (nostr == null) {
      log('nostr is null; the user is probably not logged in. aborting.',
          name: 'DeepLink');
      return;
    }

    if (call.method == 'onDeepLink') {
      final String link = call.arguments;
      log('Received deep link: $link', name: 'DeepLink');

      _processDeepLink(link);
    }
  }

  reload() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Locale? locale;
    if (StringUtil.isNotBlank(settingsProvider.i18n)) {
      for (var item in S.delegate.supportedLocales) {
        if (item.languageCode == settingsProvider.i18n &&
            item.countryCode == settingsProvider.i18nCC) {
          locale = Locale(settingsProvider.i18n!, settingsProvider.i18nCC);
          break;
        }
      }
    }
    setGetTimeAgoDefaultLocale(locale);

    var lightTheme = getLightTheme();
    var darkTheme = getDarkTheme();
    ThemeData defaultTheme;
    ThemeData? defaultDarkTheme;
    if (settingsProvider.themeStyle == ThemeStyle.light) {
      defaultTheme = lightTheme;
    } else if (settingsProvider.themeStyle == ThemeStyle.dark) {
      defaultTheme = darkTheme;
    } else {
      defaultTheme = lightTheme;
      defaultDarkTheme = darkTheme;
    }

    routes = {
      RouterPath.index: (context) => IndexWidget(reload: reload),
      RouterPath.login: (context) => const LoginSignupWidget(),
      RouterPath.onboarding: (context) => const OnboardingWidget(),
      RouterPath.donate: (context) => const DonateWidget(),
      RouterPath.user: (context) => const UserWidget(),
      RouterPath.userContactList: (context) => const UserContactListWidget(),
      RouterPath.userHistoryContactList: (context) =>
          const UserHistoryContactListWidget(),
      RouterPath.userZapList: (context) => const UserZapListWidget(),
      RouterPath.userRelays: (context) => const UserRelayWidget(),
      RouterPath.dmDetail: (context) => const DMDetailWidget(),
      RouterPath.threadDetail: (context) => const ThreadDetailWidget(),
      RouterPath.threadTrace: (context) => const ThreadTraceWidget(),
      RouterPath.eventDetail: (context) => const EventDetailWidget(),
      RouterPath.tagDetail: (context) => const TagDetailWidget(),
      RouterPath.notices: (context) => const NoticeWidget(),
      RouterPath.keyBackup: (context) => const KeyBackupWidget(),
      RouterPath.relayhub: (context) => const RelayhubWidget(),
      RouterPath.relays: (context) => const RelaysWidget(),
      RouterPath.filter: (context) => const FilterWidget(),
      RouterPath.profileEditor: (context) => const ProfileEditorWidget(),
      RouterPath.settings: (context) => SettingsWidget(indexReload: reload),
      RouterPath.qrScanner: (context) => const QRScannerWidget(),
      RouterPath.webUtils: (context) => const WebUtilsWidget(),
      RouterPath.relayInfo: (context) => const RelayInfoWidget(),
      RouterPath.followedTagsList: (context) =>
          const FollowedTagsListWidget(),
      RouterPath.communityDetail: (context) => const CommunityDetailWidget(),
      RouterPath.followedCommunities: (context) =>
          const FollowedCommunitiesWidget(),
      RouterPath.followed: (context) => const FollowedWidget(),
      RouterPath.bookmark: (context) => const BookmarkWidget(),
      RouterPath.followSetList: (context) => const FollowSetListWidget(),
      RouterPath.followSetDetail: (context) => const FollowSetDetailWidget(),
      RouterPath.followSetFeed: (context) => const FollowSetFeedWidget(),
      RouterPath.nwcSetting: (context) => const NwcSettingWidget(),
      RouterPath.groupList: (context) => const CommunitiesScreen(),
      RouterPath.groupDetail: (context) => const GroupDetailWidget(),
      RouterPath.groupEdit: (context) => const GroupEditWidget(),
      RouterPath.groupMembers: (context) => const GroupMembersWidget(),
      RouterPath.groupInfo: (context) => const GroupInfoWidget(),
      RouterPath.communityGuidelines: (context) => const CommunityGuidelinesScreen(),
      RouterPath.pushNotificationTest: (context) =>
          const PushNotificationTestWidget(),
    };

    return MultiProvider(
      providers: [
        ListenableProvider<SettingsProvider>.value(
          value: settingsProvider,
        ),
        ListenableProvider<UserProvider>.value(
          value: userProvider,
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
        locale: locale,
        theme: defaultTheme,
        child: MaterialApp(
          navigatorKey: MyApp.navigatorKey,
          builder: (context, child) {
            try {
              // Wrap in a try-catch to ensure app continues even if BotToast fails
              final botToastChild = BotToastInit()(context, child);
              
              // Clean up any existing BotToast cancel functions to prevent memory leaks
              WidgetsBinding.instance.addPostFrameCallback((_) {
                try {
                  StyledBotToast.cleanUp();
                } catch (e) {
                  debugPrint("Error cleaning up toast: $e");
                }
              });
              
              // Wrap app in global error boundary
              return ErrorBoundary(
                errorBuilder: (error, stackTrace) {
                  // Custom error view
                  return Scaffold(
                    appBar: AppBar(
                      title: const Text('Error Encountered'),
                      backgroundColor: Colors.red[700],
                    ),
                    body: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: ListView(
                        children: [
                          const Text(
                            'An unexpected error occurred',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            error.toString(),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          if (stackTrace != null)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                stackTrace.toString(),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                RouterPath.index,
                                (route) => false,
                              );
                            },
                            child: const Text('Return to Home'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: botToastChild,
              );
            } catch (e, stack) {
              // If BotToast initialization fails, continue without it
              log(
                'Error initializing BotToast: $e',
                name: 'AppBuilder',
                error: e,
                stackTrace: stack,
              );
              
              // Return the child wrapped in error boundary - ensure child is non-null
              return ErrorBoundary(
                child: child ?? const SizedBox(),
              );
            }
          },
          navigatorObservers: [
            BotToastNavigatorObserver(),
            webViewProvider.webviewNavigatorObserver,
          ],
          // showPerformanceOverlay: true,
          debugShowCheckedModeBanner: false,
          locale: locale,
          title: Base.appName,
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
          initialRoute: RouterPath.index,
          routes: routes,
          onGenerateRoute: (settings) {
            // print("Generating route for: ${settings.name} with args: ${settings.arguments}");
            switch (settings.name) {
              case RouterPath.groupAdmin:
                final groupId = settings.arguments as GroupIdentifier?;
                if (groupId == null) {
                  // print("GROUP_ADMIN: groupId is null, returning null route");
                  return null;
                }
                // print("GROUP_ADMIN: Creating route with groupId: $groupId");
                return MaterialPageRoute(
                  builder: (context) => Provider<GroupIdentifier>.value(
                    value: groupId,
                    child: const GroupAdminScreen(),
                  ),
                );
              case RouterPath.groupInfo:
                // Handle direct navigation without arguments
                if (settings.arguments == null) {
                  return MaterialPageRoute(
                    builder: (context) => const CommunitiesScreen(),
                  );
                }
                
                final groupId = settings.arguments as GroupIdentifier;
                return MaterialPageRoute(
                  builder: (context) => Provider<GroupIdentifier>.value(
                    value: groupId,
                    child: const GroupInfoWidget(),
                  ),
                );
              case RouterPath.inviteToGroup:
                if (settings.arguments == null) {
                  return MaterialPageRoute(
                    builder: (context) => const CommunitiesScreen(),
                  );
                }
                
                final inviteGroupId = settings.arguments as GroupIdentifier;
                return MaterialPageRoute(
                  builder: (context) => InvitePeopleWidget(
                    groupIdentifier: inviteGroupId,
                  ),
                );
                
              case RouterPath.groupDetail:
                if (settings.arguments == null) {
                  return MaterialPageRoute(
                    builder: (context) => const CommunitiesScreen(),
                  );
                }
                
                // Handle GroupIdentifier for this route as well
                final groupId = settings.arguments as GroupIdentifier;
                
                return null; // Let the usual route handle it
              default:
                return null;
            }
          },
          onUnknownRoute: (settings) {
            // Fallback to index page
            return MaterialPageRoute(
              builder: (context) => IndexWidget(reload: reload),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    SystemTimer.stopTask();
  }

  void _processDeepLink(String link) {
    if (nostr == null) {
      log('nostr is null; the user is probably not logged in. aborting.',
          name: 'DeepLink');
      return;
    }

    log('Processing deep link: $link', name: 'DeepLink');

    Uri uri = Uri.parse(link);
    if (uri.scheme.toLowerCase() == 'plur' && uri.host == 'join-community') {
      String? groupId = uri.queryParameters['group-id'];
      String? code = uri.queryParameters['code'];

      if (groupId == null || groupId.isEmpty) {
        log('Group ID is null or empty, aborting.', name: 'DeepLink');
        return;
      }

      final context = MyApp.navigatorKey.currentContext;
      if (context != null) {
        _joinGroup(
            context, RelayProvider.defaultGroupsRelayAddress, groupId, code);
      } else {
        log('Context still null after initialization - this is unexpected',
            name: 'DeepLink');
      }
    }
  }

  ThemeData getLightTheme() {
    const CustomColors light = CustomColors.light;
    double baseFontSize = settingsProvider.fontSize;

    var textTheme = _textTheme(
      baseFontSize: baseFontSize,
      foregroundColor: light.primaryForegroundColor,
    );
    var titleTextStyle = _titleTextStyle(
      foregroundColor: light.primaryForegroundColor,
    );

    // Apply custom font if set
    if (settingsProvider.fontFamily != null) {
      textTheme = _applyCustomFont(textTheme, titleTextStyle);
    }

    return ThemeData(
      extensions: const [light],
      scaffoldBackgroundColor: light.appBgColor,
      primaryColor: light.accentColor,
      focusColor: light.secondaryForegroundColor.withAlpha(26),
      appBarTheme: _appBarTheme(
        bgColor: light.navBgColor,
        titleTextStyle: titleTextStyle,
        foregroundColor: light.primaryForegroundColor,
      ),
      dividerColor: light.separatorColor,
      cardColor: light.cardBgColor,
      textTheme: textTheme,
      hintColor: light.secondaryForegroundColor,
      shadowColor: light.dimmedColor,
      tabBarTheme: _tabBarTheme(),
      canvasColor: light.feedBgColor,
      iconTheme: _iconTheme(light.primaryForegroundColor),
    );
  }

  ThemeData getDarkTheme() {
    const CustomColors dark = CustomColors.dark;
    double baseFontSize = settingsProvider.fontSize;

    var textTheme = _textTheme(
      baseFontSize: baseFontSize,
      foregroundColor: dark.primaryForegroundColor,
    );
    var titleTextStyle = _titleTextStyle(
      foregroundColor: dark.primaryForegroundColor,
    );

    // Apply custom font if set
    if (settingsProvider.fontFamily != null) {
      textTheme = _applyCustomFont(textTheme, titleTextStyle);
    }

    return ThemeData(
      extensions: const [CustomColors.dark],
      scaffoldBackgroundColor: dark.appBgColor,
      primaryColor: dark.accentColor,
      focusColor: dark.secondaryForegroundColor.withAlpha(26),
      appBarTheme: _appBarTheme(
        bgColor: dark.navBgColor,
        titleTextStyle: titleTextStyle,
        foregroundColor: dark.primaryForegroundColor,
      ),
      dividerColor: dark.separatorColor,
      cardColor: dark.cardBgColor,
      textTheme: textTheme,
      hintColor: dark.dimmedColor,
      shadowColor: Colors.white.withAlpha(76),
      tabBarTheme: _tabBarTheme(),
      canvasColor: dark.feedBgColor,
      iconTheme: _iconTheme(dark.primaryForegroundColor),
    );
  }

  // Theme methods
  TextTheme _textTheme({
    required double baseFontSize,
    required Color foregroundColor,
  }) =>
      TextTheme(
        bodyLarge: GoogleFonts.nunito(
          fontSize: baseFontSize + 2,
          color: foregroundColor,
        ),
        bodyMedium: GoogleFonts.nunito(
          fontSize: baseFontSize,
          color: foregroundColor,
        ),
        bodySmall: GoogleFonts.nunito(
          fontSize: baseFontSize - 2,
          color: foregroundColor,
        ),
        titleLarge: GoogleFonts.nunito(
          fontSize: baseFontSize + 4,
          fontWeight: FontWeight.bold,
          color: foregroundColor,
        ),
        titleMedium: GoogleFonts.nunito(
          fontSize: baseFontSize + 2,
          fontWeight: FontWeight.bold,
          color: foregroundColor,
        ),
        titleSmall: GoogleFonts.nunito(
          fontSize: baseFontSize,
          fontWeight: FontWeight.bold,
          color: foregroundColor,
        ),
        labelLarge: GoogleFonts.nunito(
          fontSize: baseFontSize,
          fontWeight: FontWeight.w500,
          color: foregroundColor,
        ),
        labelMedium: GoogleFonts.nunito(
          fontSize: baseFontSize - 1,
          fontWeight: FontWeight.w500,
          color: foregroundColor,
        ),
        labelSmall: GoogleFonts.nunito(
          fontSize: baseFontSize - 2,
          fontWeight: FontWeight.w500,
          color: foregroundColor,
        ),
      );
}

TextStyle _titleTextStyle({
  required Color foregroundColor,
}) =>
    GoogleFonts.nunito(
      color: foregroundColor,
      fontWeight: FontWeight.bold,
    );

TextTheme _applyCustomFont(TextTheme textTheme, TextStyle titleTextStyle) =>
    GoogleFonts.getTextTheme(settingsProvider.fontFamily!, textTheme);

AppBarTheme _appBarTheme({
  required Color bgColor,
  required TextStyle titleTextStyle,
  required Color foregroundColor,
}) =>
    AppBarTheme(
      backgroundColor: bgColor,
      titleTextStyle: titleTextStyle,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(
        color: foregroundColor,
      ),
    );

TabBarTheme _tabBarTheme() => TabBarTheme(
      indicatorColor: Colors.white,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerHeight: 0,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.grey[200],
    );

IconThemeData _iconTheme(Color color) => IconThemeData(color: color);

void setGetTimeAgoDefaultLocale(Locale? locale) {
  String? localeName = Intl.defaultLocale;
  if (locale != null) {
    localeName = LocaleUtil.getLocaleKey(locale);
  }

  if (StringUtil.isNotBlank(localeName)) {
    if (_timeAgoSupportLocale.containsKey(localeName)) {
      GetTimeAgo.setDefaultLocale(localeName!);
    } else if (localeName == "zh_tw") {
      GetTimeAgo.setDefaultLocale("zh_tr");
    }
  }
}

final Map<String, int> _timeAgoSupportLocale = {
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
