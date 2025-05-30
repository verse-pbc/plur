
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../main.dart';

class GroupDetailProvider extends ChangeNotifier
    with PendingEventsLaterFunction {
  static const int previousLength = 5;

  late int _initTime;

  GroupIdentifier? _groupIdentifier;

  EventMemBox newNotesBox = EventMemBox(sortAfterAdd: false);

  EventMemBox notesBox = EventMemBox(sortAfterAdd: false);

  EventMemBox chatsBox = EventMemBox(sortAfterAdd: false);

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
  }

  @override
  void dispose() {
    super.dispose;
    clear();
  }

  void onNewEvent(Event e) {
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
            notifyListeners();
          }
        }
      }
    } else if (e.kind == EventKind.groupChatMessage ||
        e.kind == EventKind.groupChatReply) {
      if (chatsBox.add(e)) {
        chatsBox.sort();
        notifyListeners();
      }
    }
  }

  void mergeNewEvent() {
    final isEmpty = newNotesBox.isEmpty();
    if (isEmpty) {
      return;
    }
    notesBox.addBox(newNotesBox);
    newNotesBox.clear();
    notesBox.sort();
    notifyListeners();
  }

  static List<int> supportEventKinds = [
    EventKind.groupNote,
    EventKind.groupNoteReply,
    EventKind.groupChatMessage,
    EventKind.groupChatReply,
  ];

  void doQuery(int? until) {
    if (_groupIdentifier != null) {
      var relays = [_groupIdentifier!.host];
      var filter = Filter(
        until: until ?? _initTime,
        kinds: supportEventKinds,
      );
      var jsonMap = filter.toJson();
      jsonMap["#h"] = [_groupIdentifier!.groupId];
      nostr!.query(
        [jsonMap],
        onEvent,
        tempRelays: relays,
        relayTypes: RelayType.onlyTemp,
        sendAfterAuth: true,
      );
    }
  }

  void onEvent(Event event) {
    later(event, (list) {
      bool noteAdded = false;
      bool chatAdded = false;

      for (var e in list) {
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

      if (noteAdded) {
        notesBox.sort();
      }
      if (chatAdded) {
        chatsBox.sort();
      }

      if (noteAdded || chatAdded) {
        // update ui
        notifyListeners();
      }
    }, null);
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
      notesBox.sort();
      notifyListeners();
    } else if (isGroupChat(e)) {
      chatsBox.delete(id);
      chatsBox.sort();
      notifyListeners();
    }
  }

  void updateGroupIdentifier(GroupIdentifier groupIdentifier) {
    if (_groupIdentifier == null ||
        _groupIdentifier.toString() != groupIdentifier.toString()) {
      // clear and need to query data
      clearData();
      _groupIdentifier = groupIdentifier;
      doQuery(null);
    } else {
      _groupIdentifier = groupIdentifier;
    }
  }

  refresh() {
    clearData();
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
    if (!isGroupNote(event)) return;
    if (!notesBox.add(event)) return;
    notesBox.sort();
    notifyListeners();
  }
}
