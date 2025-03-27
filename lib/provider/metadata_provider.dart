import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/nip05status.dart';
import 'package:nostrmo/data/event_db.dart';

import '../data/metadata.dart';
import '../data/metadata_db.dart';
import '../main.dart';

class MetadataProvider extends ChangeNotifier with LaterFunction {
  final Map<String, RelayListMetadata> _relayListMetadataCache = {};

  final Map<String, Metadata> _metadataCache = {};

  final Map<String, int> _handingPubkeys = {};

  final Map<String, ContactList> _contactListMap = {};

  static MetadataProvider? _metadataProvider;

  static Future<MetadataProvider> getInstance() async {
    if (_metadataProvider == null) {
      _metadataProvider = MetadataProvider();

      var list = await MetadataDB.all();
      for (var md in list) {
        if (md.valid == Nip05Status.NIP05_NOT_VALID) {
          md.valid = null;
        }
        _metadataProvider!._metadataCache[md.pubkey!] = md;
      }

      var events = await EventDB.list(Base.defaultDataIndex,
          [EventKind.relayListMetadata, EventKind.contactList], 0, 1000000);
      _metadataProvider!._contactListMap.clear();
      for (var e in events) {
        if (e.kind == EventKind.relayListMetadata) {
          var relayListMetadata = RelayListMetadata.fromEvent(e);
          _metadataProvider!._relayListMetadataCache[relayListMetadata.pubkey] =
              relayListMetadata;
        } else if (e.kind == EventKind.contactList) {
          var contactList = ContactList.fromJson(e.tags, e.createdAt);
          _metadataProvider!._contactListMap[e.pubkey] = contactList;
        }
      }

      // lazyTimeMS begin bigger and request less
      _metadataProvider!.laterTimeMS = 2000;
    }

    return _metadataProvider!;
  }

  List<Metadata> findUser(String str, {int? limit = 5}) {
    List<Metadata> list = [];
    if (StringUtil.isNotBlank(str)) {
      var values = _metadataCache.values;
      for (var metadata in values) {
        if ((metadata.displayName != null &&
                metadata.displayName!.contains(str)) ||
            (metadata.name != null && metadata.name!.contains(str)) ||
            (metadata.nip05 != null && metadata.nip05!.contains(str))) {
          list.add(metadata);

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

  Metadata? getMetadata(String pubkey) {
    var metadata = _metadataCache[pubkey];
    if (metadata != null) {
      return metadata;
    }

    if (!_needUpdatePubKeys.contains(pubkey) &&
        !_handingPubkeys.containsKey(pubkey)) {
      _needUpdatePubKeys.add(pubkey);
    }
    later(_laterCallback);

    return null;
  }

  int getNip05Status(String pubkey) {
    var metadata = getMetadata(pubkey);

    if (PlatformUtil.isWeb()) {
      // web can't valid NIP05 due to cors
      if (metadata != null) {
        if (metadata.nip05 != null) {
          return Nip05Status.NIP05_VALID;
        }

        return Nip05Status.NIP05_NOT_VALID;
      }

      return Nip05Status.NIP05_NOT_FOUND;
    }

    if (metadata == null) {
      return Nip05Status.METADATA_NOT_FOUND;
    } else if (StringUtil.isNotBlank(metadata.nip05)) {
      if (metadata.valid == null) {
        Nip05Validator.valid(metadata.nip05!, pubkey).then((valid) async {
          if (valid != null) {
            if (valid) {
              metadata.valid = Nip05Status.NIP05_VALID;
              await MetadataDB.update(metadata);
            } else {
              // only update cache, next open app vill valid again
              metadata.valid = Nip05Status.NIP05_NOT_VALID;
            }
            notifyListeners();
          }
        });

        return Nip05Status.NIP05_NOT_VALID;
      } else if (metadata.valid! == Nip05Status.NIP05_VALID) {
        return Nip05Status.NIP05_VALID;
      }

      return Nip05Status.NIP05_NOT_VALID;
    }

    return Nip05Status.NIP05_NOT_FOUND;
  }

  final EventMemBox _pendingEvents = EventMemBox(sortAfterAdd: false);

  void _handlePendingEvents() {
    for (var event in _pendingEvents.all()) {
      if (event.kind == EventKind.metadata) {
        if (StringUtil.isBlank(event.content)) {
          continue;
        }

        _handingPubkeys.remove(event.pubkey);

        var jsonObj = jsonDecode(event.content);
        var md = Metadata.fromJson(jsonObj);
        md.pubkey = event.pubkey;
        md.updated_at = event.createdAt;

        // check cache
        var oldMetadata = _metadataCache[md.pubkey];
        if (oldMetadata == null) {
          // db
          MetadataDB.insert(md);
          // cache
          _metadataCache[md.pubkey!] = md;
          // refresh
        } else if (oldMetadata.updated_at! < md.updated_at!) {
          // db
          MetadataDB.update(md);
          // cache
          _metadataCache[md.pubkey!] = md;
          // refresh
        }
      } else if (event.kind == EventKind.relayListMetadata) {
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
                EventKind.relayListMetadata,
                event.pubkey
              ]);
          EventDB.insert(Base.defaultDataIndex, event);
          _eventToRelayListCache(event);
        }
      } else if (event.kind == EventKind.contactList) {
        var oldContactList = _contactListMap[event.pubkey];
        if (oldContactList == null) {
          // insert
          EventDB.insert(Base.defaultDataIndex, event);
          _eventToContactList(event);
        } else if (event.createdAt > oldContactList.createdAt) {
          // update, remote old event and insert new event
          EventDB.execute(
              "delete from event where key_index = ? and kind = ? and pubkey = ?",
              [Base.defaultDataIndex, EventKind.contactList, event.pubkey]);
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
            EventKind.metadata,
          ],
          authors: [pubkey],
          limit: 1,
        );
        filters.add(filter.toJson());
      }
      {
        var filter = Filter(
          kinds: [
            EventKind.relayListMetadata,
          ],
          authors: [pubkey],
          limit: 1,
        );
        filters.add(filter.toJson());
      }
      {
        var filter = Filter(
          kinds: [
            EventKind.contactList,
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
    _metadataCache.clear();
    MetadataDB.deleteAll();
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
