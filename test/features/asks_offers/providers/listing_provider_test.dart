import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/features/asks_offers/models/listing_model.dart';
import 'package:nostrmo/features/asks_offers/providers/listing_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Create mock annotations
@GenerateMocks([Nostr])
import 'listing_provider_test.mocks.dart';

void main() {
  group('ListingProvider', () {
    late MockNostr mockNostr;
    late ListingNotifier listingNotifier;
    late ProviderContainer container;

    // Sample test data
    // Using a valid hex string for the pubkey (64 hex chars)
    const testPubkey = '13852255dc6788860e1b5cbc77be690eb8720fdaf169f94e4196213572982aa1';
    const testId = '4f1448b1b2f0812702a97b2fc68311d151f1e4c6e7866acb70c6ca890013a20e';
    final testCreatedAt = DateTime.now();
    final testCreatedAtSeconds = testCreatedAt.millisecondsSinceEpoch ~/ 1000;
    
    // Sample listing data
    final offerListing = ListingModel(
      id: 'offer_id',
      pubkey: testPubkey,
      d: 'offer_d',
      type: ListingType.offer,
      title: 'Test Offer',
      content: 'This is a test offer',
      status: ListingStatus.active,
      createdAt: testCreatedAt,
    );
    
    final askListing = ListingModel(
      id: 'ask_id',
      pubkey: testPubkey,
      d: 'ask_d',
      type: ListingType.ask,
      title: 'Test Ask',
      content: 'This is a test ask',
      status: ListingStatus.active,
      createdAt: testCreatedAt,
    );

    // Create mock events
    Event createMockEvent({
      required String id,
      required String d,
      required ListingType type,
      required String title,
      required ListingStatus status,
      String? groupId,
    }) {
      final tags = [
        ['d', d],
        ['type', type == ListingType.ask ? 'ask' : 'offer'],
        ['title', title],
        ['status', status.name],
      ];
      
      if (groupId != null) {
        tags.add(['h', groupId]);
      }
      
      final event = Event(
        testPubkey,
        31111,
        tags,
        'Test content for $title',
        createdAt: testCreatedAtSeconds,
      );
      
      event.id = id;
      event.sig = 'test_sig';
      
      return event;
    }

    setUp(() {
      // Initialize mocks
      mockNostr = MockNostr();
      
      // Set up default behaviors for the mock
      when(mockNostr.publicKey).thenReturn(testPubkey);
      
      // For query events
      when(mockNostr.queryEvents(any)).thenAnswer((_) async => []);
      
      // For subscribe
      when(mockNostr.subscribe(any, any, id: anyNamed('id'))).thenReturn(null);
      
      // For sign event
      when(mockNostr.signEvent(any)).thenAnswer((invocation) {
        final event = invocation.positionalArguments[0] as Event;
        event.id = testId; // Set a test ID
        event.sig = 'test_sig';
        return null;
      });
      
      // For send event
      when(mockNostr.sendEvent(any)).thenAnswer((_) async => null);
      
      // Create a provider container with mocked Nostr
      container = ProviderContainer(
        overrides: [
          // We would override the Nostr provider here in a real implementation
        ],
      );
      
      // Create ListingNotifier directly for testing
      listingNotifier = ListingNotifier(container);
      // Inject the mock Nostr into the notifier for testing
      // In a real implementation, we would use a proper DI system
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should be loading', () {
      expect(listingNotifier.debugState, isA<AsyncLoading>());
    });

    test('filterListings should filter by type', () {
      // Update the state with some test listings
      final listings = [offerListing, askListing];
      listingNotifier.debugState = AsyncData(listings);
      
      // Test filtering by type
      final offerListings = listingNotifier.filterListings(type: ListingType.offer);
      expect(offerListings.length, 1);
      expect(offerListings.first.type, ListingType.offer);
      
      final askListings = listingNotifier.filterListings(type: ListingType.ask);
      expect(askListings.length, 1);
      expect(askListings.first.type, ListingType.ask);
    });

    test('filterListings should filter by status', () {
      // Create a fulfilled listing
      final fulfilledListing = offerListing.copyWith(
        id: 'fulfilled_id',
        status: ListingStatus.fulfilled,
      );
      
      // Update the state with test listings
      final listings = [offerListing, fulfilledListing];
      listingNotifier.debugState = AsyncData(listings);
      
      // Test filtering by status
      final activeListings = listingNotifier.filterListings(status: ListingStatus.active);
      expect(activeListings.length, 1);
      expect(activeListings.first.status, ListingStatus.active);
      
      final fulfilledListings = listingNotifier.filterListings(status: ListingStatus.fulfilled);
      expect(fulfilledListings.length, 1);
      expect(fulfilledListings.first.status, ListingStatus.fulfilled);
    });

    test('filterListings should filter by groupId', () {
      // Create listings with different group IDs
      final groupListing = offerListing.copyWith(
        id: 'group_id',
        groupId: 'test_group',
      );
      
      // Update the state with test listings
      final listings = [offerListing, groupListing];
      listingNotifier.debugState = AsyncData(listings);
      
      // Test filtering by groupId
      final groupListings = listingNotifier.filterListings(groupId: 'test_group');
      expect(groupListings.length, 1);
      expect(groupListings.first.groupId, 'test_group');
      
      // Test filtering for public listings (no groupId)
      final publicListings = listingNotifier.filterListings();
      expect(publicListings.length, 1);
      expect(publicListings.first.groupId, isNull);
    });

    test('filterListings should filter by search query', () {
      // Create listings with different titles
      final specialListing = offerListing.copyWith(
        id: 'special_id',
        title: 'Special Offer',
      );
      
      // Update the state with test listings
      final listings = [offerListing, specialListing];
      listingNotifier.debugState = AsyncData(listings);
      
      // Test filtering by search query
      final searchResults = listingNotifier.filterListings(searchQuery: 'Special');
      expect(searchResults.length, 1);
      expect(searchResults.first.title, contains('Special'));
    });

    test('handleEvent should process events of kind 31111', () {
      // Create a mock event
      final mockEvent = createMockEvent(
        id: 'event_id',
        d: 'event_d',
        type: ListingType.offer,
        title: 'Event Offer',
        status: ListingStatus.active,
      );
      
      // Initially empty state
      listingNotifier.debugState = const AsyncData([]);
      
      // Process the event
      listingNotifier.handleEvent(mockEvent);
      
      // Verify the event was added to the state
      final state = listingNotifier.debugState as AsyncData;
      final listings = state.value as List<ListingModel>;
      expect(listings.length, 1);
      expect(listings.first.id, 'event_id');
      expect(listings.first.title, 'Event Offer');
    });

    test('handleEvent should not process events of other kinds', () {
      // Create a mock event with a different kind
      final tags = [['d', 'other_d']];
      final otherEvent = Event(
        testPubkey,
        1, // Different kind
        tags,
        'Other content',
        createdAt: testCreatedAtSeconds,
      );
      
      otherEvent.id = 'other_id';
      otherEvent.sig = 'test_sig';
      
      // Initially empty state
      listingNotifier.debugState = const AsyncData([]);
      
      // Process the event
      listingNotifier.handleEvent(otherEvent);
      
      // Verify the state remains empty
      final state = listingNotifier.debugState as AsyncData;
      final listings = state.value as List<ListingModel>;
      expect(listings.isEmpty, true);
    });

    test('_updateListing should only update if newer version', () {
      // Create an old listing
      final oldListing = offerListing.copyWith(
        createdAt: testCreatedAt.subtract(const Duration(days: 1)),
      );
      
      // Create a newer listing with the same pubkey and d
      final newListing = offerListing.copyWith(
        title: 'Updated Title',
        createdAt: testCreatedAt,
      );
      
      // Initially add the old listing
      listingNotifier.debugState = AsyncData([oldListing]);
      
      // Update with the newer listing
      listingNotifier.handleEvent(newListing.toEvent());
      
      // Verify the listing was updated
      final state = listingNotifier.debugState as AsyncData;
      final listings = state.value as List<ListingModel>;
      expect(listings.length, 1);
      expect(listings.first.title, 'Updated Title');
    });

    test('_updateListing should not update if older version', () {
      // Create a newer listing
      final newListing = offerListing.copyWith(
        title: 'Newer Title',
        createdAt: testCreatedAt,
      );
      
      // Create an older listing with the same pubkey and d
      final oldListing = offerListing.copyWith(
        title: 'Older Title',
        createdAt: testCreatedAt.subtract(const Duration(days: 1)),
      );
      
      // Initially add the newer listing
      listingNotifier.debugState = AsyncData([newListing]);
      
      // Try to update with the older listing
      listingNotifier.handleEvent(oldListing.toEvent());
      
      // Verify the listing was not updated
      final state = listingNotifier.debugState as AsyncData;
      final listings = state.value as List<ListingModel>;
      expect(listings.length, 1);
      expect(listings.first.title, 'Newer Title');
    });

    // Test creation and update operations with mocked Nostr
    group('Operation tests', () {
      setUp(() {
        // Reset to a known state before each test
        listingNotifier.debugState = const AsyncData([]);
      });

      test('createListing should sign and send a new event', () async {
        // We need to update the internal nostr reference
        // This is a bit hacky for tests, in a real implementation we'd use proper DI
        // nostr = mockNostr; // Inject mock
        
        // Mock behaviors
        // Expect signEvent to be called
        when(mockNostr.signEvent(any)).thenAnswer((invocation) {
          final event = invocation.positionalArguments[0] as Event;
          event.id = 'new_id'; // Set a test ID for the new event
          event.sig = 'new_sig';
          return null;
        });
        
        // Now call createListing
        await listingNotifier.createListing(
          type: ListingType.offer,
          title: 'New Listing',
          content: 'New content',
        );
        
        // Verify signEvent and sendEvent were called
        verify(mockNostr.signEvent(any)).called(1);
        verify(mockNostr.sendEvent(any)).called(1);
      });

      test('updateListing should update an existing listing', () async {
        // Add a listing to update
        final listingToUpdate = offerListing.copyWith(
          id: 'update_id',
          title: 'Original Title',
        );
        
        listingNotifier.debugState = AsyncData([listingToUpdate]);
        
        // Mock behaviors
        when(mockNostr.signEvent(any)).thenAnswer((invocation) {
          final event = invocation.positionalArguments[0] as Event;
          // Keep the same ID for update
          event.id = 'update_id';
          event.sig = 'updated_sig';
          return null;
        });
        
        // Now call updateListing with modified listing
        final updatedListing = listingToUpdate.copyWith(
          title: 'Updated Title',
          status: ListingStatus.fulfilled,
        );
        
        await listingNotifier.updateListing(updatedListing);
        
        // Verify methods were called
        verify(mockNostr.signEvent(any)).called(1);
        verify(mockNostr.sendEvent(any)).called(1);
        
        // Verify state was updated
        final state = listingNotifier.debugState as AsyncData;
        final listings = state.value as List<ListingModel>;
        expect(listings.length, 1);
        expect(listings.first.title, 'Updated Title');
        expect(listings.first.status, ListingStatus.fulfilled);
      });
    });
  });
}