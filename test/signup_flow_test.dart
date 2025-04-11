import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostr_sdk/relay/relay_info_util.dart';
import 'package:nostrmo/consts/index_taps.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/provider/index_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
import 'package:nostrmo/router/follow/follow_posts_widget.dart';
import 'package:nostrmo/router/group/communities_feed_widget.dart';
import 'package:nostrmo/router/group/communities_widget.dart';
import 'package:nostrmo/router/login/login_widget.dart';
import 'package:nostrmo/router/signup/signup_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

@GenerateMocks([
  http.Client, 
  MetadataProvider, 
  ListProvider, 
  GroupProvider, 
  IndexProvider
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late MockListProvider mockListProvider;
  late MockGroupProvider mockGroupProvider;
  late MockIndexProvider mockIndexProvider;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final httpClient = MockClient();
    when(httpClient.get(any, headers: anyNamed('headers')))
        .thenAnswer((invocation) async {
      const String json = '''
        {
          "name": "Nostr Groups Relay",
          "description": "A specialized relay implementing NIP-29 for Nostr group management",
          "pubkey": null,
          "contact": null,
          "supported_nips": [
            1,
            11,
            29,
            42
          ],
          "software": "groups_relay",
          "version": "0.1.0",
          "limitation": null,
          "posting_policy": null,
          "payments_url": null,
          "fees": null,
          "icon": null
        }
      ''';

      return http.Response(json, 200, headers: {
        'Content-Type': 'application/json',
      });
    });
    
    RelayInfoUtil.client = httpClient;

    await initializeProviders(isTesting: true);

    // Set up mocks
    mockListProvider = MockListProvider();
    mockGroupProvider = MockGroupProvider();
    mockIndexProvider = MockIndexProvider();
    
    // Mock group membership data
    final groupIds = [
      GroupIdentifier('wss://relay.test.com', 'group123'),
      GroupIdentifier('wss://relay.test.com', 'group456'),
    ];
    when(mockListProvider.groupIdentifiers).thenReturn(groupIds);
    
    // Replace the global providers with mocks
    listProvider = mockListProvider;
    groupProvider = mockGroupProvider;
    indexProvider = mockIndexProvider;
    
    await relayLocalDB?.close();
    relayLocalDB = null;
  });

  testWidgets('Verify signup flow navigates to timeline and shows correct tab', 
      (WidgetTester tester) async {
    // Build the login widget
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        S.delegate
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: const Locale('en'),
      routes: {
        '/': (context) => const LoginSignupWidget(),
        '/signup': (context) => const SignupWidget(),
      },
    ));
    await tester.pumpAndSettle();

    // Find and tap the Signup button
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    // Verify we're on the signup page
    expect(find.byType(SignupWidget), findsOneWidget);

    // Find and tap the checkbox to accept terms
    await tester.tap(find.byKey(const Key('acknowledgement_checkbox')));
    await tester.pumpAndSettle();

    // Verify the Copy & Continue button is enabled
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('done_button'))).enabled,
      isTrue,
    );

    // Capture the SetCurrentTap calls to the IndexProvider
    verify(mockIndexProvider.setCurrentTap(IndexTaps.FOLLOW)).called(0);

    // Tap the Copy & Continue button
    await tester.tap(find.byKey(const Key('done_button')));
    await tester.pumpAndSettle();

    // Verify IndexProvider was told to go to the FOLLOW tab
    verify(mockIndexProvider.setCurrentTap(IndexTaps.FOLLOW)).called(1);
    
    // When we start the app for real, verify we see the right screens
    // and can access the Community Feed and Communities tabs
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    
    // Verify we can see the timeline widget
    expect(find.byType(FollowPostsWidget), findsOneWidget);
    
    // Simulate navigating to the Community Feed tab
    when(mockIndexProvider.currentTap).thenReturn(IndexTaps.COMMUNITY_FEED);
    await tester.pump();
    await tester.pumpAndSettle();
    
    // Verify the Communities Feed tab is accessible
    expect(find.byType(CommunitiesFeedWidget), findsOneWidget);
    
    // Simulate navigating to the Communities tab
    when(mockIndexProvider.currentTap).thenReturn(IndexTaps.COMMUNITIES);
    await tester.pump();
    await tester.pumpAndSettle();
    
    // Verify the Communities tab is accessible
    expect(find.byType(CommunitiesWidget), findsOneWidget);
  });
}