import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:nostrmo/features/asks_offers/models/listing_model.dart';
import 'package:nostrmo/features/asks_offers/providers/listing_provider.dart';
import 'package:nostrmo/features/asks_offers/screens/listings_screen.dart';
import 'package:nostrmo/features/asks_offers/widgets/listing_card.dart';

class MockListingNotifier extends StateNotifier<AsyncValue<List<ListingModel>>> 
    with Mock implements ListingNotifier {
  MockListingNotifier() : super(const AsyncLoading());
  
  final List<ListingModel> _filteredListings = [];
  
  @override
  Future<void> loadListings({String? groupId}) async {
    // Do nothing in mock
  }
  
  @override
  List<ListingModel> filterListings({
    ListingType? type, 
    ListingStatus? status,
    String? groupId,
    String? searchQuery,
  }) {
    return _filteredListings;
  }
  
  void setFilteredListings(List<ListingModel> listings) {
    _filteredListings.clear();
    _filteredListings.addAll(listings);
  }
  
  void setAsyncValue(AsyncValue<List<ListingModel>> value) {
    state = value;
  }
}

// Override the listingProvider for testing
final mockListingProvider = StateNotifierProvider<MockListingNotifier, AsyncValue<List<ListingModel>>>(
  (ref) => MockListingNotifier(),
);

void main() {
  group('ListingsScreen', () {
    late MockListingNotifier mockNotifier;
    
    // Sample listings for testing
    final testListings = [
      ListingModel(
        id: 'offer1',
        pubkey: '13852255dc6788860e1b5cbc77be690eb8720fdaf169f94e4196213572982aa1',
        d: 'd1',
        type: ListingType.offer,
        title: 'Test Offer 1',
        content: 'Test content 1',
        status: ListingStatus.active,
        createdAt: DateTime.now(),
      ),
      ListingModel(
        id: 'ask1',
        pubkey: '53ba98b4f6d919e62e8a8bfe8899a3523e4c6f92f9b7d653783bcf400c6102de',
        d: 'd2',
        type: ListingType.ask,
        title: 'Test Ask 1',
        content: 'Test content 2',
        status: ListingStatus.active,
        createdAt: DateTime.now(),
      ),
    ];
    
    setUp(() {
      mockNotifier = MockListingNotifier();
    });
    
    testWidgets('should display loading indicator when loading', (WidgetTester tester) async {
      mockNotifier.setAsyncValue(const AsyncLoading());
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listingProvider.overrideWithValue(mockNotifier),
          ],
          child: const MaterialApp(
            home: ListingsScreen(),
          ),
        ),
      );
      
      // Loading screen should show a CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
    
    testWidgets('should display error message when error occurs', (WidgetTester tester) async {
      mockNotifier.setAsyncValue(AsyncError('Test error', StackTrace.current));
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listingProvider.overrideWithValue(mockNotifier),
          ],
          child: const MaterialApp(
            home: ListingsScreen(),
          ),
        ),
      );
      
      // Error screen should show the error message
      expect(find.text('Error: Test error'), findsOneWidget);
    });
    
    testWidgets('should display listings when data is available', (WidgetTester tester) async {
      // Set up mock data
      mockNotifier.setAsyncValue(AsyncData(testListings));
      mockNotifier.setFilteredListings(testListings);
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listingProvider.overrideWithValue(mockNotifier),
          ],
          child: const MaterialApp(
            home: ListingsScreen(),
          ),
        ),
      );
      
      // Should show listing cards for each listing
      expect(find.byType(ListingCard), findsNWidgets(2));
      expect(find.text('Test Offer 1'), findsOneWidget);
      expect(find.text('Test Ask 1'), findsOneWidget);
    });
    
    testWidgets('should display empty message when no listings match filters', (WidgetTester tester) async {
      // Set up mock data with empty filtered results
      mockNotifier.setAsyncValue(AsyncData(testListings));
      mockNotifier.setFilteredListings([]);
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listingProvider.overrideWithValue(mockNotifier),
          ],
          child: const MaterialApp(
            home: ListingsScreen(),
          ),
        ),
      );
      
      // Should show "No listings found" message
      expect(find.text('No listings found'), findsOneWidget);
    });
    
    testWidgets('should have filter controls', (WidgetTester tester) async {
      // Set up mock data
      mockNotifier.setAsyncValue(AsyncData(testListings));
      mockNotifier.setFilteredListings(testListings);
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listingProvider.overrideWithValue(mockNotifier),
          ],
          child: const MaterialApp(
            home: ListingsScreen(),
          ),
        ),
      );
      
      // Should have a search field
      expect(find.byType(TextField), findsOneWidget);
      
      // Should have dropdown selectors for type and status
      expect(find.byType(DropdownButton<ListingType>), findsOneWidget);
      expect(find.byType(DropdownButton<ListingStatus>), findsOneWidget);
    });
    
    testWidgets('should have add button in app bar', (WidgetTester tester) async {
      // Set up mock data
      mockNotifier.setAsyncValue(AsyncData(testListings));
      mockNotifier.setFilteredListings(testListings);
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listingProvider.overrideWithValue(mockNotifier),
          ],
          child: const MaterialApp(
            home: ListingsScreen(),
          ),
        ),
      );
      
      // Should have an add button in the app bar
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}