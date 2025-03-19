import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/nip05status.dart';
import 'package:nostrmo/data/event_db.dart';

import '../data/user.dart';
import '../data/user_db.dart';
import '../main.dart';

class MetadataProvider extends ChangeNotifier with LaterFunction {
  final Map<String, RelayListMetadata> _relayListMetadataCache = {};

  final Map<String, User> _userCache = {};

  final Map<String, int> _handingPubkeys = {};

  final Map<String, ContactList> _contactListMap = {};

  static MetadataProvider? _metadataProvider;

  static Future<MetadataProvider> getInstance() async {
    if (_metadataProvider == null) {
      _metadataProvider = MetadataProvider();

      var list = await UserDB.all();
      for (var md in list) {
        if (md.valid == Nip05Status.NIP05_NOT_VALID) {
          md.valid = null;
        }
        _metadataProvider!._userCache[md.pubkey!] = md;
      }

      var events = await EventDB.list(Base.defaultDataIndex,
          [EventKind.RELAY_LIST_METADATA, EventKind.CONTACT_LIST], 0, 1000000);
      _metadataProvider!._contactListMap.clear();
      for (var e in events) {
        if (e.kind == EventKind.RELAY_LIST_METADATA) {
          var relayListMetadata = RelayListMetadata.fromEvent(e);
          _metadataProvider!._relayListMetadataCache[relayListMetadata.pubkey] =
              relayListMetadata;
        } else if (e.kind == EventKind.CONTACT_LIST) {
          var contactList = ContactList.fromJson(e.tags, e.createdAt);
          _metadataProvider!._contactListMap[e.pubkey] = contactList;
        }
      }

      // lazyTimeMS begin bigger and request less
      _metadataProvider!.laterTimeMS = 2000;
    }

    return _metadataProvider!;
  }

  List<User> findUser(String str, {int? limit = 5}) {
    List<User> list = [];
    if (StringUtil.isNotBlank(str)) {
      var values = _userCache.values;
      for (final user in values) {
        if ((user.displayName != null && user.displayName!.contains(str)) ||
            (user.name != null && user.name!.contains(str)) ||
            (user.nip05 != null && user.nip05!.contains(str))) {
          list.add(user);

          if (limit != null && list.length >= limit) {
            break;
          }
        }
      }
    }
    return list;
  }

  void _laterCallback() {
    if (_needUpdatePubKeys.isNotEmpty) {
      _laterSearch();
    }

    if (!_pendingEvents.isEmpty()) {
      _handlePendingEvents();
    }
  }

  final List<String> _needUpdatePubKeys = [];

  void update(String pubkey) {
    if (!_needUpdatePubKeys.contains(pubkey)) {
      _needUpdatePubKeys.add(pubkey);
    }
    later(_laterCallback);
  }

  User? getUser(String pubkey) {
    final user = _userCache[pubkey];
    if (user != null) {
      return user;
    }

    if (!_needUpdatePubKeys.contains(pubkey) &&
        !_handingPubkeys.containsKey(pubkey)) {
      _needUpdatePubKeys.add(pubkey);
    }
    later(_laterCallback);

    return null;
  }

  int getNip05Status(String pubkey) {
    var user = getUser(pubkey);

    if (PlatformUtil.isWeb()) {
      // web can't valid NIP05 due to cors
      if (user != null) {
        if (user.nip05 != null) {
          return Nip05Status.NIP05_VALID;
        }

        return Nip05Status.NIP05_NOT_VALID;
      }

      return Nip05Status.NIP05_NOT_FOUND;
    }

    if (user == null) {
      return Nip05Status.METADATA_NOT_FOUND;
    } else if (StringUtil.isNotBlank(user.nip05)) {
      if (user.valid == null) {
        Nip05Validator.valid(user.nip05!, pubkey).then((valid) async {
          if (valid != null) {
            if (valid) {
              user.valid = Nip05Status.NIP05_VALID;
              await UserDB.update(user);
            } else {
              // only update cache, next open app vill valid again
              user.valid = Nip05Status.NIP05_NOT_VALID;
            }
            notifyListeners();
          }
        });

        return Nip05Status.NIP05_NOT_VALID;
      } else if (user.valid! == Nip05Status.NIP05_VALID) {
        return Nip05Status.NIP05_VALID;
      }

      return Nip05Status.NIP05_NOT_VALID;
    }

    return Nip05Status.NIP05_NOT_FOUND;
  }

  final EventMemBox _pendingEvents = EventMemBox(sortAfterAdd: false);

