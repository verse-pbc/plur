import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/features/events/models/event_chat_model.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/group_id_util.dart';

/// Provider for accessing event chat messages
final eventChatProvider =
    StateNotifierProvider<EventChatNotifier, AsyncValue<List<EventChatModel>>>((ref) {
  return EventChatNotifier(ref);
});

/// Notifier class to manage event chat messages state
class EventChatNotifier extends StateNotifier<AsyncValue<List<EventChatModel>>> {
  final Ref ref;
  String? _subscriptionId;
  final Map<String, EventChatModel> _latestMessages = {};
  final List<Event> _pendingEvents = [];
  String? _currentEventId;

  EventChatNotifier(this.ref) : super(const AsyncValue.loading()) {
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
    
    // Update state with all current messages, sorted by createdAt time
    state = AsyncValue.data(_latestMessages.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
  }

  void _processEvent(Event event) {
    try {
      // First check if this has the right subject tag
      bool isEventChat = false;
      for (final tag in event.tags) {
        if (tag is List && tag.isNotEmpty && tag[0] == 'subject' && tag.length > 1) {
          if (tag[1] == 'event-chat') {
            isEventChat = true;
            break;
          }
        }
      }
      
      if (!isEventChat) {
        return;
      }
      
      // Now, let's check if it's related to our current event
      if (_currentEventId != null) {
        bool isRelatedToCurrentEvent = false;
        for (final tag in event.tags) {
          if (tag is List && tag.isNotEmpty && tag[0] == 'e' && tag.length > 1) {
            if (tag[1] == _currentEventId) {
              isRelatedToCurrentEvent = true;
              break;
            }
          }
        }
        
        if (!isRelatedToCurrentEvent) {
          return;
        }
      }
      
      // Parse the event into our model
      final chatModel = EventChatModel.fromEvent(event);
      
      // Store in our messages map
      _latestMessages[event.id] = chatModel;
    } catch (e, stack) {
      debugPrint('Error processing event chat message: $e');
      debugPrint('Stack trace: $stack');
    }
  }

  void _handleSubscriptionEvent(Event event) {
    if (event.kind == 1) { // Standard notes
      _pendingEvents.add(event);
    }
  }

  /// Load chat messages for a specific event
  Future<void> loadEventChat({required String eventId, String? eventDTag, String? groupId}) async {
    // Check if Nostr client is initialized
    if (nostr == null) {
      debugPrint('Warning: Nostr client not initialized when loading event chat');
      state = AsyncValue.data([]);
      return;
    }
    
    try {
      debugPrint("Loading event chat for event ID: $eventId");
      state = const AsyncValue.loading();
      _latestMessages.clear(); // Clear previous messages
      _currentEventId = eventId; // Set current event ID
      
      // Create filter for notes (kind 1)
      final filter = Filter(kinds: [1]);
      final filterJson = filter.toJson();
      
      // Add event filter
      filterJson["#e"] = [eventId];
      
      // Add subject tag filter for event-chat
      filterJson["#subject"] = ["event-chat"];
      
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
      }
      
      // Cancel previous subscription if exists
      if (_subscriptionId != null) {
        try {
          nostr!.unsubscribe(_subscriptionId!);
        } catch (e) {
          // Ignore errors when unsubscribing
        }
      }
      
      // Get recent messages
      List<Event> initialEvents = [];
      try {
        initialEvents = await nostr!.queryEvents([filterJson]);
      } catch (e) {
        debugPrint("Error querying event chat messages: $e");
      }
      
      // Process initial events
      for (final event in initialEvents) {
        _processEvent(event);
      }
      
      // Update state after initial load
      state = AsyncValue.data(_latestMessages.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
      
      // Subscribe to future events
      _subscriptionId = "event_chat_${DateTime.now().millisecondsSinceEpoch}";
      nostr!.subscribe(
        [filterJson],
        _handleSubscriptionEvent,
        id: _subscriptionId,
      );
      
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Send a chat message for an event
  Future<EventChatModel?> sendMessage({
    required String eventId,
    required String eventDTag,
    required String content,
    String? replyTo,
    String? groupId,
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
      
      // Create chat message model
      final chatModel = EventChatModel(
        id: '', // Will be set after signing
        pubkey: pubkey,
        eventId: eventId,
        eventDTag: eventDTag,
        content: content,
        replyTo: replyTo,
        groupId: processedGroupId,
        createdAt: DateTime.now(),
      );
      
      // Convert to Nostr event and sign
      Event eventToPublish = chatModel.toEvent();
      nostr!.signEvent(eventToPublish);
      
      // Create final model with event ID
      final finalMessage = chatModel.copyWith(id: eventToPublish.id);
      
      // Send to relays
      await nostr!.sendEvent(eventToPublish);
      
      // Update local state
      _latestMessages[eventToPublish.id] = finalMessage;
      
      // Sort by timestamp
      state = AsyncValue.data(_latestMessages.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
      
      return finalMessage;
    } catch (error, stackTrace) {
      if (state is! AsyncError) {
        state = AsyncValue.error(error, stackTrace);
      }
      rethrow;
    }
  }

  /// Get messages for a specific event
  List<EventChatModel> getMessagesForEvent(String eventId) {
    if (!state.hasValue) return [];
    
    return state.value!
        .where((message) => message.eventId == eventId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Get thread of messages for a specific parent message
  List<EventChatModel> getThreadForMessage(String messageId) {
    if (!state.hasValue) return [];
    
    return state.value!
        .where((message) => message.replyTo == messageId || message.id == messageId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
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