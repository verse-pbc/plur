import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/features/events/models/event_model.dart';
import 'package:nostrmo/features/events/providers/event_provider.dart';
import 'package:nostrmo/features/events/screens/event_creation_screen.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/main.dart';

// Mock version of EventNotifier
class MockEventNotifier extends StateNotifier<AsyncValue<List<EventModel>>>
    implements EventNotifier {
  
  MockEventNotifier() : super(const AsyncValue.loading());
  
  bool createEventCalled = false;
  Map<String, dynamic>? lastEventParams;
  
  @override
  Future<EventModel?> createEvent({
    required String title,
    required String description,
    String? coverImageUrl,
    required DateTime startAt,
    DateTime? endAt,
    String? location,
    int? capacity,
    String? cost,
    required String groupId,
    required EventVisibility visibility,
    List<String> tags = const [],
    List<String> organizers = const [],
    String? recurrenceRule,
  }) async {
    createEventCalled = true;
    lastEventParams = {
      'title': title,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'startAt': startAt,
      'endAt': endAt,
      'location': location,
      'capacity': capacity,
      'cost': cost,
      'groupId': groupId,
      'visibility': visibility,
      'tags': tags,
      'organizers': organizers,
      'recurrenceRule': recurrenceRule,
    };
    
    // Return a mock event
    return EventModel(
      id: 'mock_id',
      pubkey: 'mock_pubkey',
      d: 'mock_d_tag',
      title: title,
      description: description,
      coverImageUrl: coverImageUrl,
      startAt: startAt,
      endAt: endAt,
      location: location,
      capacity: capacity,
      cost: cost,
      groupId: groupId,
      visibility: visibility,
      tags: tags,
      eventId: 'mock_event_id',
      createdAt: DateTime.now(),
      organizers: organizers.isEmpty ? ['mock_pubkey'] : organizers,
      recurrenceRule: recurrenceRule,
    );
  }
  
  // Implement required methods with minimal functionality
  @override
  Ref get ref => throw UnimplementedError();
  
  @override
  Future<void> loadEvents({String? groupId}) async {}
  
  @override
  Future<EventModel?> updateEvent(EventModel event) async {
    return event;
  }
  
  @override
  Future<bool> deleteEvent(EventModel event) async {
    return true;
  }
  
  @override
  List<EventModel> filterEvents({
    String? groupId,
    EventVisibility? visibility,
    DateTime? fromDate,
    DateTime? toDate,
    bool showPastEvents = false,
    bool onlyMyEvents = false,
  }) {
    return [];
  }
  
  @override
  List<EventModel> getEventsForDay(DateTime day, {String? groupId}) {
    return [];
  }
  
  @override
  EventModel? getEventById(String eventId) {
    return null;
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}

void main() {
  // Set up global mocks
  setUpAll(() {
    // Mock the nostr client global variable
    nostr = MockClient();
  });
  
  tearDownAll(() {
    nostr = null;
  });
  
  group('EventCreationScreen UI Tests', () {
    testWidgets('Should trigger event creation on form submission', 
        (WidgetTester tester) async {
      // Create a mock event notifier
      final mockEventNotifier = MockEventNotifier();
      
      // Wrap the widget in necessary providers
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventProvider.overrideWith((_) => mockEventNotifier),
          ],
          child: MaterialApp(
            home: EventCreationScreen(groupId: 'test_group_id'),
            localizationsDelegates: const [
              S.delegate,
            ],
          ),
        ),
      );
      
      // Allow widget to build completely
      await tester.pumpAndSettle();
      
      // Find the text fields
      final titleField = find.byType(TextFormField).first;
      final descriptionField = find.byType(TextFormField).at(1);
      
      // Enter text in fields
      await tester.enterText(titleField, 'Test Event Title');
      await tester.enterText(descriptionField, 'Test Event Description');
      
      // Find and tap the submit button
      final submitButton = find.byType(ElevatedButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();
      
      // Verify event creation was called with correct parameters
      expect(mockEventNotifier.createEventCalled, isTrue);
      expect(mockEventNotifier.lastEventParams?['title'], equals('Test Event Title'));
      expect(mockEventNotifier.lastEventParams?['description'], equals('Test Event Description'));
      expect(mockEventNotifier.lastEventParams?['groupId'], equals('test_group_id'));
    });
  });
}

// Simple mock for Nostr Client
class MockClient implements Client {
  @override
  String get publicKey => 'mock_pubkey';
  
  @override
  void signEvent(Event event) {}
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}