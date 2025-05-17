import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/relay_provider.dart';
import 'package:nostrmo/util/app_logger.dart';

import '../../main.dart';

class GroupDetailProvider extends ChangeNotifier
    with PendingEventsLaterFunction {
  static const int previousLength = 5;

  late int _initTime;

  GroupIdentifier? _groupIdentifier;

  EventMemBox newNotesBox = EventMemBox(sortAfterAdd: false);

  EventMemBox notesBox = EventMemBox(sortAfterAdd: false);

  EventMemBox chatsBox = EventMemBox(sortAfterAdd: false);
  
  // Keep track of loading state
  bool isLoading = false;
  
  // Cache for event retrieval by ID
  final Map<String, Event> _eventCache = {};
  
  // Track if the provider has been disposed
  bool _disposed = false;

  GroupDetailProvider() {
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  void clear() {
    _groupIdentifier = null;
    clearData();
  }

  void clearData() {
    newNotesBox.clear();
    notesBox.clear();
    chatsBox.clear();
    _eventCache.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    disposeLater();
    clear();
    super.dispose();
  }

  bool onNewEvent(Event e) {
    bool wasAdded = false;
    
    // Cache the event regardless of type
    _eventCache[e.id] = e;
    
    if (e.kind == EventKind.groupNote ||
        e.kind == EventKind.groupNoteReply) {
      if (!notesBox.contains(e.id)) {
        if (newNotesBox.add(e)) {
          if (e.createdAt > _initTime) {
            _initTime = e.createdAt;
          }
          if (e.pubkey == nostr!.publicKey) {
            mergeNewEvent();
          } else {
            if (!_disposed) notifyListeners();
          }
          wasAdded = true;
        }
      }
    } else if (e.kind == EventKind.groupChatMessage ||
        e.kind == EventKind.groupChatReply) {
      if (chatsBox.add(e)) {
        chatsBox.sort();
        if (!_disposed) notifyListeners();
        wasAdded = true;
      }
    }
    
    return wasAdded;
  }

  void mergeNewEvent() {
    final isEmpty = newNotesBox.isEmpty();
    if (isEmpty) {
      return;
    }
    
    logger.d('Merging ${newNotesBox.length()} new events into main feed');
        
    notesBox.addBox(newNotesBox);
    newNotesBox.clear();
    notesBox.sort();
    if (!_disposed) notifyListeners();
  }

  static List<int> supportEventKinds = [
    EventKind.groupNote,
    EventKind.groupNoteReply,
    EventKind.groupChatMessage,
    EventKind.groupChatReply,
  ];

  void doQuery(int? until) {
    if (_groupIdentifier == null) {
      logger.w('Cannot query - group identifier is null');
      
      // Make sure loading indicator goes away
      if (isLoading) {
        isLoading = false;
        if (!_disposed) notifyListeners();
      }
      return;
    }
    
    logger.d('Querying for events in group ${_groupIdentifier!.groupId}');
        
    // Set loading state if this is an initial query (until is null)
    if (until == null) {
      isLoading = true;
      if (!_disposed) notifyListeners();
    }
    
    // Try to query multiple relays to maximize chances of getting events
    try {
      // Create filter
      var filter = Filter(
        until: until ?? _initTime,
        kinds: supportEventKinds,
        limit: 50, // Limit to avoid overwhelming the UI
      );
      var jsonMap = filter.toJson();
      jsonMap["#h"] = [_groupIdentifier!.groupId];
      
      // Query the group's specific relay
      nostr!.query(
        [jsonMap],
        onEvent,
        tempRelays: [_groupIdentifier!.host],
        relayTypes: RelayType.onlyTemp,
        sendAfterAuth: true,
      );
      
      // Also query default relay if different
      if (_groupIdentifier!.host != RelayProvider.defaultGroupsRelayAddress) {
        nostr!.query(
          [jsonMap],
          onEvent,
          tempRelays: [RelayProvider.defaultGroupsRelayAddress],
          relayTypes: RelayType.onlyTemp,
          sendAfterAuth: true,
        );
      }
    } catch (e, stack) {
      logger.e('Error in query', e, stack);
      
      // Make sure loading indicator goes away
      if (isLoading) {
        isLoading = false;
        if (!_disposed) notifyListeners();
      }
    }
    
    // Set a timeout to ensure loading indicator goes away
    Future.delayed(const Duration(seconds: 5), () {
      // Check if we've been disposed before notifying listeners
      if (isLoading && !_disposed) {
        isLoading = false;
        if (!_disposed) notifyListeners();
      }
    });
  }

  void onEvent(Event event) {
    later(event, (list) {
      bool noteAdded = false;
      bool chatAdded = false;
      int eventCount = 0;

      for (var e in list) {
        // Only process events that match this group's ID
        if (_isEventForThisGroup(e)) {
          eventCount++;
          
          // Cache the event
          _eventCache[e.id] = e;
          
          if (isGroupNote(e)) {
            if (notesBox.add(e)) {
              noteAdded = true;
            }
          } else if (isGroupChat(e)) {
            if (chatsBox.add(e)) {
              chatAdded = true;
            }
          }
        }
      }
      
      // If we received any events, we're no longer loading
      if (eventCount > 0 && isLoading) {
        isLoading = false;
        logger.d('Received $eventCount events for group ${_groupIdentifier?.groupId}');
      }

      if (noteAdded) {
        notesBox.sort();
      }
      if (chatAdded) {
        chatsBox.sort();
      }

      // Update UI if anything changed or if we're no longer loading
      if (noteAdded || chatAdded || (eventCount > 0 && isLoading)) {
        if (!_disposed) notifyListeners();
      }
    }, null);
  }
  
  bool _isEventForThisGroup(Event e) {
    if (_groupIdentifier == null) return false;
    
    // Check if event has an h-tag matching this group's ID
    for (var tag in e.tags) {
      if (tag is List && tag.isNotEmpty && tag.length > 1 && 
          tag[0] == "h" && tag[1] == _groupIdentifier!.groupId) {
        return true;
      }
    }
    return false;
  }

  bool isGroupNote(Event e) {
    return e.kind == EventKind.groupNote ||
        e.kind == EventKind.groupNoteReply;
  }

  bool isGroupChat(Event e) {
    return e.kind == EventKind.groupChatMessage ||
        e.kind == EventKind.groupChatReply;
  }

  void deleteEvent(Event e) {
    var id = e.id;
    if (isGroupNote(e)) {
      newNotesBox.delete(id);
      notesBox.delete(id);
      _eventCache.remove(id);
      notesBox.sort();
      if (!_disposed) notifyListeners();
    } else if (isGroupChat(e)) {
      chatsBox.delete(id);
      _eventCache.remove(id);
      chatsBox.sort();
      if (!_disposed) notifyListeners();
    }
  }

  void updateGroupIdentifier(GroupIdentifier groupIdentifier) {
    if (_groupIdentifier == null ||
        _groupIdentifier.toString() != groupIdentifier.toString()) {
      
      logger.i('Updating group identifier to ${groupIdentifier.groupId} at ${groupIdentifier.host}');
          
      // Clear and set loading state
      clearData();
      isLoading = true;
      if (!_disposed) notifyListeners();
      
      // Update identifier and query
      _groupIdentifier = groupIdentifier;
      doQuery(null);
    } else {
      _groupIdentifier = groupIdentifier;
    }
  }

  void refresh() {
    logger.d('Refreshing group ${_groupIdentifier?.groupId}');
    
    // Clear data and set loading state
    clearData();
    isLoading = true;
    if (!_disposed) notifyListeners();
    
    // Update time and query
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    doQuery(null);
  }

  List<String> notesPrevious() {
    return timelinePrevious(notesBox);
  }

  List<String> chatsPrevious() {
    return timelinePrevious(chatsBox);
  }

  List<String> timelinePrevious(
    EventMemBox box, {
    int length = previousLength,
  }) {
    var list = box.all();
    var listLength = list.length;

    List<String> previous = [];

    for (var i = 0; i < previousLength; i++) {
      var index = listLength - i - 1;
      if (index < 0) {
        break;
      }

      var event = list[index];
      var idSubStr = event.id.substring(0, 8);
      previous.add(idSubStr);
    }

    return previous;
  }

  /// Handles an event that the current user created from a group.
  ///
  /// Only processes group notes and updates the UI if the event was successfully
  /// added to the notes box.
  ///
  /// [event] The event to process
  void handleDirectEvent(Event event) {
    if (!isGroupNote(event) || _disposed) return;
    
    // Cache the event
    _eventCache[event.id] = event;
    
    if (!notesBox.add(event)) return;
    notesBox.sort();
    if (!_disposed) {
      if (!_disposed) notifyListeners();
    }
  }
  
  // Get an event by ID from cache
  Event? getEventById(String id) {
    return _eventCache[id];
  }
}
