import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:nostrmo/util/notification_util.dart';

import '../consts/client_connected.dart';
import '../main.dart';
import 'data_util.dart';

class RelayProvider extends ChangeNotifier {
  static const defaultGroupsRelayAddress = 'wss://communities.nos.social';
  static RelayProvider? _relayProvider;

  List<String> relayAddrs = [];

  Map<String, RelayStatus> relayStatusMap = {};

  List<String> cacheRelayAddrs = [];

  RelayStatus? relayStatusLocal;

  final Map<String, RelayStatus> _tempRelayStatusMap = {};

  static RelayProvider getInstance() {
    if (_relayProvider == null) {
      _relayProvider = RelayProvider();
      // _relayProvider!._load();
      var l = sharedPreferences.getStringList(DataKey.cacheRelays);
      if (l != null) {
        _relayProvider!.cacheRelayAddrs.clear();
        _relayProvider!.cacheRelayAddrs.addAll(l);
      }
    }
    return _relayProvider!;
  }

  void loadRelayAddrs(String? content) {
    var relays = parseRelayAddrs(content);
    if (relays.isEmpty) {
      relays = [
        defaultGroupsRelayAddress,
        "wss://relay.nos.social",
        "wss://relay.damus.io",
        "wss://purplepag.es",
        "wss://nos.lol",
        "wss://relay.mostr.pub",
      ];
    }

    relayAddrs = relays;
  }

  List<String> parseRelayAddrs(String? content) {
    List<String> relays = [];
    if (StringUtil.isBlank(content)) {
      return relays;
    }

    var relayStatuses = NIP02.parseContenToRelays(content!);
    for (var relayStatus in relayStatuses) {
      var addr = relayStatus.addr;
      relays.add(addr);

      var oldRelayStatus = relayStatusMap[addr];
      if (oldRelayStatus != null) {
        oldRelayStatus.readAccess = relayStatus.readAccess;
        oldRelayStatus.writeAccess = relayStatus.writeAccess;
      } else {
        relayStatusMap[addr] = relayStatus;
      }
    }

    return relays;
  }

  RelayStatus? getRelayStatus(String addr) {
    return relayStatusMap[addr];
  }

  String relayNumStr() {
    var normalLength = relayAddrs.length;
    var cacheLength = cacheRelayAddrs.length;

    int connectedNum = 0;
    var it = relayStatusMap.values;
    for (var status in it) {
      if (status.connected == ClientConnected.connected) {
        connectedNum++;
      }
    }
    return "$connectedNum / ${normalLength + cacheLength}";
  }

  int total() {
    return relayAddrs.length;
  }

  Future<Nostr?> genNostrWithKey(String key) async {
    NostrSigner? nostrSigner;
    if (Nip19.isPubkey(key)) {
      nostrSigner = PubkeyOnlyNostrSigner(Nip19.decode(key));
    } else if (AndroidNostrSigner.isAndroidNostrSignerKey(key)) {
      var pubkey = AndroidNostrSigner.getPubkeyFromKey(key);
      var package = AndroidNostrSigner.getPackageFromKey(key);
      nostrSigner = AndroidNostrSigner(pubkey: pubkey, package: package);
    } else if (NIP07Signer.isWebNostrSignerKey(key)) {
      var pubkey = NIP07Signer.getPubkey(key);
      nostrSigner = NIP07Signer(pubkey: pubkey);
    } else if (NostrRemoteSignerInfo.isBunkerUrl(key)) {
      var info = NostrRemoteSignerInfo.parseBunkerUrl(key);
      if (info == null) {
        return null;
      }
      bool hasConnected = false;
      if (StringUtil.isNotBlank(info.userPubkey)) {
        hasConnected = true;
      }
      nostrSigner = NostrRemoteSigner(
          settingsProvider.relayMode != null
              ? settingsProvider.relayMode!
              : RelayMode.fastMode,
          info);
      await (nostrSigner as NostrRemoteSigner)
          .connect(sendConnectRequest: !hasConnected);
      if (StringUtil.isBlank(info.userPubkey)) {
        await nostrSigner.pullPubkey();
      }
      if (await nostrSigner.getPublicKey() == null) {
        return null;
      }
    } else {
      try {
        nostrSigner = LocalNostrSigner(key);
      } catch (exception, stackTrace) {
        await Sentry.captureException(exception, stackTrace: stackTrace);
      }
    }

    if (nostrSigner == null) {
      return null;
    }

    return await genNostr(nostrSigner);
  }

