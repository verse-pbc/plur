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

  DMSessionDetail? getSessionDetail(String pubkey) {
    return _sessionDetails[pubkey];
  }

  DMSessionDetail findOrNewADetail(String pubkey) {
    for (var detail in knownList) {
      if (detail.dmSession.pubkey == pubkey) {
        return detail;
      }
    }

    for (var detail in _unknownList) {
      if (detail.dmSession.pubkey == pubkey) {
        return detail;
      }
    }

    var dmSession = DMSession(pubkey: pubkey);
    DMSessionDetail detail = DMSessionDetail(dmSession);
    detail.info = DMSessionInfo(pubkey: pubkey, readedTime: 0);

    return detail;
  }

  void updateReadTime(DMSessionDetail? detail) {
    if (detail != null &&
        detail.info != null &&
        detail.dmSession.newestEvent != null) {
      detail.info!.readedTime = detail.dmSession.newestEvent!.createdAt;
      DMSessionInfoDB.update(detail.info!);
      notifyListeners();
    }
  }

  void addEventAndUpdateReadTime(DMSessionDetail detail, Event event) {
    pendingEvents.add(event);
    eventLaterHandle(pendingEvents, updateUI: false);
    updateReadTime(detail);
  }

  Future<DMSessionDetail> addDmSessionToKnown(DMSessionDetail detail) async {
    var keyIndex = settingsProvider.privateKeyIndex!;
    var pubkey = detail.dmSession.pubkey;
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
    var events = await EventDB.list(
        keyIndex,
        [EventKind.directMessage, EventKind.privateDirectMessage],
        0,
        10000000);
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
    for (var info in infos) {
      infoMap[info.pubkey!] = info;
    }

    for (var entry in eventListMap.entries) {
      var pubkey = entry.key;
      var list = entry.value;

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

    // // copy to a new list for provider update
    // var length = detailList.length;
    // List<DMSessionDetail> newlist =
    //     List.generate(length, (index) => detailList[index]);
    // return newlist;
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

    var addResult = sessionDetail.dmSession.addEvent(event);
    if (addResult) {
      _sortDetailList();
      // TODO
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
      // targetNostr.pool.subscribe([filter0.toJson(), filter1.toJson()], onEvent);
      targetNostr.query([filter0.toJson(), filter1.toJson()], onEvent);
    }
  }

  // void handleEventImmediately(Event event) {
  //   pendingEvents.add(event);
  //   eventLaterHandle(pendingEvents);
  // }

  void onEvent(Event event) {
    later(event, eventLaterHandle, null);
  }

  void eventLaterHandle(List<Event> events, {bool updateUI = true}) {
    bool updated = false;
    for (var event in events) {
      var addResult = _addEvent(localPubkey!, event);
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
  DMSession dmSession;
  DMSessionInfo? info;

  DMSessionDetail(this.dmSession, {this.info});

  bool hasNewMessage() {
    if (info == null) {
      return true;
    } else if (dmSession.newestEvent != null &&
        info!.readedTime! < dmSession.newestEvent!.createdAt) {
      return true;
    }
    return false;
  }
}
