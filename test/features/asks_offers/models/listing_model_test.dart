import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/features/asks_offers/models/listing_model.dart';

void main() {
  group('ListingModel', () {
    // Test data
    final now = DateTime.now();
    final nowSeconds = now.millisecondsSinceEpoch ~/ 1000;
    // Using a valid hex string for the pubkey (64 hex chars)
    const pubkey = '13852255dc6788860e1b5cbc77be690eb8720fdaf169f94e4196213572982aa1';
    const eventId = 'test_event_id';
    const dTag = 'test_d_tag';

    // Create Event using a safer approach since the Event constructor in the SDK is positional
    final mockTags = [
        ['d', dTag],
        ['type', 'offer'],
        ['title', 'Test Offer Title'],
        ['status', 'active'],
        ['h', 'group123'],
        ['expires', (nowSeconds + 86400).toString()], // Expires in 1 day
        ['location', 'Test Location'],
        ['price', '1000 sats'],
        ['image', 'http://example.com/image1.jpg'],
        ['image', 'http://example.com/image2.jpg'],
        ['payment', 'lnbc1...'],
    ];
    final mockEvent = Event(pubkey, 31111, mockTags, 'This is the test offer description.', createdAt: nowSeconds);
    // Setting ID and sig manually for test consistency
    mockEvent.id = eventId;
    mockEvent.sig = 'test_sig';


    final expectedModel = ListingModel(
      id: eventId,
      pubkey: pubkey,
      d: dTag,
      type: ListingType.offer,
      title: 'Test Offer Title',
      content: 'This is the test offer description.',
      status: ListingStatus.active,
      groupId: 'group123',
      expiresAt: DateTime.fromMillisecondsSinceEpoch((nowSeconds + 86400) * 1000),
      location: 'Test Location',
      price: '1000 sats',
      imageUrls: ['http://example.com/image1.jpg', 'http://example.com/image2.jpg'],
      paymentInfo: 'lnbc1...',
      createdAt: DateTime.fromMillisecondsSinceEpoch(nowSeconds * 1000),
    );

    test('fromEvent correctly parses a Nostr event', () {
      final model = ListingModel.fromEvent(mockEvent);
      expect(model, equals(expectedModel));
    });

    test('toEvent correctly converts a ListingModel to a Nostr event', () {
      final event = expectedModel.toEvent();

      // We need to compare fields manually as event ID and sig won't match
      expect(event.kind, equals(31111));
      expect(event.pubkey, equals(pubkey));
      // createdAt might differ by milliseconds if tests run slow, compare seconds
      expect(event.createdAt, closeTo(nowSeconds, 1)); 
      expect(event.content, equals(expectedModel.content));
      
      // Check tags (order doesn't strictly matter for Nostr, but our method is deterministic)
      expect(event.tags, containsAll([
        ['d', dTag],
        ['type', 'offer'],
        ['title', 'Test Offer Title'],
        ['status', 'active'],
        ['h', 'group123'],
        ['expires', (nowSeconds + 86400).toString()],
        ['location', 'Test Location'],
        ['price', '1000 sats'],
        ['image', 'http://example.com/image1.jpg'],
        ['image', 'http://example.com/image2.jpg'],
        ['payment', 'lnbc1...'],
      ]));
      expect(event.tags.length, 11);
    });

    test('copyWith creates a correct copy with updated fields', () {
      final updatedTime = now.add(const Duration(hours: 1));
      final updatedModel = expectedModel.copyWith(
        status: ListingStatus.fulfilled,
        createdAt: updatedTime,
        price: '2000 sats',
      );

      expect(updatedModel.id, equals(expectedModel.id));
      expect(updatedModel.pubkey, equals(expectedModel.pubkey));
      expect(updatedModel.d, equals(expectedModel.d));
      expect(updatedModel.type, equals(expectedModel.type));
      expect(updatedModel.title, equals(expectedModel.title));
      expect(updatedModel.content, equals(expectedModel.content));
      expect(updatedModel.status, equals(ListingStatus.fulfilled)); // Updated
      expect(updatedModel.groupId, equals(expectedModel.groupId));
      expect(updatedModel.expiresAt, equals(expectedModel.expiresAt));
      expect(updatedModel.location, equals(expectedModel.location));
      expect(updatedModel.price, equals('2000 sats')); // Updated
      expect(updatedModel.imageUrls, equals(expectedModel.imageUrls));
      expect(updatedModel.paymentInfo, equals(expectedModel.paymentInfo));
      expect(updatedModel.createdAt, equals(updatedTime)); // Updated
    });
    
    test('equality works correctly', () {
      final model1 = ListingModel.fromEvent(mockEvent);
      final model2 = ListingModel.fromEvent(mockEvent); // Same event data
      final model3 = expectedModel.copyWith(title: 'Different Title');

      // Check equality by comparing all properties
      expect(model1.id, equals(model2.id));
      expect(model1.pubkey, equals(model2.pubkey));
      expect(model1.d, equals(model2.d));
      expect(model1.type, equals(model2.type));
      expect(model1.title, equals(model2.title));
      expect(model1.content, equals(model2.content));
      expect(model1.status, equals(model2.status));
      
      // Check inequality
      expect(model1.title, isNot(equals(model3.title)));
    });
    
    test('_parseStatus handles various status strings correctly', () {
      // Use a dummy event and modify the status tag
      Event createEventWithStatus(String? statusValue) {
          final tags = [
              ['d', 'd'], ['type', 'ask'], ['title', 't'],
              if (statusValue != null) ['status', statusValue],
          ];
          final event = Event(pubkey, 31111, tags, '', createdAt: 0);
          event.id = 'id';
          event.sig = 'sig';
          return event;
      }
      
      expect(ListingModel.fromEvent(createEventWithStatus('active')).status, ListingStatus.active);
      expect(ListingModel.fromEvent(createEventWithStatus('ACTIVE')).status, ListingStatus.active);
      expect(ListingModel.fromEvent(createEventWithStatus('inactive')).status, ListingStatus.inactive);
      expect(ListingModel.fromEvent(createEventWithStatus('fulfilled')).status, ListingStatus.fulfilled);
      expect(ListingModel.fromEvent(createEventWithStatus('expired')).status, ListingStatus.expired);
      expect(ListingModel.fromEvent(createEventWithStatus('cancelled')).status, ListingStatus.cancelled);
      expect(ListingModel.fromEvent(createEventWithStatus('unknown')).status, ListingStatus.active); // Default
      expect(ListingModel.fromEvent(createEventWithStatus(null)).status, ListingStatus.active); // Default for null
    });

  });
} 