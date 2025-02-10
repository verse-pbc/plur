import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nostr_sdk/relay/relay_info_util.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
import 'package:nostrmo/router/signup/signup_widget.dart';
import 'package:nostrmo/router/group/no_communities_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sign_up_test.mocks.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

@GenerateNiceMocks([MockSpec<http.Client>(), MockSpec<MetadataProvider>()])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    metadataProvider = MockMetadataProvider();

    await relayLocalDB?.close();
    relayLocalDB = null;
  });

  testWidgets('Sign Up button creates account', (WidgetTester tester) async {
    // launch the app
    await tester.pumpWidget(MyApp());

    await tester.pumpAndSettle();

    // find the Sign Up button and tap it
    await tester.tap(find.byKey(const Key('signup_button')));
    await tester.pumpAndSettle();

    // find the required checkbox and turn it on
    await tester.tap(find.byKey(const Key('acknowledgement_checkbox')));
    await tester.pumpAndSettle();

    // find the Copy & Continue button and tap it
    await tester.tap(find.byKey(const Key('copy_and_continue_button')));
    await tester.pumpAndSettle();

    // verify that the NoCommunitiesWidget is shown
    expect(find.byType(NoCommunitiesWidget), findsOneWidget);
  });
  
  testWidgets('Checkbox enables button', (WidgetTester tester) async {
    // launch the app
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        S.delegate
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: SignupWidget()),
    ));
    await tester.pumpAndSettle();

    // test that the initial state of the button is disabled
    expect(tester.widget<FilledButton>(find.byKey(const Key('copy_and_continue_button'))).enabled, isFalse);
    
    // find the required checkbox and turn it on
    await tester.tap(find.byKey(const Key('acknowledgement_checkbox')));
    await tester.pumpAndSettle();

    // test that the button is now enabled
    expect(tester.widget<FilledButton>(find.byKey(const Key('copy_and_continue_button'))).enabled, isTrue);
  });
}
