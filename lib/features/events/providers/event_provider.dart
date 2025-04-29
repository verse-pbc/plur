import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/features/events/models/event_model.dart';
import 'package:nostrmo/features/events/models/event_rsvp_model.dart';
import 'package:nostrmo/features/events/nostr_event_kinds.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/group_id_util.dart';
import 'package:nostrmo/util/error_logger.dart';

/// Provider for accessing event data
final eventProvider =
    StateNotifierProvider<EventNotifier, AsyncValue<List<EventModel>>>((ref) {
  return EventNotifier(ref);
});

/// Provider for accessing RSVP data
final eventRSVPProvider =
    StateNotifierProvider<EventRSVPNotifier, AsyncValue<List<EventRSVPModel>>>((ref) {
  return EventRSVPNotifier(ref);
});

/// Notifier class to manage event state
class EventNotifier extends StateNotifier<AsyncValue<List<EventModel>>> {
  final Ref ref;
  String? _subscriptionId;
  final Map<String, EventModel> _latestEvents = {};
  final List<Event> _pendingEvents = [];

  EventNotifier(this.ref) : super(const AsyncValue.loading()) {
    _startDelayedProcessing();
  }

  void _startDelayedProcessing() {
    const Duration processInterval = Duration(milliseconds: 500);
    Timer.periodic(processInterval, (timer) {
      if (_pendingEvents.isNotEmpty) {
        _processPendingEvents();
      }
    });
  }

