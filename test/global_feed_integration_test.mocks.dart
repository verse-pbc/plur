// Mocks generated by Mockito 5.4.4 from annotations
// in nostrmo/test/global_feed_integration_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i7;
import 'dart:ui' as _i11;

import 'package:flutter/material.dart' as _i9;
import 'package:mockito/mockito.dart' as _i1;
import 'package:mockito/src/dummies.dart' as _i4;
import 'package:nostr_sdk/nostr_sdk.dart' as _i2;
import 'package:nostrmo/data/custom_emoji.dart' as _i5;
import 'package:nostrmo/data/join_group_parameters.dart' as _i8;
import 'package:nostrmo/data/public_group_info.dart' as _i10;
import 'package:nostrmo/generated/l10n.dart' as _i6;
import 'package:nostrmo/provider/list_provider.dart' as _i3;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeBookmarks_0 extends _i1.SmartFake implements _i2.Bookmarks {
  _FakeBookmarks_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeNostrSigner_1 extends _i1.SmartFake implements _i2.NostrSigner {
  _FakeNostrSigner_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeRelay_2 extends _i1.SmartFake implements _i2.Relay {
  _FakeRelay_2(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [ListProvider].
///
/// See the documentation for Mockito's code generation for more information.
class MockListProvider extends _i1.Mock implements _i3.ListProvider {
  MockListProvider() {
    _i1.throwOnMissingStub(this);
  }

  @override
  String get emojiKey => (super.noSuchMethod(
        Invocation.getter(#emojiKey),
        returnValue: _i4.dummyValue<String>(
          this,
          Invocation.getter(#emojiKey),
        ),
      ) as String);

  @override
  String get bookmarksKey => (super.noSuchMethod(
        Invocation.getter(#bookmarksKey),
        returnValue: _i4.dummyValue<String>(
          this,
          Invocation.getter(#bookmarksKey),
        ),
      ) as String);

  @override
  List<_i2.GroupIdentifier> get groupIdentifiers => (super.noSuchMethod(
        Invocation.getter(#groupIdentifiers),
        returnValue: <_i2.GroupIdentifier>[],
      ) as List<_i2.GroupIdentifier>);

  @override
  bool get hasListeners => (super.noSuchMethod(
        Invocation.getter(#hasListeners),
        returnValue: false,
      ) as bool);

  @override
  bool privateBookmarkContains(String? eventId) => (super.noSuchMethod(
        Invocation.method(
          #privateBookmarkContains,
          [eventId],
        ),
        returnValue: false,
      ) as bool);

  @override
  bool publicBookmarkContains(String? eventId) => (super.noSuchMethod(
        Invocation.method(
          #publicBookmarkContains,
          [eventId],
        ),
        returnValue: false,
      ) as bool);

  @override
  void load(
    String? pubkey,
    List<int>? kinds, {
    _i2.Nostr? targetNostr,
    bool? initQuery = false,
  }) =>
      super.noSuchMethod(
        Invocation.method(
          #load,
          [
            pubkey,
            kinds,
          ],
          {
            #targetNostr: targetNostr,
            #initQuery: initQuery,
          },
        ),
        returnValueForMissingStub: null,
      );

  @override
  void onEvent(_i2.Event? event) => super.noSuchMethod(
        Invocation.method(
          #onEvent,
          [event],
        ),
        returnValueForMissingStub: null,
      );

  @override
  List<MapEntry<String, List<_i5.CustomEmoji>>> emojis(
    _i6.S? localization,
    _i2.Event? emojiEvent,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #emojis,
          [
            localization,
            emojiEvent,
          ],
        ),
        returnValue: <MapEntry<String, List<_i5.CustomEmoji>>>[],
      ) as List<MapEntry<String, List<_i5.CustomEmoji>>>);

  @override
  void addCustomEmoji(_i5.CustomEmoji? emoji) => super.noSuchMethod(
        Invocation.method(
          #addCustomEmoji,
          [emoji],
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i2.Bookmarks getBookmarks() => (super.noSuchMethod(
        Invocation.method(
          #getBookmarks,
          [],
        ),
        returnValue: _FakeBookmarks_0(
          this,
          Invocation.method(
            #getBookmarks,
            [],
          ),
        ),
      ) as _i2.Bookmarks);

  @override
  _i7.Future<_i2.Bookmarks?> parseBookmarks() => (super.noSuchMethod(
        Invocation.method(
          #parseBookmarks,
          [],
        ),
        returnValue: _i7.Future<_i2.Bookmarks?>.value(),
      ) as _i7.Future<_i2.Bookmarks?>);

  @override
  void addPrivateBookmark(_i2.BookmarkItem? bookmarkItem) => super.noSuchMethod(
        Invocation.method(
          #addPrivateBookmark,
          [bookmarkItem],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void addPublicBookmark(_i2.BookmarkItem? bookmarkItem) => super.noSuchMethod(
        Invocation.method(
          #addPublicBookmark,
          [bookmarkItem],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void removePrivateBookmark(String? value) => super.noSuchMethod(
        Invocation.method(
          #removePrivateBookmark,
          [value],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void removePublicBookmark(String? value) => super.noSuchMethod(
        Invocation.method(
          #removePublicBookmark,
          [value],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void saveBookmarks(_i2.Bookmarks? bookmarks) => super.noSuchMethod(
        Invocation.method(
          #saveBookmarks,
          [bookmarks],
        ),
        returnValueForMissingStub: null,
      );

  @override
  bool checkPublicBookmark(_i2.BookmarkItem? item) => (super.noSuchMethod(
        Invocation.method(
          #checkPublicBookmark,
          [item],
        ),
        returnValue: false,
      ) as bool);

  @override
  bool checkPrivateBookmark(_i2.BookmarkItem? item) => (super.noSuchMethod(
        Invocation.method(
          #checkPrivateBookmark,
          [item],
        ),
        returnValue: false,
      ) as bool);

  @override
  void joinGroup(
    _i8.JoinGroupParameters? request, {
    _i9.BuildContext? context,
  }) =>
      super.noSuchMethod(
        Invocation.method(
          #joinGroup,
          [request],
          {#context: context},
        ),
        returnValueForMissingStub: null,
      );

  @override
  bool isGroupMember(_i8.JoinGroupParameters? request) => (super.noSuchMethod(
        Invocation.method(
          #isGroupMember,
          [request],
        ),
        returnValue: false,
      ) as bool);

  @override
  void joinGroups(
    List<_i8.JoinGroupParameters>? requests, {
    _i9.BuildContext? context,
  }) =>
      super.noSuchMethod(
        Invocation.method(
          #joinGroups,
          [requests],
          {#context: context},
        ),
        returnValueForMissingStub: null,
      );

  @override
  void leaveGroup(_i2.GroupIdentifier? gi) => super.noSuchMethod(
        Invocation.method(
          #leaveGroup,
          [gi],
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i7.Future<(String?, _i2.GroupIdentifier?)> createGroupAndGenerateInvite(
          String? groupName) =>
      (super.noSuchMethod(
        Invocation.method(
          #createGroupAndGenerateInvite,
          [groupName],
        ),
        returnValue:
            _i7.Future<(String?, _i2.GroupIdentifier?)>.value((null, null)),
      ) as _i7.Future<(String?, _i2.GroupIdentifier?)>);

  @override
  String createInviteLink(
    _i2.GroupIdentifier? group,
    String? inviteCode, {
    List<String>? roles,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #createInviteLink,
          [
            group,
            inviteCode,
          ],
          {#roles: roles},
        ),
        returnValue: _i4.dummyValue<String>(
          this,
          Invocation.method(
            #createInviteLink,
            [
              group,
              inviteCode,
            ],
            {#roles: roles},
          ),
        ),
      ) as String);

  @override
  void clear() => super.noSuchMethod(
        Invocation.method(
          #clear,
          [],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void handleGroupDeleteEvent(_i2.Event? event) => super.noSuchMethod(
        Invocation.method(
          #handleGroupDeleteEvent,
          [event],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void handleAdminMembershipEvent(_i2.Event? event) => super.noSuchMethod(
        Invocation.method(
          #handleAdminMembershipEvent,
          [event],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void handleEditMetadataEvent(_i2.Event? event) => super.noSuchMethod(
        Invocation.method(
          #handleEditMetadataEvent,
          [event],
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i7.Future<List<_i10.PublicGroupInfo>> queryPublicGroups(
          List<String>? relays) =>
      (super.noSuchMethod(
        Invocation.method(
          #queryPublicGroups,
          [relays],
        ),
        returnValue: _i7.Future<List<_i10.PublicGroupInfo>>.value(
            <_i10.PublicGroupInfo>[]),
      ) as _i7.Future<List<_i10.PublicGroupInfo>>);

  @override
  void addListener(_i11.VoidCallback? listener) => super.noSuchMethod(
        Invocation.method(
          #addListener,
          [listener],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void removeListener(_i11.VoidCallback? listener) => super.noSuchMethod(
        Invocation.method(
          #removeListener,
          [listener],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void dispose() => super.noSuchMethod(
        Invocation.method(
          #dispose,
          [],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void notifyListeners() => super.noSuchMethod(
        Invocation.method(
          #notifyListeners,
          [],
        ),
        returnValueForMissingStub: null,
      );
}

/// A class which mocks [Nostr].
///
/// See the documentation for Mockito's code generation for more information.
class MockNostr extends _i1.Mock implements _i2.Nostr {
  MockNostr() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i2.NostrSigner get nostrSigner => (super.noSuchMethod(
        Invocation.getter(#nostrSigner),
        returnValue: _FakeNostrSigner_1(
          this,
          Invocation.getter(#nostrSigner),
        ),
      ) as _i2.NostrSigner);

  @override
  set nostrSigner(_i2.NostrSigner? _nostrSigner) => super.noSuchMethod(
        Invocation.setter(
          #nostrSigner,
          _nostrSigner,
        ),
        returnValueForMissingStub: null,
      );

  @override
  set onNotice(
          dynamic Function(
            String,
            String,
          )? _onNotice) =>
      super.noSuchMethod(
        Invocation.setter(
          #onNotice,
          _onNotice,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i2.Relay Function(String) get tempRelayGener => (super.noSuchMethod(
        Invocation.getter(#tempRelayGener),
        returnValue: (String __p0) => _FakeRelay_2(
          this,
          Invocation.getter(#tempRelayGener),
        ),
      ) as _i2.Relay Function(String));

  @override
  set tempRelayGener(_i2.Relay Function(String)? _tempRelayGener) =>
      super.noSuchMethod(
        Invocation.setter(
          #tempRelayGener,
          _tempRelayGener,
        ),
        returnValueForMissingStub: null,
      );

  @override
  String get publicKey => (super.noSuchMethod(
        Invocation.getter(#publicKey),
        returnValue: _i4.dummyValue<String>(
          this,
          Invocation.getter(#publicKey),
        ),
      ) as String);

  @override
  _i7.Future<_i2.Event?> sendLike(
    String? id, {
    String? pubkey,
    String? content,
    List<String>? tempRelays,
    List<String>? targetRelays,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #sendLike,
          [id],
          {
            #pubkey: pubkey,
            #content: content,
            #tempRelays: tempRelays,
            #targetRelays: targetRelays,
          },
        ),
        returnValue: _i7.Future<_i2.Event?>.value(),
      ) as _i7.Future<_i2.Event?>);

  @override
  _i7.Future<_i2.Event?> deleteEvent(
    String? eventId, {
    List<String>? tempRelays,
    List<String>? targetRelays,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #deleteEvent,
          [eventId],
          {
            #tempRelays: tempRelays,
            #targetRelays: targetRelays,
          },
        ),
        returnValue: _i7.Future<_i2.Event?>.value(),
      ) as _i7.Future<_i2.Event?>);

  @override
  _i7.Future<_i2.Event?> deleteEvents(
    List<String>? eventIds, {
    List<String>? tempRelays,
    List<String>? targetRelays,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #deleteEvents,
          [eventIds],
          {
            #tempRelays: tempRelays,
            #targetRelays: targetRelays,
          },
        ),
        returnValue: _i7.Future<_i2.Event?>.value(),
      ) as _i7.Future<_i2.Event?>);

  @override
  _i7.Future<_i2.Event?> sendRepost(
    String? id, {
    String? relayAddr,
    String? content = r'',
    List<String>? tempRelays,
    List<String>? targetRelays,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #sendRepost,
          [id],
          {
            #relayAddr: relayAddr,
            #content: content,
            #tempRelays: tempRelays,
            #targetRelays: targetRelays,
          },
        ),
        returnValue: _i7.Future<_i2.Event?>.value(),
      ) as _i7.Future<_i2.Event?>);

  @override
  _i7.Future<_i2.Event?> sendContactList(
    _i2.ContactList? contacts,
    String? content, {
    List<String>? tempRelays,
    List<String>? targetRelays,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #sendContactList,
          [
            contacts,
            content,
          ],
          {
            #tempRelays: tempRelays,
            #targetRelays: targetRelays,
          },
        ),
        returnValue: _i7.Future<_i2.Event?>.value(),
      ) as _i7.Future<_i2.Event?>);

  @override
  _i7.Future<_i2.Event?> sendEvent(
    _i2.Event? event, {
    List<String>? tempRelays,
    List<String>? targetRelays,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #sendEvent,
          [event],
          {
            #tempRelays: tempRelays,
            #targetRelays: targetRelays,
          },
        ),
        returnValue: _i7.Future<_i2.Event?>.value(),
      ) as _i7.Future<_i2.Event?>);

  @override
  void checkEventSign(_i2.Event? event) => super.noSuchMethod(
        Invocation.method(
          #checkEventSign,
          [event],
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i7.Future<void> signEvent(_i2.Event? event) => (super.noSuchMethod(
        Invocation.method(
          #signEvent,
          [event],
        ),
        returnValue: _i7.Future<void>.value(),
        returnValueForMissingStub: _i7.Future<void>.value(),
      ) as _i7.Future<void>);

  @override
  _i2.Event? broadcase(
    _i2.Event? event, {
    List<String>? tempRelays,
    List<String>? targetRelays,
  }) =>
      (super.noSuchMethod(Invocation.method(
        #broadcase,
        [event],
        {
          #tempRelays: tempRelays,
          #targetRelays: targetRelays,
        },
      )) as _i2.Event?);

  @override
  void close() => super.noSuchMethod(
        Invocation.method(
          #close,
          [],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void addInitQuery(
    List<Map<String, dynamic>>? filters,
    dynamic Function(_i2.Event)? onEvent, {
    String? id,
    Function? onComplete,
  }) =>
      super.noSuchMethod(
        Invocation.method(
          #addInitQuery,
          [
            filters,
            onEvent,
          ],
          {
            #id: id,
            #onComplete: onComplete,
          },
        ),
        returnValueForMissingStub: null,
      );

  @override
  bool tempRelayHasSubscription(String? relayAddr) => (super.noSuchMethod(
        Invocation.method(
          #tempRelayHasSubscription,
          [relayAddr],
        ),
        returnValue: false,
      ) as bool);

  @override
  String subscribe(
    List<Map<String, dynamic>>? filters,
    dynamic Function(_i2.Event)? onEvent, {
    String? id,
    List<String>? tempRelays,
    List<String>? targetRelays,
    List<int>? relayTypes = const [
      1,
      2,
      3,
      4,
    ],
    bool? sendAfterAuth = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #subscribe,
          [
            filters,
            onEvent,
          ],
          {
            #id: id,
            #tempRelays: tempRelays,
            #targetRelays: targetRelays,
            #relayTypes: relayTypes,
            #sendAfterAuth: sendAfterAuth,
          },
        ),
        returnValue: _i4.dummyValue<String>(
          this,
          Invocation.method(
            #subscribe,
            [
              filters,
              onEvent,
            ],
            {
              #id: id,
              #tempRelays: tempRelays,
              #targetRelays: targetRelays,
              #relayTypes: relayTypes,
              #sendAfterAuth: sendAfterAuth,
            },
          ),
        ),
      ) as String);

  @override
  void unsubscribe(String? id) => super.noSuchMethod(
        Invocation.method(
          #unsubscribe,
          [id],
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i7.Future<List<_i2.Event>> queryEvents(
    List<Map<String, dynamic>>? filters, {
    String? id,
    List<String>? tempRelays,
    List<String>? targetRelays,
    List<int>? relayTypes = const [
      1,
      2,
      3,
      4,
    ],
    bool? sendAfterAuth = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #queryEvents,
          [filters],
          {
            #id: id,
            #tempRelays: tempRelays,
            #targetRelays: targetRelays,
            #relayTypes: relayTypes,
            #sendAfterAuth: sendAfterAuth,
          },
        ),
        returnValue: _i7.Future<List<_i2.Event>>.value(<_i2.Event>[]),
      ) as _i7.Future<List<_i2.Event>>);

  @override
  String query(
    List<Map<String, dynamic>>? filters,
    dynamic Function(_i2.Event)? onEvent, {
    String? id,
    Function? onComplete,
    List<String>? tempRelays,
    List<String>? targetRelays,
    List<int>? relayTypes = const [
      1,
      2,
      3,
      4,
    ],
    bool? sendAfterAuth = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #query,
          [
            filters,
            onEvent,
          ],
          {
            #id: id,
            #onComplete: onComplete,
            #tempRelays: tempRelays,
            #targetRelays: targetRelays,
            #relayTypes: relayTypes,
            #sendAfterAuth: sendAfterAuth,
          },
        ),
        returnValue: _i4.dummyValue<String>(
          this,
          Invocation.method(
            #query,
            [
              filters,
              onEvent,
            ],
            {
              #id: id,
              #onComplete: onComplete,
              #tempRelays: tempRelays,
              #targetRelays: targetRelays,
              #relayTypes: relayTypes,
              #sendAfterAuth: sendAfterAuth,
            },
          ),
        ),
      ) as String);

  @override
  String queryByFilters(
    Map<String, List<Map<String, dynamic>>>? filtersMap,
    dynamic Function(_i2.Event)? onEvent, {
    String? id,
    Function? onComplete,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #queryByFilters,
          [
            filtersMap,
            onEvent,
          ],
          {
            #id: id,
            #onComplete: onComplete,
          },
        ),
        returnValue: _i4.dummyValue<String>(
          this,
          Invocation.method(
            #queryByFilters,
            [
              filtersMap,
              onEvent,
            ],
            {
              #id: id,
              #onComplete: onComplete,
            },
          ),
        ),
      ) as String);

  @override
  _i7.Future<bool> addRelay(
    _i2.Relay? relay, {
    bool? autoSubscribe = false,
    bool? init = false,
    int? relayType = 1,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #addRelay,
          [relay],
          {
            #autoSubscribe: autoSubscribe,
            #init: init,
            #relayType: relayType,
          },
        ),
        returnValue: _i7.Future<bool>.value(false),
      ) as _i7.Future<bool>);

  @override
  void removeRelay(
    String? url, {
    int? relayType = 1,
  }) =>
      super.noSuchMethod(
        Invocation.method(
          #removeRelay,
          [url],
          {#relayType: relayType},
        ),
        returnValueForMissingStub: null,
      );

  @override
  List<_i2.Relay> activeRelays() => (super.noSuchMethod(
        Invocation.method(
          #activeRelays,
          [],
        ),
        returnValue: <_i2.Relay>[],
      ) as List<_i2.Relay>);

  @override
  _i2.Relay? getRelay(String? url) => (super.noSuchMethod(Invocation.method(
        #getRelay,
        [url],
      )) as _i2.Relay?);

  @override
  _i2.Relay? getTempRelay(String? url) => (super.noSuchMethod(Invocation.method(
        #getTempRelay,
        [url],
      )) as _i2.Relay?);

  @override
  void reconnect() => super.noSuchMethod(
        Invocation.method(
          #reconnect,
          [],
        ),
        returnValueForMissingStub: null,
      );

  @override
  List<String> getExtralReadableRelays(
    List<String>? extraRelays,
    int? maxRelayNum,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #getExtralReadableRelays,
          [
            extraRelays,
            maxRelayNum,
          ],
        ),
        returnValue: <String>[],
      ) as List<String>);

  @override
  void removeTempRelay(String? addr) => super.noSuchMethod(
        Invocation.method(
          #removeTempRelay,
          [addr],
        ),
        returnValueForMissingStub: null,
      );

  @override
  bool readable() => (super.noSuchMethod(
        Invocation.method(
          #readable,
          [],
        ),
        returnValue: false,
      ) as bool);

  @override
  bool writable() => (super.noSuchMethod(
        Invocation.method(
          #writable,
          [],
        ),
        returnValue: false,
      ) as bool);

  @override
  bool isReadOnly() => (super.noSuchMethod(
        Invocation.method(
          #isReadOnly,
          [],
        ),
        returnValue: false,
      ) as bool);
}