  Future<Nostr?> genNostr(NostrSigner signer) async {
    final pubkey = await signer.getPublicKey();
    if (pubkey == null) {
      return null;
    }

    var nostr = Nostr(signer, pubkey, [filterProvider], genTempRelay,
        onNotice: noticeProvider.onNotice);
    log("nostr init over");

    // add initQuery
    dmProvider.initDMSessions(nostr.publicKey);
    contactListProvider.reload(targetNostr: nostr);
    contactListProvider.query(targetNostr: nostr);
    followEventProvider.doQuery(targetNostr: nostr, initQuery: true);
    mentionMeProvider.doQuery(targetNostr: nostr, initQuery: true);
    // don't query after init, due to query dm need login to relay so the first query change to call by timer

    loadRelayAddrs(contactListProvider.content);
    listProvider.load(nostr.publicKey,
        [EventKind.bookmarksList, EventKind.emojisList, EventKind.groupList],
        targetNostr: nostr, initQuery: true);
    badgeProvider.reload(targetNostr: nostr, initQuery: true);

    // add local relay
    if (relayLocalDB != null &&
        settingsProvider.relayLocal != OpenStatus.close) {
      relayStatusLocal = RelayStatus(RelayLocal.localUrl);
      var relayLocal =
          RelayLocal(RelayLocal.localUrl, relayStatusLocal!, relayLocalDB!)
            ..relayStatusCallback = onRelayStatusChange;
      nostr.addRelay(relayLocal, init: true);
    }

    for (var relayAddr in relayAddrs) {
      log("begin to init $relayAddr");
      var custRelay = genRelay(relayAddr);
      try {
        nostr.addRelay(custRelay, init: true);
      } catch (e) {
        log("relay $relayAddr add to pool error ${e.toString()}");
      }
    }

    for (var relayAddr in cacheRelayAddrs) {
      log("begin to init $relayAddr");
      var custRelay = genRelay(relayAddr, relayType: RelayType.cache);
      try {
        nostr.addRelay(custRelay, init: true, relayType: RelayType.cache);
      } catch (e) {
        log("relay $relayAddr add to pool error ${e.toString()}");
      }
    }

    NotificationUtil.registerUserForPushNotifications(nostr);

    return nostr;
  }

  void onRelayStatusChange() {
    notifyListeners();
  }

  void addRelay(String relayAddr) {
    if (!relayAddrs.contains(relayAddr)) {
      relayAddrs.add(relayAddr);
      _doAddRelay(relayAddr);
      saveRelay();
    }
  }

  void addCacheRelay(String relayAddr) {
    if (!cacheRelayAddrs.contains(relayAddr)) {
      cacheRelayAddrs.add(relayAddr);
      _doAddRelay(relayAddr, relayType: RelayType.cache);
      saveCacheRelay();
      notifyListeners();
    }
  }

  void _doAddRelay(String relayAddr,
      {bool init = false, int relayType = RelayType.normal}) {
    var custRelay = genRelay(relayAddr, relayType: relayType);
    log("begin to init $relayAddr");
    nostr!.addRelay(custRelay,
        autoSubscribe: true, init: init, relayType: relayType);
  }

  void removeRelay(String relayAddr) {
    if (relayAddrs.contains(relayAddr)) {
      relayAddrs.remove(relayAddr);
      relayStatusMap.remove(relayAddr);
      nostr!.removeRelay(relayAddr);

      saveRelay();
    } else if (cacheRelayAddrs.contains(relayAddr)) {
      cacheRelayAddrs.remove(relayAddr);
      relayStatusMap.remove(relayAddr);
      nostr!.removeRelay(relayAddr, relayType: RelayType.cache);

      saveCacheRelay();
      notifyListeners();
    }
  }

  void saveRelay() {
    _updateRelayToContactList();

    // save to NIP-65
    var relayStatuses = _getRelayStatuses();
    NIP65.save(nostr!, relayStatuses);
  }

  void saveCacheRelay() {
    sharedPreferences.setStringList(DataKey.cacheRelays, cacheRelayAddrs);
  }

  void _updateRelayToContactList() {
    var relayStatuses = _getRelayStatuses();
    var relaysContent = NIP02.relaysToContent(relayStatuses);
    contactListProvider.updateRelaysContent(relaysContent);
    notifyListeners();
  }

