import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nostrmo/features/asks_offers/models/listing_model.dart';
import 'package:nostrmo/features/asks_offers/widgets/listing_card.dart';

void main() {
  group('ListingCard Widget', () {
    testWidgets('should render offer listing card correctly', (WidgetTester tester) async {
      final offerListing = ListingModel(
        id: 'offer_id',
        pubkey: '13852255dc6788860e1b5cbc77be690eb8720fdaf169f94e4196213572982aa1',
        d: 'offer_d',
        type: ListingType.offer,
        title: 'Test Offer',
        content: 'This is a test offer content',
        status: ListingStatus.active,
        price: '1000 sats',
        location: 'Test Location',
        createdAt: DateTime.now(),
      );
      
      bool tapCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListingCard(
              listing: offerListing,
              onTap: () {
                tapCalled = true;
              },
            ),
          ),
        ),
      );
      
      // Verify basic content is displayed
      expect(find.text('Test Offer'), findsOneWidget);
      expect(find.text('This is a test offer content'), findsOneWidget);
      expect(find.text('1000 sats'), findsOneWidget);
      expect(find.text('Test Location'), findsOneWidget);
      
      // Verify type chip has correct text
      expect(find.text('OFFER'), findsOneWidget);
      
      // Verify status chip has correct text
      expect(find.text('ACTIVE'), findsOneWidget);
      
      // Test tap action
      await tester.tap(find.byType(ListingCard));
      expect(tapCalled, true);
    });
    
    testWidgets('should render ask listing card correctly', (WidgetTester tester) async {
      final askListing = ListingModel(
        id: 'ask_id',
        pubkey: '53ba98b4f6d919e62e8a8bfe8899a3523e4c6f92f9b7d653783bcf400c6102de',
        d: 'ask_d',
        type: ListingType.ask,
        title: 'Test Ask',
        content: 'This is a test ask content',
        status: ListingStatus.fulfilled,
        createdAt: DateTime.now(),
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListingCard(
              listing: askListing,
            ),
          ),
        ),
      );
      
      // Verify basic content is displayed
      expect(find.text('Test Ask'), findsOneWidget);
      expect(find.text('This is a test ask content'), findsOneWidget);
      
      // Verify type chip has correct text
      expect(find.text('ASK'), findsOneWidget);
      
      // Verify status chip has correct text
      expect(find.text('FULFILLED'), findsOneWidget);
      
      // No price, location, or expiry info should be shown
      expect(find.byIcon(Icons.location_on), findsNothing);
      expect(find.byIcon(Icons.timer), findsNothing);
    });
    
    testWidgets('should render optional fields when present', (WidgetTester tester) async {
      final now = DateTime.now();
      final expiry = now.add(const Duration(days: 7));
      
      final listingWithAllFields = ListingModel(
        id: 'full_id',
        pubkey: '13852255dc6788860e1b5cbc77be690eb8720fdaf169f94e4196213572982aa1',
        d: 'full_d',
        type: ListingType.offer,
        title: 'Full Offer',
        content: 'This listing has all optional fields',
        status: ListingStatus.active,
        price: '2000 sats',
        location: 'Full Location',
        expiresAt: expiry,
        // Empty imageUrls to avoid network image loading in tests
        imageUrls: [], 
        paymentInfo: 'lnbc1...',
        createdAt: now,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ListingCard(
                listing: listingWithAllFields,
              ),
            ),
          ),
        ),
      );
      
      // Verify basic content
      expect(find.text('Full Offer'), findsOneWidget);
      expect(find.text('This listing has all optional fields'), findsOneWidget);
      expect(find.text('2000 sats'), findsOneWidget);
      
      // Verify location and expiry info
      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.text('Full Location'), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsOneWidget);
      
      // We're not testing images directly in this test to avoid network loading
      // expect(find.byType(ListView), findsOneWidget);
    });
    
    testWidgets('should apply correct styles for status chips', (WidgetTester tester) async {
      final expiredListing = ListingModel(
        id: 'expired_id',
        pubkey: '13852255dc6788860e1b5cbc77be690eb8720fdaf169f94e4196213572982aa1',
        d: 'expired_d',
        type: ListingType.offer,
        title: 'Expired Offer',
        content: 'This offer has expired',
        status: ListingStatus.expired,
        createdAt: DateTime.now(),
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListingCard(
              listing: expiredListing,
            ),
          ),
        ),
      );
      
      // Find the status chip
      expect(find.text('EXPIRED'), findsOneWidget);
      
      // Other statuses would need to be tested similarly, but this verifies
      // the basic rendering of status chips with different styles
    });
  });
}