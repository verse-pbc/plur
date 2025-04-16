import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nostr_sdk/relay/relay_info_util.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/user_provider.dart';
import 'package:nostrmo/router/login/login_widget.dart';
import 'package:nostrmo/router/group/no_communities_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sign_up_test.mocks.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nostrmo/util/firebase_options.dart';
import 'mocks/mock_firebase.dart';

@GenerateNiceMocks([MockSpec<http.Client>(), MockSpec<UserProvider>()])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setupMockFirebase();

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

    userProvider = MockUserProvider();

    await relayLocalDB?.close();
    relayLocalDB = null;
  });

  testWidgets('Sign Up flow with age verification and name input',
      (WidgetTester tester) async {
    // Launch the app
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // find the Sign Up button and tap it
    await tester.tap(find.byKey(const Key('signup_button')));
    await tester.pumpAndSettle();

    // Verify we're on the age verification step
    expect(find.byKey(const Key('age_verification_title')), findsOneWidget);

    // Accept age verification
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    // Verify we're on the name input step
    expect(find.byKey(const Key('name_input_title')), findsOneWidget);

    // Enter the name
    await tester.enterText(find.byKey(const Key('input')), 'Test User');
    await tester.pumpAndSettle();

    // Tap the continue button
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // verify that the NoCommunitiesWidget is shown
    expect(find.byType(NoCommunitiesWidget), findsOneWidget);
  });

  testWidgets('Age verification denial shows dialog and returns to login',
      (WidgetTester tester) async {
    // Launch the app and ensure nostr is null to show login screen
    nostr = null;
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // find the Sign Up button and tap it
    await tester.tap(find.byKey(const Key('signup_button')));
    await tester.pumpAndSettle();

    // Verify we're on the age verification step
    expect(find.byKey(const Key('age_verification_title')), findsOneWidget);

    // Deny age verification
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();

    // Verify the dialog appears
    expect(find.byKey(const Key('age_dialog_title')), findsOneWidget);
    expect(
      find.byKey(const Key('age_requirement_message')),
      findsOneWidget,
    );

    // Tap OK on the dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Verify we're back at login screen
    expect(find.byType(LoginSignupWidget), findsOneWidget);
  });
}