  void _processPendingEvents() {
    if (_pendingEvents.isEmpty) return;
    
    final events = List<Event>.from(_pendingEvents);
    _pendingEvents.clear();
    
    for (final event in events) {
      _processEvent(event);
    }
    
    // Update state with all current events, sorted by startAt time
    state = AsyncValue.data(_latestEvents.values.toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt)));
  }

  void _processEvent(Event event) {
    try {
      // First check if this is an event of the correct kind
      if (event.kind != EventKindExtension.dateBoundedEvent && 
          event.kind != EventKindExtension.timeBoundedEvent) {
        debugPrint('Skipping event of wrong kind: ${event.kind}');
        return;
      }
      
      // Add basic validation for event structure
      if (event.tags.isEmpty) {
        debugPrint('Skipping event with empty tags');
        return;
      }
      
      try {
        final eventModel = EventModel.fromEvent(event);
        final key = '${eventModel.pubkey}:${eventModel.d}';
        
        // Check if this is a newer version of an existing event
        final existingEvent = _latestEvents[key];
        if (existingEvent == null || 
            event.createdAt > existingEvent.createdAt.millisecondsSinceEpoch ~/ 1000) {
          _latestEvents[key] = eventModel;
        }
      } catch (modelError, modelStack) {
        ErrorLogger.logError('Error creating event model from event', modelError, modelStack);
        // Continue processing other events, don't rethrow
      }
    } catch (e, stack) {
      ErrorLogger.logError('Error processing event', e, stack);
      // Continue without crashing
    }
  }

  void _handleSubscriptionEvent(Event event) {
    if (event.kind == EventKindExtension.dateBoundedEvent || 
        event.kind == EventKindExtension.timeBoundedEvent) {
      _pendingEvents.add(event);
    }
  }

  /// Load events based on optional filters
  Future<void> loadEvents({String? groupId}) async {
    // Check if Nostr client is initialized
    if (nostr == null) {
      ErrorLogger.logError('Warning: Nostr client not initialized when loading events', 
        'NullNostrClient', StackTrace.current);
      state = AsyncValue.data([]);
      return;
    }
    
    try {
      debugPrint("Loading events with groupId: $groupId");
      state = const AsyncValue.loading();
      _latestEvents.clear(); // Clear previous events
      
      // Create filters for date-bounded and time-bounded events
      final dateFilter = Filter(kinds: [EventKindExtension.dateBoundedEvent]);
      final timeFilter = Filter(kinds: [EventKindExtension.timeBoundedEvent]);
      
      // Convert filters to JSON to add custom tags
      dynamic dateFilterJson;
      dynamic timeFilterJson;
      
      try {
        dateFilterJson = dateFilter.toJson();
        timeFilterJson = timeFilter.toJson();
      } catch (filterError, filterStack) {
        ErrorLogger.logError('Error converting filters to JSON', filterError, filterStack);
        // Create basic JSON filters if conversion fails
        dateFilterJson = {"kinds": [EventKindExtension.dateBoundedEvent]};
        timeFilterJson = {"kinds": [EventKindExtension.timeBoundedEvent]};
      }
      
      // Add group filter if specified
      if (groupId != null) {
        try {
          // For better querying, we'll try multiple formats of the group ID
          List<String> groupIdFormats = [];
          
          // Add original group ID
          groupIdFormats.add(groupId);
          
          // If the group ID starts with wss://, extract the ID part
          if (groupId.startsWith("wss://")) {
            final idPart = GroupIdUtil.extractIdPart(groupId);
            if (idPart.isNotEmpty) {
              groupIdFormats.add(idPart);
            }
          }
          
          // Standardize the group ID
          String standardized = GroupIdUtil.standardizeGroupIdString(groupId);
          if (!groupIdFormats.contains(standardized)) {
            groupIdFormats.add(standardized);
          }
          
          // Add h-tag filter to both filters
          dateFilterJson["#h"] = groupIdFormats;
          timeFilterJson["#h"] = groupIdFormats;
          
          debugPrint("Added h-tag filter: ${dateFilterJson["#h"]}");
        } catch (groupIdError, groupIdStack) {
          ErrorLogger.logError('Error processing group ID for events', groupIdError, groupIdStack);
          // Continue without group filtering if it fails
        }
      }
      
      // Cancel previous subscription if exists
      if (_subscriptionId != null) {
        try {
          nostr!.unsubscribe(_subscriptionId!);
        } catch (e) {
          // Ignore errors when unsubscribing
        }
      }
      
      // Get recent events
      List<Event> initialEvents = [];
      try {
        // Query both date and time bounded events
        initialEvents = await nostr!.queryEvents([dateFilterJson, timeFilterJson]);
      } catch (queryError, queryStack) {
        ErrorLogger.logError("Error querying events", queryError, queryStack);
        // Continue with an empty list if query fails
      }
      
      // Process initial events
      for (final event in initialEvents) {
        _processEvent(event);
      }
      
      // Update state after initial load (with empty list fallback)
      try {
        state = AsyncValue.data(_latestEvents.values.toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt)));
      } catch (sortError, sortStack) {
        ErrorLogger.logError('Error sorting events', sortError, sortStack);
        // Fallback to unsorted list if sorting fails
        state = AsyncValue.data(_latestEvents.values.toList());
      }
      
      // Subscribe to future events
      try {
        _subscriptionId = "events_${DateTime.now().millisecondsSinceEpoch}";
        nostr!.subscribe(
          [dateFilterJson, timeFilterJson],
          _handleSubscriptionEvent,
          id: _subscriptionId,
        );
      } catch (subscribeError, subscribeStack) {
        ErrorLogger.logError('Error subscribing to events', subscribeError, subscribeStack);
        // Continue without subscription if it fails
      }
      
    } catch (error, stackTrace) {
      ErrorLogger.logError('Error loading events', error, stackTrace);
      // Set state to error but with an empty list so the UI can still function
      state = AsyncValue.data([]);
    }
  }

  /// Create a new event
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
    debugPrint('Creating event with title: $title, tags: $tags');
    
    if (nostr == null) {
      debugPrint('ERROR: Nostr client not initialized when creating event');
      throw Exception('Nostr client not initialized');
    }
    
    try {
      final pubkey = nostr!.publicKey;
      final d = DateTime.now().millisecondsSinceEpoch.toString(); // Unique identifier
      
      // Process the group ID
      String? processedGroupId = GroupIdUtil.standardizeGroupIdString(groupId);
      
      // Create event model
      final eventModel = EventModel(
        id: '', // Will be set after signing
        pubkey: pubkey,
        d: d,
        title: title,
        description: description,
        coverImageUrl: coverImageUrl,
        startAt: startAt,
        endAt: endAt,
        location: location,
        capacity: capacity,
        cost: cost,
        groupId: processedGroupId,
        visibility: visibility,
        tags: tags,
        createdAt: DateTime.now(),
        organizers: organizers.isEmpty ? [pubkey] : [...organizers, pubkey],
        recurrenceRule: recurrenceRule,
      );
      
      // Convert to Nostr event and sign
      Event eventToPublish = eventModel.toEvent();
      nostr!.signEvent(eventToPublish);
      
      // Create final model with event ID
      final finalEvent = eventModel.copyWith(
        id: eventToPublish.id,
        eventId: eventToPublish.id,
      );
      
      // Send to relays
      await nostr!.sendEvent(eventToPublish);
      
      // Update local state
      _updateEvent(finalEvent);
      
      return finalEvent;
    } catch (error, stackTrace) {
      if (state is! AsyncError) {
        state = AsyncValue.error(error, stackTrace);
      }
      rethrow;
    }
  }

  /// Update an existing event
  Future<EventModel?> updateEvent(EventModel event) async {
    if (nostr == null) {
      throw Exception('Nostr client not initialized');
    }
    
    try {
      // Ensure we're using the correct group ID format
      String? processedGroupId;
      if (event.groupId != null) {
        processedGroupId = GroupIdUtil.standardizeGroupIdString(event.groupId!);
      }
      
      // Create an updated event with current timestamp
      final updatedEvent = event.copyWith(
        createdAt: DateTime.now(),
        groupId: processedGroupId,
      );
      
      // Convert to Nostr event and sign
      Event eventToPublish = updatedEvent.toEvent();
      nostr!.signEvent(eventToPublish);
      
      // Create final model with event ID
      final finalEvent = updatedEvent.copyWith(
        id: eventToPublish.id,
        eventId: eventToPublish.id,
      );
      
      // Send to relays
      await nostr!.sendEvent(eventToPublish);
      
      // Update local state
      _updateEvent(finalEvent);
      
      return finalEvent;
    } catch (error, stackTrace) {
      if (state is! AsyncError) {
        state = AsyncValue.error(error, stackTrace);
      }
      rethrow;
    }
  }

  /// Delete an event (by publishing a deletion event)
  Future<bool> deleteEvent(EventModel event) async {
    if (nostr == null) {
      throw Exception('Nostr client not initialized');
    }
    
    try {
      // Create event IDs array for deletion
      final eventIds = [event.eventId ?? event.id];
      if (eventIds[0].isEmpty) {
        return false;
      }
      
      // Create deletion event
      final deletionEvent = Event.create(
        kind: 5, // Deletion event kind
        pubkey: nostr!.publicKey,
        content: 'Event deleted',
        tags: [
          ['e', eventIds[0]],
        ],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      
      // Sign and send
      nostr!.signEvent(deletionEvent);
      await nostr!.sendEvent(deletionEvent);
      
      // Remove from local cache
      _removeEvent(event);
      
      return true;
    } catch (error) {
      debugPrint('Error deleting event: $error');
      return false;
    }
  }

  /// Filter events by group, time range, visibility, etc.
  List<EventModel> filterEvents({
    String? groupId,
    EventVisibility? visibility,
    DateTime? fromDate,
    DateTime? toDate,
    bool showPastEvents = false,
    bool onlyMyEvents = false,
  }) {
    if (!state.hasValue) return [];
    
    final now = DateTime.now();
    final myPubkey = nostr?.publicKey;
    
    return state.value!.where((event) {
      // Filter by group ID
      if (groupId != null && event.groupId != null) {
        if (!GroupIdUtil.doGroupIdsMatch(groupId, event.groupId)) {
          return false;
        }
      }
      
      // Filter by visibility
      if (visibility != null && event.visibility != visibility) {
        return false;
      }
      
      // Filter by date range
      if (fromDate != null && event.startAt.isBefore(fromDate)) {
        return false;
      }
      
      if (toDate != null && event.startAt.isAfter(toDate)) {
        return false;
      }
      
      // Filter past events
      if (!showPastEvents) {
        // For date-only events, check if it's today or in the future
        if (event.endAt == null) {
          // Use end of day for comparison
          final endOfDay = DateTime(event.startAt.year, event.startAt.month, event.startAt.day, 23, 59, 59);
          if (endOfDay.isBefore(now)) {
            return false;
          }
        } else if (event.endAt!.isBefore(now)) {
          // For events with an end time, check if it's already over
          return false;
        }
      }
      
      // Filter only my events
      if (onlyMyEvents && myPubkey != null) {
        if (event.pubkey != myPubkey && !event.organizers.contains(myPubkey)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }
  
  /// Get events for a specific day
  List<EventModel> getEventsForDay(DateTime day, {String? groupId}) {
    try {
      final startOfDay = DateTime(day.year, day.month, day.day);
      final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);
      
      final filtered = filterEvents(
        groupId: groupId,
        fromDate: startOfDay,
        toDate: endOfDay,
        showPastEvents: true,
      );
      
      // Also include multi-day events that span this day
      if (state.hasValue) {
        for (final event in state.value!) {
          if (event.endAt != null && 
              event.startAt.isBefore(startOfDay) && 
              event.endAt!.isAfter(startOfDay)) {
            // This is a multi-day event that spans the target day
            if (!filtered.contains(event) && 
                (groupId == null || GroupIdUtil.doGroupIdsMatch(groupId, event.groupId))) {
              filtered.add(event);
            }
          }
        }
      }
      
      return filtered..sort((a, b) => a.startAt.compareTo(b.startAt));
    } catch (e, stack) {
      debugPrint('Error getting events for day: $e');
      debugPrint('Stack trace: $stack');
      return [];
    }
  }
  
  /// Get an event by ID
  EventModel? getEventById(String eventId) {
    if (!state.hasValue) return null;
    
    try {
      return state.value!.firstWhere(
        (event) => event.id == eventId || event.eventId == eventId,
      );
    } catch (e) {
      return null;
    }
  }

  void _updateEvent(EventModel event) {
    final key = '${event.pubkey}:${event.d}';
    final currentEvent = _latestEvents[key];
    
    // Update if this is a new event or a newer version
    if (currentEvent == null || 
        event.createdAt.isAfter(currentEvent.createdAt)) {
      _latestEvents[key] = event;
      
      // Update state with all current events, sorted by startAt time
      state = AsyncValue.data(_latestEvents.values.toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt)));
    }
  }
  
  void _removeEvent(EventModel event) {
    final key = '${event.pubkey}:${event.d}';
    _latestEvents.remove(key);
    
    // Update state
    state = AsyncValue.data(_latestEvents.values.toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt)));
  }

  @override
  void dispose() {
    if (_subscriptionId != null && nostr != null) {
      try {
        nostr!.unsubscribe(_subscriptionId!);
      } catch (_) {
        // Ignore errors during disposal
      }
    }
    super.dispose();
  }
}

