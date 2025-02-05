import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nostr_sdk/relay/relay_info_util.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
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
    when(httpClient.get(any, headers: anyNamed('headers'))).thenAnswer((invocation) async {
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
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    // find the Login button and tap it
    await tester.tap(find.text('Login'));

    // wait for the navigation animation to complete
    await tester.pumpAndSettle();

    // verify that the NoCommunitiesWidget is shown
    expect(find.byType(NoCommunitiesWidget), findsOneWidget);
  });
}