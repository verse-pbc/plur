import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/router/tag/topic_map.dart';

import '../main.dart';
import 'data_util.dart';

class ContactListProvider extends ChangeNotifier {
  static ContactListProvider? _contactListProvider;

  Event? _event;

  String content = "";

  ContactList? _contactList;

  Map<String, Event> followSetEventMap = {};

  final Map<String, FollowSet> _followSetMap = {};

  static ContactListProvider getInstance() {
    _contactListProvider ??= ContactListProvider();
    return _contactListProvider!;
  }

  void reload({Nostr? targetNostr}) {
    targetNostr ??= nostr;

    String? pubkey;
    if (targetNostr != null) {
      pubkey = targetNostr.publicKey;
    }

    var str = sharedPreferences.getString(DataKey.contactLists);
    if (StringUtil.isNotBlank(str)) {
      var jsonMap = jsonDecode(str!);

      if (jsonMap is Map<String, dynamic>) {
        String? eventStr;
        if (StringUtil.isNotBlank(pubkey)) {
          eventStr = jsonMap[pubkey];
        } else if (jsonMap.length == 1) {
          eventStr = jsonMap.entries.first.value as String;
        }

        if (eventStr != null) {
          var eventMap = jsonDecode(eventStr);
          _contactListProvider!._event = Event.fromJson(eventMap);
          _contactListProvider!._contactList = ContactList.fromJson(
              _contactListProvider!._event!.tags,
              _contactListProvider!._event!.createdAt);
          _contactListProvider!.content = _contactListProvider!._event!.content;

          return;
        }
      }
    }

    _contactListProvider!._contactList = ContactList();
  }

  void clearCurrentContactList() {
    var pubkey = nostr!.publicKey;
    var str = sharedPreferences.getString(DataKey.contactLists);
    if (StringUtil.isNotBlank(str)) {
      var jsonMap = jsonDecode(str!);
      if (jsonMap is Map) {
        jsonMap.remove(pubkey);

        var jsonStr = jsonEncode(jsonMap);
        sharedPreferences.setString(DataKey.contactLists, jsonStr);
      }
    }
  }

  var subscriptId = StringUtil.rndNameStr(16);

  void query({Nostr? targetNostr}) {
    targetNostr ??= nostr;
    subscriptId = StringUtil.rndNameStr(16);
    var filter = Filter(
        kinds: [EventKind.contactList],
        limit: 1,
        authors: [targetNostr!.publicKey]);
    var filter1 = Filter(
        kinds: [EventKind.followSets],
        limit: 100,
        authors: [targetNostr.publicKey]);
    targetNostr.addInitQuery([
      filter.toJson(),
      filter1.toJson(),
    ], _onEvent, id: subscriptId);
  }

  void _onEvent(Event e) async {
    if (e.kind == EventKind.contactList) {
      if (_event == null || e.createdAt > _event!.createdAt) {
        _event = e;
        _contactList = ContactList.fromJson(e.tags, _event!.createdAt);
        content = e.content;
        _saveAndNotify();

        relayProvider.relayUpdateByContactListEvent(e);
      }
    } else if (e.kind == EventKind.followSets) {
      var dTag = FollowSet.getDTag(e);
      if (dTag != null) {
        var oldFollowSet = _followSetMap[dTag];
        if (oldFollowSet != null) {
          if (e.createdAt > oldFollowSet.createdAt) {
            _followSetMap.remove(dTag);
            followSetEventMap[dTag] = e;
            notifyListeners();
          }
        } else {
          followSetEventMap[dTag] = e;
          notifyListeners();
        }
      }
    }
  }

  void _saveAndNotify({bool notify = true}) {
    var eventJsonMap = _event!.toJson();
    var eventJsonStr = jsonEncode(eventJsonMap);

    var pubkey = nostr!.publicKey;
    Map<String, dynamic>? allJsonMap;

    var str = sharedPreferences.getString(DataKey.contactLists);
    if (StringUtil.isNotBlank(str)) {
      allJsonMap = jsonDecode(str!);
    }
    allJsonMap ??= {};

    allJsonMap[pubkey] = eventJsonStr;
    var jsonStr = jsonEncode(allJsonMap);

    sharedPreferences.setString(DataKey.contactLists, jsonStr);

    if (notify) {
      notifyListeners();
      followEventProvider.metadataUpdatedCallback(_contactList);
    }
  }

  int total() {
    return _contactList!.total();
  }

  void addContact(Contact contact) async {
    _contactList!.add(contact);
    var result = await sendContactList();
    if (!result) {
      _contactList!.remove(contact.publicKey);
    }

    _saveAndNotify();
  }

