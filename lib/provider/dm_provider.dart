import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../data/dm_session_info.dart';
import '../data/dm_session_info_db.dart';
import '../data/event_db.dart';
import '../main.dart';

class DMProvider extends ChangeNotifier with PendingEventsLaterFunction {
  final List<DMSessionDetail> _knownList = [];

  final List<DMSessionDetail> _unknownList = [];

  final Map<String, DMSessionDetail> _sessionDetails = {};

  String? localPubkey;

  List<DMSessionDetail> get knownList => _knownList;

  List<DMSessionDetail> get unknownList => _unknownList;

  DMSessionDetail? sessionDetailFor(String pubkey) =>
      _sessionDetails[pubkey];

  DMSessionDetail findOrNewADetail(String pubkey) => [
        ...knownList,
        ..._unknownList,
      ].firstWhere(
        (detail) => detail.dmSession.pubkey == pubkey,
        orElse: () => DMSessionDetail(DMSession(pubkey: pubkey))
          ..info = DMSessionInfo(pubkey: pubkey, readedTime: 0),
      );

  void updateReadTime(DMSessionDetail detail) {
    var info = detail.info;
    final newestCreatedAt = detail.dmSession.newestEvent?.createdAt;
    if (info == null || newestCreatedAt == null) return;

    info.readedTime = newestCreatedAt;
    DMSessionInfoDB.update(info);
    notifyListeners();
  }

  void addEventAndUpdateReadTime(DMSessionDetail detail, Event event) {
    pendingEvents.add(event);
    _eventLaterHandle(pendingEvents, updateUI: false);
    updateReadTime(detail);
  }

  Future<DMSessionDetail> addDmSessionToKnown(DMSessionDetail detail) async {
    final keyIndex = settingsProvider.privateKeyIndex!;
    final pubkey = detail.dmSession.pubkey;

    DMSessionInfo o = DMSessionInfo(pubkey: pubkey);
    o.keyIndex = keyIndex;
    o.readedTime = detail.dmSession.newestEvent!.createdAt;
    await DMSessionInfoDB.insert(o);

    detail.info = o;

    unknownList.remove(detail);
    knownList.add(detail);

    _sortDetailList();
    notifyListeners();

    return detail;
  }

  int _initSince = 0;

  Future<void> initDMSessions(String localPubkey) async {
    _sessionDetails.clear();
    _knownList.clear();
    _unknownList.clear();

    this.localPubkey = localPubkey;
    var keyIndex = settingsProvider.privateKeyIndex!;
    var events = await EventDB.list(keyIndex,
        [EventKind.directMessage, EventKind.privateDirectMessage], 0, 10000000);
    if (events.isNotEmpty) {
      // find the newest event, subscribe behind the new newest event
      _initSince = events.first.createdAt;
    }

    Map<String, List<Event>> eventListMap = {};
    for (var event in events) {
      var pubkey = _getPubkey(localPubkey, event);
      if (StringUtil.isNotBlank(pubkey)) {
        var list = eventListMap[pubkey!];
        if (list == null) {
          list = [];
          eventListMap[pubkey] = list;
        }
        list.add(event);
      }
    }

    Map<String, DMSessionInfo> infoMap = {};
    var infos = await DMSessionInfoDB.all(keyIndex);
    for (final info in infos) {
      infoMap[info.pubkey!] = info;
    }

    for (final entry in eventListMap.entries) {
      final pubkey = entry.key;
      final list = entry.value;

      var session = DMSession(pubkey: pubkey);
      session.addEvents(list);

      var info = infoMap[pubkey];
      var detail = DMSessionDetail(session, info: info);
      if (info != null) {
        _knownList.add(detail);
      } else {
        _unknownList.add(detail);
      }
      _sessionDetails[pubkey] = detail;
    }

    _sortDetailList();
    notifyListeners();
  }

  void _sortDetailList() {
    _doSortDetailList(_knownList);
    _doSortDetailList(_unknownList);
  }

  void _doSortDetailList(List<DMSessionDetail> detailList) {
    detailList.sort((detail0, detail1) {
      return detail1.dmSession.newestEvent!.createdAt -
          detail0.dmSession.newestEvent!.createdAt;
    });
  }

  String? _getPubkey(String localPubkey, Event event) {
    if (event.pubkey != localPubkey) {
      return event.pubkey;
    }

    for (var tag in event.tags) {
      if (tag[0] == "p") {
        return tag[1] as String;
      }
    }

    return null;
  }

  bool _addEvent(String localPubkey, Event event) {
    var pubkey = _getPubkey(localPubkey, event);
    if (StringUtil.isBlank(pubkey)) {
      return false;
    }

    var sessionDetail = _sessionDetails[pubkey];
    if (sessionDetail == null) {
      var session = DMSession(pubkey: pubkey!);
      sessionDetail = DMSessionDetail(session);
      _sessionDetails[pubkey] = sessionDetail;

      _unknownList.add(sessionDetail);
    }

    final addResult = sessionDetail.dmSession.addEvent(event);
    if (addResult) {
      _sortDetailList();
    }

    return addResult;
  }

  void query(
      {Nostr? targetNostr, bool initQuery = false, bool queryAll = false}) {
    targetNostr ??= nostr;
    var filter0 = Filter(
      kinds: [EventKind.directMessage],
      authors: [targetNostr!.publicKey],
    );
    var filter1 = Filter(
      kinds: [EventKind.directMessage],
      p: [targetNostr.publicKey],
    );

    if (!queryAll || _initSince == 0) {
      filter0.since = _initSince + 1;
      filter1.since = _initSince + 1;
    }

    if (initQuery) {
      targetNostr.addInitQuery([filter0.toJson(), filter1.toJson()], onEvent);
    } else {
      targetNostr.query([filter0.toJson(), filter1.toJson()], onEvent);
    }
  }

  void onEvent(Event event) {
    later(event, _eventLaterHandle, null);
  }

  void _eventLaterHandle(List<Event> events, {bool updateUI = true}) {
    final pubkey = localPubkey;
    if (pubkey == null) {
      return;
    }

    bool updated = false;
    for (final event in events) {
      final addResult = _addEvent(pubkey, event);
      // save to local
      if (addResult) {
        updated = true;
        var keyIndex = settingsProvider.privateKeyIndex!;
        EventDB.insert(keyIndex, event);
      }
    }

    if (updated) {
      _sortDetailList();
      if (updateUI) {
        notifyListeners();
      }
    }
  }

  void clear() {
    _sessionDetails.clear();
    _knownList.clear();
    _unknownList.clear();

    notifyListeners();
  }
}

class DMSessionDetail {
  final DMSession dmSession;
  DMSessionInfo? info;

  DMSessionDetail(this.dmSession, {this.info});

  bool get hasNewMessage {
    if (info == null) {
      return true;
    } else if (dmSession.newestEvent != null &&
        info!.readedTime! < dmSession.newestEvent!.createdAt) {
      return true;
    }
    return false;
  }
}
