import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostrmo/features/events/models/event_model.dart';
import 'package:nostrmo/features/events/providers/event_provider.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

// Create mock for Nostr client
class MockNostr extends Mock implements Client {
  @override
  String get publicKey => 'mock_pubkey';
  
  @override
  void signEvent(Event event) {
    // Set an ID for the event
    when(event.id).thenReturn('mock_event_id');
  }
  
  @override
  Future<void> sendEvent(Event event) async {
    // Simulate successful send
    return Future.value();
  }
}

@GenerateMocks([EventNotifier])
void main() {
  late ProviderContainer container;
  late MockNostr mockNostr;
  
  setUp(() {
    mockNostr = MockNostr();
    
    // Create a provider container for testing with overrides
    container = ProviderContainer(
      overrides: [
        eventProvider.overrideWith((ref) => EventNotifier(ref)),
      ],
    );
    
    // Manually assign mockNostr to the global nostr variable
    // This is not ideal but necessary due to the global variable usage
    nostr = mockNostr;
  });
  
  tearDown(() {
    container.dispose();
    nostr = null;
  });
  
  group('EventProvider Tests', () {
    test('Should create an event successfully', () async {
      final eventNotifier = container.read(eventProvider.notifier);
      
      // Define event parameters
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final title = 'Test Event';
      final description = 'Test Description';
      final groupId = 'test_group_id';
      
      try {
        // Attempt to create an event
        final event = await eventNotifier.createEvent(
          title: title,
          description: description,
          startAt: tomorrow,
          groupId: groupId,
          visibility: EventVisibility.public,
          tags: [],
        );
        
        // Verify the event was created with the correct properties
        expect(event, isNotNull);
        expect(event?.title, equals(title));
        expect(event?.description, equals(description));
        expect(event?.groupId, equals(groupId));
        expect(event?.visibility, equals(EventVisibility.public));
        
        // Verify the event was added to the provider state
        final events = container.read(eventProvider).value;
        expect(events, isNotNull);
        expect(events!.isNotEmpty, isTrue);
        expect(events.first.title, equals(title));
        
      } catch (e) {
        fail('Event creation failed with error: $e');
      }
    });
    
    test('Should handle event creation failure', () async {
      final eventNotifier = container.read(eventProvider.notifier);
      
      // Set up mock to fail
      when(mockNostr.sendEvent(any)).thenThrow(Exception('Failed to send event'));
      
      // Define event parameters
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      
      // Attempt to create an event and expect it to throw
      expect(
        () => eventNotifier.createEvent(
          title: 'Test Event',
          description: 'Test Description',
          startAt: tomorrow,
          groupId: 'test_group_id',
          visibility: EventVisibility.public,
          tags: [],
        ),
        throwsException,
      );
    });
  });
}