  void _handlePendingEvents() {
    for (var event in _pendingEvents.all()) {
      if (event.kind == EventKind.METADATA) {
        if (StringUtil.isBlank(event.content)) {
          continue;
        }

        _handingPubkeys.remove(event.pubkey);

        var jsonObj = jsonDecode(event.content);
        var user = User.fromJson(jsonObj);
        user.pubkey = event.pubkey;
        user.updated_at = event.createdAt;

        // check cache
        final oldUser = _userCache[user.pubkey];
        if (oldUser == null) {
          // db
          UserDB.insert(user);
          // cache
          _userCache[user.pubkey!] = user;
          // refresh
        } else if (oldUser.updated_at! < user.updated_at!) {
          // db
          UserDB.update(user);
          // cache
          _userCache[user.pubkey!] = user;
          // refresh
        }
      } else if (event.kind == EventKind.RELAY_LIST_METADATA) {
        // this is relayInfoMetadata, only set to cache, not update UI
        var oldRelayListMetadata = _relayListMetadataCache[event.pubkey];
        if (oldRelayListMetadata == null) {
          // insert
          EventDB.insert(Base.defaultDataIndex, event);
          _eventToRelayListCache(event);
        } else if (event.createdAt > oldRelayListMetadata.createdAt) {
          // update, remote old event and insert new event
          EventDB.execute(
              "delete from event where key_index = ? and kind = ? and pubkey = ?",
              [
                Base.defaultDataIndex,
                EventKind.RELAY_LIST_METADATA,
                event.pubkey
              ]);
          EventDB.insert(Base.defaultDataIndex, event);
          _eventToRelayListCache(event);
        }
      } else if (event.kind == EventKind.CONTACT_LIST) {
        var oldContactList = _contactListMap[event.pubkey];
        if (oldContactList == null) {
          // insert
          EventDB.insert(Base.defaultDataIndex, event);
          _eventToContactList(event);
        } else if (event.createdAt > oldContactList.createdAt) {
          // update, remote old event and insert new event
          EventDB.execute(
              "delete from event where key_index = ? and kind = ? and pubkey = ?",
              [Base.defaultDataIndex, EventKind.CONTACT_LIST, event.pubkey]);
          EventDB.insert(Base.defaultDataIndex, event);
          _eventToContactList(event);
        }
      }
    }

    _pendingEvents.clear();
    notifyListeners();
  }

  void onEvent(Event event) {
    _pendingEvents.add(event);
    later(_laterCallback);
  }

  void _laterSearch() {
    if (_needUpdatePubKeys.isEmpty) {
      return;
    }

    // if (!nostr!.readable()) {
    //   // the nostr isn't readable later handle it again.
    //   later(_laterCallback, null);
    //   return;
    // }

    List<Map<String, dynamic>> filters = [];
    for (var pubkey in _needUpdatePubKeys) {
      {
        var filter = Filter(
          kinds: [
            EventKind.METADATA,
          ],
          authors: [pubkey],
          limit: 1,
        );
        filters.add(filter.toJson());
      }
      {
        var filter = Filter(
          kinds: [
            EventKind.RELAY_LIST_METADATA,
          ],
          authors: [pubkey],
          limit: 1,
        );
        filters.add(filter.toJson());
      }
      {
        var filter = Filter(
          kinds: [
            EventKind.CONTACT_LIST,
          ],
          authors: [pubkey],
          limit: 1,
        );
        filters.add(filter.toJson());
      }
      if (filters.length > 20) {
        nostr!.query(filters, onEvent);
        filters = [];
      }
    }
    if (filters.isNotEmpty) {
      nostr!.query(filters, onEvent);
    }

    for (var pubkey in _needUpdatePubKeys) {
      _handingPubkeys[pubkey] = 1;
    }
    _needUpdatePubKeys.clear();
  }

  void clear() {
    _userCache.clear();
    UserDB.deleteAll();
  }

  ContactList? getContactList(String pubkey) {
    return _contactListMap[pubkey];
  }

  RelayListMetadata? getRelayListMetadata(String pubkey) {
    return _relayListMetadataCache[pubkey];
  }

  void _eventToRelayListCache(Event event) {
    RelayListMetadata rlm = RelayListMetadata.fromEvent(event);
    _relayListMetadataCache[rlm.pubkey] = rlm;
  }

  void _eventToContactList(Event event) {
    var contactList = ContactList.fromJson(event.tags, event.createdAt);
    _contactListMap[event.pubkey] = contactList;
  }

  List<String> getExtralRelays(String pubkey, bool isWrite) {
    List<String> tempRelays = [];
    var relayListMetadata = metadataProvider.getRelayListMetadata(pubkey);
    if (relayListMetadata != null) {
      late List<String> relays;
      if (isWrite) {
        relays = relayListMetadata.writeAbleRelays;
      } else {
        relays = relayListMetadata.readAbleRelays;
      }
      tempRelays = nostr!.getExtralReadableRelays(relays, 3);
    }
    return tempRelays;
  }
}