/// Notifier class to manage RSVP state
class EventRSVPNotifier extends StateNotifier<AsyncValue<List<EventRSVPModel>>> {
  final Ref ref;
  String? _subscriptionId;
  final Map<String, EventRSVPModel> _latestRSVPs = {};
  final List<Event> _pendingEvents = [];

  EventRSVPNotifier(this.ref) : super(const AsyncValue.loading()) {
    _startDelayedProcessing();
  }

  void _startDelayedProcessing() {
    const Duration processInterval = Duration(milliseconds: 500);
    Timer.periodic(processInterval, (timer) {
      if (_pendingEvents.isNotEmpty) {
        _processPendingEvents();
      }
    });
  }

  void _processPendingEvents() {
    if (_pendingEvents.isEmpty) return;
    
    final events = List<Event>.from(_pendingEvents);
    _pendingEvents.clear();
    
    for (final event in events) {
      _processEvent(event);
    }
    
    // Update state with all current RSVPs
    state = AsyncValue.data(_latestRSVPs.values.toList());
  }

  void _processEvent(Event event) {
    try {
      // First check if this is an RSVP event
      if (event.kind != EventKindExtension.eventRSVP) {
        debugPrint('Skipping RSVP event of wrong kind: ${event.kind}');
        return;
      }
      
      // Add basic validation for event structure
      if (event.tags.isEmpty) {
        debugPrint('Skipping RSVP event with empty tags');
        return;
      }
      
      try {
        final rsvpModel = EventRSVPModel.fromEvent(event);
        final key = '${rsvpModel.pubkey}:${rsvpModel.eventDTag}';
        
        // Check if this is a newer version of an existing RSVP
        final existingRSVP = _latestRSVPs[key];
        if (existingRSVP == null || 
            event.createdAt > existingRSVP.createdAt.millisecondsSinceEpoch ~/ 1000) {
          _latestRSVPs[key] = rsvpModel;
        }
      } catch (modelError, modelStack) {
        ErrorLogger.logError('Error creating RSVP model from event', modelError, modelStack);
        // Continue processing other events, don't rethrow
      }
    } catch (e, stack) {
      ErrorLogger.logError('Error processing RSVP event', e, stack);
      // Continue without crashing
    }
  }