  void removeContact(String pubkey) async {
    _contactList!.remove(pubkey);
    var result = await sendContactList();
    if (!result) {
      _contactList!.add(Contact(publicKey: pubkey));
    }

    _saveAndNotify();
  }

  void updateContacts(ContactList contactList) async {
    var oldContactList = _contactList;
    _contactList = contactList;
    var result = await sendContactList();
    if (!result) {
      _contactList = oldContactList;
    }

    _saveAndNotify();
  }

  ContactList? get contactList => _contactList;

  Iterable<Contact> list() {
    return _contactList!.list();
  }

  Contact? getContact(String pubkey) {
    return _contactList!.get(pubkey);
  }

  void clear() {
    _event = null;
    _contactList!.clear();
    content = "";
    clearCurrentContactList();
    _followSetMap.clear();
    followSetEventMap.clear();

    notifyListeners();
  }

  bool containTag(String tag) {
    var list = TopicMap.getList(tag);
    if (list != null) {
      for (var t in list) {
        var exist = _contactList!.containsTag(t);
        if (exist) {
          return true;
        }
      }
      return false;
    } else {
      return _contactList!.containsTag(tag);
    }
  }

  Future<bool> sendContactList() async {
    var newEvent = await nostr!.sendContactList(_contactList!, content);
    if (newEvent != null) {
      _event = newEvent;
      return true;
    }

    return false;
  }

  void addTag(String tag) async {
    _contactList!.addTag(tag);
    var result = await sendContactList();
    if (!result) {
      _contactList!.removeTag(tag);
    }

    _saveAndNotify();
  }

  void removeTag(String tag) async {
    _contactList!.removeTag(tag);
    var result = await sendContactList();
    if (!result) {
      _contactList!.addTag(tag);
    }

    _saveAndNotify();
  }

  int totalFollowedTags() {
    return _contactList!.totalFollowedTags();
  }

  Iterable<String> tagList() {
    return _contactList!.tagList();
  }

  bool containCommunity(String id) {
    return _contactList!.containsCommunity(id);
  }

  void addCommunity(String tag) async {
    _contactList!.addCommunity(tag);
    var result = await sendContactList();
    if (!result) {
      _contactList!.removeCommunity(tag);
    }

    _saveAndNotify();
  }

  void removeCommunity(String tag) async {
    _contactList!.removeCommunity(tag);
    var result = await sendContactList();
    if (!result) {
      _contactList!.addCommunity(tag);
    }

    _saveAndNotify();
  }

  int totalfollowedCommunities() {
    return _contactList!.totalFollowedCommunities();
  }

  Iterable<String> followedCommunitiesList() {
    return _contactList!.followedCommunitiesList();
  }

  void updateRelaysContent(String relaysContent) async {
    var oldContent = content;
    content = relaysContent;
    var result = await sendContactList();
    if (!result) {
      content = oldContent;
    }

    _saveAndNotify(notify: false);
  }

  void deleteFollowSet(String dTag) {
    _followSetMap.remove(dTag);
    followSetEventMap.remove(dTag);

    var filter =
        Filter(authors: [nostr!.publicKey], kinds: [EventKind.followSets]);
    var filterMap = filter.toJson();
    filterMap["#d"] = [dTag];

    Map<String, int> deleted = {};
    nostr!.query([filterMap], (event) {
      if (event.kind == EventKind.followSets) {
        if (deleted[event.id] == null) {
          deleted[event.id] = 1;
          nostr!.deleteEvent(event.id);
        }
      }
    });
    notifyListeners();
  }

  void addFollowSet(FollowSet followSet) async {
    var event = await followSet.toEventMap(nostr!, nostr!.publicKey);
    if (event != null) {
      _followSetMap[followSet.dTag] = followSet;
      followSetEventMap[followSet.dTag] = event;
      nostr!.sendEvent(event);
      notifyListeners();
    }
  }

  Map<String, FollowSet> get followSetMap {
    if (followSetEventMap.length > _followSetMap.length) {
      List<Future<FollowSet?>> futures = [];
      for (var entry in followSetEventMap.entries) {
        var key = entry.key;
        var value = entry.value;

        if (_followSetMap[key] == null) {
          var future = FollowSet.genFollowSet(nostr!, value);
          futures.add(future);
        }
      }

      if (futures.isNotEmpty) {
        Future.wait(futures).then((followSets) {
          for (var followSet in followSets) {
            if (followSet != null) {
              _followSetMap[followSet.dTag] = followSet;
            }
          }

          notifyListeners();
        });
      }
    }

    return _followSetMap;
  }
}