  List<String> getWritableRelays() {
    List<String> list = [];
    for (var addr in relayAddrs) {
      var relayStatus = relayStatusMap[addr];
      if (relayStatus != null && relayStatus.writeAccess) {
        list.add(addr);
      }
    }
    return list;
  }

  List<RelayStatus> _getRelayStatuses() {
    List<RelayStatus> relayStatuses = [];
    for (var addr in relayAddrs) {
      var relayStatus = relayStatusMap[addr];
      if (relayStatus != null) {
        relayStatuses.add(relayStatus);
      }
    }
    return relayStatuses;
  }

  Relay genRelay(String relayAddr, {int relayType = RelayType.normal}) {
    var relayStatus = relayStatusMap[relayAddr];
    if (relayStatus == null) {
      relayStatus = RelayStatus(relayAddr, relayType: relayType);
      relayStatusMap[relayAddr] = relayStatus;
    }

    return _doGenRelay(relayStatus);
  }

  Relay _doGenRelay(RelayStatus relayStatus) {
    var relayAddr = relayStatus.addr;

    if (PlatformUtil.isWeb()) {
      // dart:isolate is not supported on dart4web
      return RelayBase(
        relayAddr,
        relayStatus,
      )..relayStatusCallback = onRelayStatusChange;
    } else {
      if (settingsProvider.relayMode == RelayMode.baseMode) {
        return RelayBase(
          relayAddr,
          relayStatus,
        )..relayStatusCallback = onRelayStatusChange;
      } else {
        return RelayIsolate(
          relayAddr,
          relayStatus,
          eventSignCheck: settingsProvider.eventSignCheck == OpenStatus.open,
          relayNetwork: settingsProvider.network,
        )..relayStatusCallback = onRelayStatusChange;
      }
    }
  }

  void relayUpdateByContactListEvent(Event event) {
    List<String> oldRelays = [...relayAddrs];
    loadRelayAddrs(event.content);
    _updateRelays(oldRelays);
  }

  void _updateRelays(List<String> oldRelays) {
    List<String> needToRemove = [];
    List<String> needToAdd = [];
    for (var oldRelay in oldRelays) {
      if (!relayAddrs.contains(oldRelay)) {
        // new addrs don't contain old relay, need to remove
        needToRemove.add(oldRelay);
      }
    }
    for (var relayAddr in relayAddrs) {
      if (!oldRelays.contains(relayAddr)) {
        // old addrs don't contain new relay, need to add
        needToAdd.add(relayAddr);
      }
    }

    for (var relayAddr in needToRemove) {
      relayStatusMap.remove(relayAddr);
      nostr!.removeRelay(relayAddr);
    }
    for (var relayAddr in needToAdd) {
      _doAddRelay(relayAddr);
    }
  }

  void clear() {
    // sharedPreferences.remove(DataKey.RELAY_LIST);
    relayStatusMap.clear();
    loadRelayAddrs(null);
    _tempRelayStatusMap.clear();
  }

  List<RelayStatus> tempRelayStatus() {
    List<RelayStatus> list = [..._tempRelayStatusMap.values];
    return list;
  }

  Relay genTempRelay(String addr) {
    var rs = _tempRelayStatusMap[addr];
    if (rs == null) {
      rs = RelayStatus(addr);
      _tempRelayStatusMap[addr] = rs;
    }

    return _doGenRelay(rs);
  }

  void cleanTempRelays() {
    List<String> needRemoveList = [];
    var now = DateTime.now().millisecondsSinceEpoch;
    for (var entry in _tempRelayStatusMap.entries) {
      var addr = entry.key;
      var status = entry.value;

      if (now - status.connectTime.millisecondsSinceEpoch > 1000 * 60 * 10 &&
          (status.lastNoteTime == null ||
              ((now - status.lastNoteTime!.millisecondsSinceEpoch) >
                  1000 * 60 * 10)) &&
          (status.lastQueryTime == null ||
              ((now - status.lastQueryTime!.millisecondsSinceEpoch) >
                  1000 * 60 * 10))) {
        // init time over 10 min
        // last note time over 10 min
        // last query time over 10 min
        needRemoveList.add(addr);
      }
    }

    for (var addr in needRemoveList) {
      _tempRelayStatusMap.remove(addr);
      nostr!.removeTempRelay(addr);
    }
  }
}