  void _handleSubscriptionEvent(Event event) {
    if (event.kind == EventKindExtension.eventRSVP) {
      _pendingEvents.add(event);
    }
  }

  /// Load RSVPs for events
  Future<void> loadRSVPs({String? eventId, String? groupId}) async {
    if (nostr == null) {
      state = AsyncValue.error('Nostr client not initialized', StackTrace.current);
      return;
    }
    
    try {
      debugPrint("Loading RSVPs with eventId: $eventId, groupId: $groupId");
      
      // Create filter for RSVP events
      final filter = Filter(kinds: [EventKindExtension.eventRSVP]);
      final filterJson = filter.toJson();
      
      // Add event filter if specified
      if (eventId != null) {
        filterJson["#e"] = [eventId];
      }
      
      // Add group filter if specified
      if (groupId != null) {
        // For better querying, we'll try multiple formats of the group ID
        List<String> groupIdFormats = [];
        
        // Add original group ID
        groupIdFormats.add(groupId);
        
        // If the group ID starts with wss://, extract the ID part
        if (groupId.startsWith("wss://")) {
          final idPart = GroupIdUtil.extractIdPart(groupId);
          if (idPart.isNotEmpty) {
            groupIdFormats.add(idPart);
          }
        }
        
        // Standardize the group ID
        String standardized = GroupIdUtil.standardizeGroupIdString(groupId);
        if (!groupIdFormats.contains(standardized)) {
          groupIdFormats.add(standardized);
        }
        
        // Add h-tag filter
        filterJson["#h"] = groupIdFormats;
        
        debugPrint("Added h-tag filter for RSVPs: ${filterJson["#h"]}");
      }
      
      // Cancel previous subscription if exists
      if (_subscriptionId != null) {
        try {
          nostr!.unsubscribe(_subscriptionId!);
        } catch (e) {
          // Ignore errors when unsubscribing
        }
      }
      
      // If loading RSVPs for a specific event or group, clear existing
      if (eventId != null || groupId != null) {
        _latestRSVPs.clear();
        state = const AsyncValue.loading();
      }
      
      // Get recent RSVPs
      List<Event> initialEvents = [];
      try {
        initialEvents = await nostr!.queryEvents([filterJson]);
      } catch (e) {
        debugPrint("Error querying RSVP events: $e");
      }
      
      // Process initial events
      for (final event in initialEvents) {
        _processEvent(event);
      }
      
      // Update state after initial load
      state = AsyncValue.data(_latestRSVPs.values.toList());
      
      // Subscribe to future events
      _subscriptionId = "event_rsvps_${DateTime.now().millisecondsSinceEpoch}";
      nostr!.subscribe(
        [filterJson],
        _handleSubscriptionEvent,
        id: _subscriptionId,
      );
      
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Submit an RSVP for an event
  Future<EventRSVPModel?> submitRSVP({
    required String eventId,
    required String eventDTag,
    required RSVPStatus status,
    String? groupId,
    required String visibility,
    Map<String, dynamic>? customResponses,
  }) async {
    if (nostr == null) {
      throw Exception('Nostr client not initialized');
    }
    
    try {
      final pubkey = nostr!.publicKey;
      
      // Process the group ID if provided
      String? processedGroupId;
      if (groupId != null) {
        processedGroupId = GroupIdUtil.standardizeGroupIdString(groupId);
      }
      
      // Create RSVP model
      final rsvpModel = EventRSVPModel(
        pubkey: pubkey,
        eventId: eventId,
        eventDTag: eventDTag,
        status: status,
        groupId: processedGroupId,
        visibility: visibility,
        createdAt: DateTime.now(),
        customResponses: customResponses,
      );
      
      // Convert to Nostr event and sign
      Event eventToPublish = rsvpModel.toEvent();
      nostr!.signEvent(eventToPublish);
      
      // Create final model with event ID
      final finalRSVP = rsvpModel.copyWith(
        id: eventToPublish.id,
      );
      
      // Send to relays
      await nostr!.sendEvent(eventToPublish);
      
      // Update local state
      _updateRSVP(finalRSVP);
      
      return finalRSVP;
    } catch (error, stackTrace) {
      if (state is! AsyncError) {
        state = AsyncValue.error(error, stackTrace);
      }
      rethrow;
    }
  }

  /// Get RSVPs for a specific event
  List<EventRSVPModel> getRSVPsForEvent(String eventId) {
    if (!state.hasValue) return [];
    
    return state.value!.where((rsvp) => rsvp.eventId == eventId).toList();
  }
  
  /// Get RSVP counts for a specific event
  Map<RSVPStatus, int> getRSVPCountsForEvent(String eventId) {
    final rsvps = getRSVPsForEvent(eventId);
    final counts = {
      RSVPStatus.going: 0,
      RSVPStatus.interested: 0,
      RSVPStatus.notGoing: 0,
    };
    
    for (final rsvp in rsvps) {
      counts[rsvp.status] = (counts[rsvp.status] ?? 0) + 1;
    }
    
    return counts;
  }
  
  /// Get current user's RSVP for an event
  EventRSVPModel? getUserRSVPForEvent(String eventId) {
    if (!state.hasValue || nostr == null) return null;
    
    final myPubkey = nostr!.publicKey;
    try {
      return state.value!.firstWhere(
        (rsvp) => rsvp.eventId == eventId && rsvp.pubkey == myPubkey,
      );
    } catch (e) {
      return null;
    }
  }

  void _updateRSVP(EventRSVPModel rsvp) {
    final key = '${rsvp.pubkey}:${rsvp.eventDTag}';
    final currentRSVP = _latestRSVPs[key];
    
    // Update if this is a new RSVP or a newer version
    if (currentRSVP == null || 
        rsvp.createdAt.isAfter(currentRSVP.createdAt)) {
      _latestRSVPs[key] = rsvp;
      
      // Update state
      state = AsyncValue.data(_latestRSVPs.values.toList());
    }
  }
  
  /// Update the UI optimistically before the actual server change happens
  void updateOptimistically(EventRSVPModel rsvp) {
    final key = '${rsvp.pubkey}:${rsvp.eventDTag}';
    
    // Store the optimistic update
    _latestRSVPs[key] = rsvp;
    
    // Update state immediately for responsive UI
    state = AsyncValue.data(_latestRSVPs.values.toList());
  }
  
  /// Remove an optimistic RSVP if needed
  void removeOptimisticRSVP(String pubkey, String eventId) {
    // Find and remove any RSVPs from this user for this event
    final keysToRemove = <String>[];
    
    for (final entry in _latestRSVPs.entries) {
      final rsvp = entry.value;
      if (rsvp.pubkey == pubkey && rsvp.eventId == eventId) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _latestRSVPs.remove(key);
    }
    
    // Update state
    if (keysToRemove.isNotEmpty) {
      state = AsyncValue.data(_latestRSVPs.values.toList());
    }
  }

  @override
  void dispose() {
    if (_subscriptionId != null && nostr != null) {
      try {
        nostr!.unsubscribe(_subscriptionId!);
      } catch (_) {
        // Ignore errors during disposal
      }
    }
    super.dispose();
  }
}