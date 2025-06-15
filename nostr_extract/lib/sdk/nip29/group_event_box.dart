import '../event.dart';
import '../event_mem_box.dart';
import 'group_identifier.dart';

class GroupEventBox {
  int _newestTime = -1;

  GroupIdentifier groupIdentifier;

  GroupEventBox(this.groupIdentifier);

  final EventMemBox _noteBox = EventMemBox(sortAfterAdd: false);

  final EventMemBox _chatBox = EventMemBox(sortAfterAdd: false);

  final EventMemBox _notePendingBox = EventMemBox(sortAfterAdd: false);

  int get newestTime => _newestTime;

  void clear() {
    _newestTime = 0;
    _noteBox.clear();
    _chatBox.clear();
    _notePendingBox.clear();
  }

  bool _addEvent(EventMemBox box, Event event) {
    var result = box.add(event);
    if (result) {
      box.sort();
      _updateNewest();
      return true;
    }
    return false;
  }

  bool _addEvents(EventMemBox box, List<Event> events) {
    var result = _noteBox.addList(events);
    if (result) {
      _noteBox.sort();
      _updateNewest();
      return true;
    }
    return false;
  }

  void _updateNewest() {
    {
      var nbe = _noteBox.newestEvent;
      if (nbe != null && nbe.createdAt > _newestTime) {
        _newestTime = nbe.createdAt;
      }
    }
    {
      var nbe = _chatBox.newestEvent;
      if (nbe != null && nbe.createdAt > _newestTime) {
        _newestTime = nbe.createdAt;
      }
    }
    {
      var nbe = _notePendingBox.newestEvent;
      if (nbe != null && nbe.createdAt > _newestTime) {
        _newestTime = nbe.createdAt;
      }
    }
  }

  bool addNoteEvent(Event event) {
    return _addEvent(_noteBox, event);
  }

  bool addNoteEvents(List<Event> events) {
    return _addEvents(_noteBox, events);
  }

  bool addChatEvent(Event event) {
    return _addEvent(_chatBox, event);
  }

  bool addChatEvents(List<Event> events) {
    return _addEvents(_chatBox, events);
  }

  bool addNotePendingEvent(Event event) {
    return _addEvent(_notePendingBox, event);
  }

  bool addNotePendingEvents(List<Event> events) {
    return _addEvents(_notePendingBox, events);
  }
}
