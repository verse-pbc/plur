import 'dart:convert';


import '../event.dart';
import '../event_kind.dart';
import '../nip02/contact.dart';
import '../nip02/contact_list.dart';
import '../nostr.dart';
import '../utils/string_util.dart';

class FollowSet extends ContactList {
  String dTag;

  String? title;

  final Map<String, Contact> _publicContacts;
  final Map<String, int> _publicFollowedTags;
  final Map<String, int> _publicFollowedCommunities;
  final Map<String, Contact> _privateContacts;
  final Map<String, int> _privateFollowedTags;
  final Map<String, int> _privateFollowedCommunities;

  @override
  int createdAt;

  FollowSet(
    this.dTag,
    Map<String, Contact> contacts,
    Map<String, int> followedTags,
    Map<String, int> followedCommunities,
    this._publicContacts,
    this._publicFollowedTags,
    this._publicFollowedCommunities,
    this._privateContacts,
    this._privateFollowedTags,
    this._privateFollowedCommunities,
    this.createdAt, {
    this.title,
  }) : super(
          contacts: contacts,
          followedTags: followedTags,
          followedCommunities: followedCommunities,
        );

  static String? getDTag(Event e) {
    for (var tag in e.tags) {
      if (tag is List && tag.length > 1) {
        var k = tag[0];
        var v = tag[1];

        if (k == "d") {
          return v;
        }
      }
    }

    return null;
  }

  static Future<FollowSet?> genFollowSet(Nostr nostr, Event e) async {
    Map<String, Contact> contacts = {};
    Map<String, int> followedTags = {};
    Map<String, int> followedCommunities = {};

    Map<String, Contact> publicContacts = {};
    Map<String, int> publicFollowedTags = {};
    Map<String, int> publicFollowedCommunities = {};

    Map<String, Contact> privateContacts = {};
    Map<String, int> privateFollowedTags = {};
    Map<String, int> privateFollowedCommunities = {};

    ContactList.getContactInfoFromTags(
        e.tags, publicContacts, publicFollowedTags, publicFollowedCommunities);
    String dTag = "";
    String? title;
    for (var tag in e.tags) {
      if (tag is List && tag.length > 1) {
        var k = tag[0];
        var v = tag[1];

        if (k == "d") {
          dTag = v;
        } else if (k == "title") {
          title = v;
        }
      }
    }

    if (StringUtil.isNotBlank(e.content)) {
      try {
        var contentSource =
            await nostr.nostrSigner.decrypt(e.pubkey, e.content);
        if (StringUtil.isNotBlank(contentSource)) {
          var jsonObj = jsonDecode(contentSource!);
          if (jsonObj is List) {
            ContactList.getContactInfoFromTags(jsonObj, privateContacts,
                privateFollowedTags, privateFollowedCommunities);
          }
        }
      } catch (e) {
        // sometimes would decode fail
      }
    }

    contacts.addAll(publicContacts);
    contacts.addAll(privateContacts);
    followedTags.addAll(publicFollowedTags);
    followedTags.addAll(privateFollowedTags);
    followedCommunities.addAll(publicFollowedCommunities);
    followedCommunities.addAll(privateFollowedCommunities);

    return FollowSet(
      dTag,
      contacts,
      followedTags,
      followedCommunities,
      publicContacts,
      publicFollowedTags,
      publicFollowedCommunities,
      privateContacts,
      privateFollowedTags,
      privateFollowedCommunities,
      e.createdAt,
      title: title,
    );
  }

  Future<Event?> toEventMap(Nostr nostr, String pubkey) async {
    List<dynamic> tags = [];
    if (StringUtil.isNotBlank(dTag)) {
      tags.add(["d", dTag]);
    }
    if (StringUtil.isNotBlank(title)) {
      tags.add(["title", title]);
    }
    for (Contact contact in _publicContacts.values) {
      tags.add(["p", contact.publicKey, contact.url, contact.petname]);
    }
    for (var followedTag in _publicFollowedTags.keys) {
      tags.add(["t", followedTag]);
    }
    for (var id in _publicFollowedCommunities.keys) {
      tags.add(["a", id]);
    }

    List<dynamic> privateTags = [];
    for (Contact contact in _privateContacts.values) {
      privateTags.add(["p", contact.publicKey, contact.url, contact.petname]);
    }
    for (var followedTag in _privateFollowedTags.keys) {
      privateTags.add(["t", followedTag]);
    }
    for (var id in _privateFollowedCommunities.keys) {
      privateTags.add(["a", id]);
    }

    var contentSource = jsonEncode(privateTags);
    var content = await nostr.nostrSigner.encrypt(pubkey, contentSource);
    if (StringUtil.isBlank(content)) {
      return null;
    }

    return Event(pubkey, EventKind.followSets, tags, content!);
  }

  List<Contact> get publicContacts {
    return _publicContacts.values.toList();
  }

  List<Contact> get privateContacts {
    return _privateContacts.values.toList();
  }

  String displayName() {
    if (StringUtil.isNotBlank(title)) {
      return title!;
    }

    return dTag;
  }

  void addPrivate(Contact contact) {
    _privateContacts[contact.publicKey] = contact;
  }

  void addPublic(Contact contact) {
    _publicContacts[contact.publicKey] = contact;
  }

  void removePrivate(String pubkey) {
    _privateContacts.remove(pubkey);
  }

  void removePublic(String pubkey) {
    _publicContacts.remove(pubkey);
  }

  bool privateFollow(String pubkey) {
    return _privateContacts[pubkey] != null;
  }

  bool publicFollow(String pubkey) {
    return _publicContacts[pubkey] != null;
  }
}
