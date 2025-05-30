import 'dart:async';
import 'dart:developer';

import 'event.dart';
import 'event_kind.dart';
import 'event_mem_box.dart';
import 'nip02/contact_list.dart';
import 'relay/event_filter.dart';
import 'relay/relay.dart';
import 'relay/relay_pool.dart';
import 'relay/relay_type.dart';
import 'signer/nostr_signer.dart';
import 'signer/pubkey_only_nostr_signer.dart';
import 'utils/string_util.dart';

class Nostr {
  late RelayPool _pool;

  NostrSigner nostrSigner;

  final String _publicKey;

  Function(String, String)? onNotice;

  Relay Function(String) tempRelayGener;

  Nostr(this.nostrSigner, this._publicKey, List<EventFilter> eventFilters,
      this.tempRelayGener,
      {this.onNotice}) {
    _pool = RelayPool(this, eventFilters, tempRelayGener, onNotice: onNotice);
  }

  String get publicKey => _publicKey;

  Future<Event?> sendLike(String id,
      {String? pubkey,
      String? content,
      List<String>? tempRelays,
      List<String>? targetRelays}) async {
    content ??= "+";

    Event event = Event(
        _publicKey,
        EventKind.reaction,
        [
          ["e", id]
        ],
        content);
    return await sendEvent(event,
        tempRelays: tempRelays, targetRelays: targetRelays);
  }

  Future<Event?> deleteEvent(String eventId,
      {List<String>? tempRelays, List<String>? targetRelays}) async {
    Event event = Event(
        _publicKey,
        EventKind.eventDeletion,
        [
          ["e", eventId]
        ],
        "delete");
    return await sendEvent(event,
        tempRelays: tempRelays, targetRelays: targetRelays);
  }

  Future<Event?> deleteEvents(List<String> eventIds,
      {List<String>? tempRelays, List<String>? targetRelays}) async {
    List<List<dynamic>> tags = [];
    for (var eventId in eventIds) {
      tags.add(["e", eventId]);
    }

    Event event = Event(_publicKey, EventKind.eventDeletion, tags, "delete");
    return await sendEvent(event,
        tempRelays: tempRelays, targetRelays: targetRelays);
  }

  Future<Event?> sendRepost(String id,
      {String? relayAddr,
      String content = "",
      List<String>? tempRelays,
      List<String>? targetRelays}) async {
    List<dynamic> tag = ["e", id];
    if (StringUtil.isNotBlank(relayAddr)) {
      tag.add(relayAddr);
    }
    Event event = Event(_publicKey, EventKind.repost, [tag], content);
    return await sendEvent(event,
        tempRelays: tempRelays, targetRelays: targetRelays);
  }

  Future<Event?> sendContactList(ContactList contacts, String content,
      {List<String>? tempRelays, List<String>? targetRelays}) async {
    final tags = contacts.toJson();
    final event = Event(_publicKey, EventKind.contactList, tags, content);
    return await sendEvent(event,
        tempRelays: tempRelays, targetRelays: targetRelays);
  }

  /// Publishes the given Event to some relays.
  ///
  /// [event] The Event to publish.
  /// [tempRelays] Optional list of relays to publish this event to regardless
  /// of the user's relay set. If you set this you may also want to set
  /// `targetRelays` to the same value.
  /// [targetRelays] Optional list that, if provided, will limit the publishing
  /// of the event to the intersection of `targetRelays` and the user's relay
  /// set. If this argument is empty or ommitted the event will be published to
  /// all the relays in the user's relay set in addition to the `tempRelays`.
  Future<Event?> sendEvent(Event event,
      {List<String>? tempRelays, List<String>? targetRelays}) async {
    await signEvent(event);
    if (StringUtil.isBlank(event.sig)) {
      return null;
    }

    var result = _pool.send(
      ["EVENT", event.toJson()],
      tempRelays: tempRelays,
      targetRelays: targetRelays,
    );
    if (result) {
      return event;
    }
    return null;
  }

  void checkEventSign(Event event) {
    if (StringUtil.isBlank(event.sig)) {
      throw StateError("Event is not signed");
    }
  }

  Future<void> signEvent(Event event) async {
    var ne = await nostrSigner.signEvent(event);
    if (ne != null) {
      event.id = ne.id;
      event.sig = ne.sig;
    }
  }

  Event? broadcast(Event event,
      {List<String>? tempRelays, List<String>? targetRelays}) {
    var result = _pool.send(
      ["EVENT", event.toJson()],
      tempRelays: tempRelays,
      targetRelays: targetRelays,
    );
    if (result) {
      return event;
    }
    return null;
  }

  void close() {
    _pool.removeAll();
  }

  void addInitQuery(List<Map<String, dynamic>> filters, Function(Event) onEvent,
      {String? id, Function? onComplete}) {
    _pool.addInitQuery(filters, onEvent, id: id, onComplete: onComplete);
  }

  /// Checks if a temporary relay has any active subscriptions
  ///
  /// [relayAddr] The relay address to check
  /// Returns true if the relay has active subscriptions.
  bool tempRelayHasSubscription(String relayAddr) {
    return _pool.tempRelayHasSubscription(relayAddr);
  }

  /// Subscribes to events matching the given filters.
  ///
  /// Parameters:
  /// - [filters] The event filters to match against.
  /// - [onEvent] Callback function when matching events are received.
  /// - [id] Optional subscription identifier
  /// - [tempRelays] Optional list of temporary relays used for one-off operations. These relays
  ///   are created for specific queries and discarded after use, unlike the main relay pool.
  /// - [targetRelays] Optional list of specific relays chosen from your configured relay set
  ///   to handle this particular subscription.
  /// - [relayTypes] Types of relays to use.
  /// - [sendAfterAuth] Whether to wait for relay authentication before subscribing.
  ///
  /// Returns the subscription ID that can be used to unsubscribe later
  // still need to Rename relay parameters globally for clarity:
  //  - tempRelays
  //  - targetRelays
  String subscribe(
    List<Map<String, dynamic>> filters,
    Function(Event) onEvent, {
    String? id,
    List<String>? tempRelays,
    List<String>? targetRelays,
    List<int> relayTypes = RelayType.all,
    bool sendAfterAuth = false,
  }) {
    return _pool.subscribe(
      filters,
      onEvent,
      id: id,
      tempRelays: tempRelays,
      targetRelays: targetRelays,
      relayTypes: relayTypes,
      sendAfterAuth: sendAfterAuth,
    );
  }

  void unsubscribe(String id) {
    _pool.unsubscribe(id);
  }

  /// Queries the relays with the specified filters and parameters.
  ///
  /// This method allows you to query a pool of relays using a set of filters
  /// and get a list of received events as a result.
  ///
  /// - [filters]: A list of maps containing the filters to apply to the query.
  /// - [id]: (Optional) A unique identifier for the query.
  /// - [tempRelays]: (Optional) A list of temporary relays to use for the
  /// query.
  /// - [targetRelays]: (Optional) A list of target relays to focus the query
  /// on.
  /// - [relayTypes]: A list of relay types to configure which kind of relays
  /// are queried. Defaults to [RelayType.all].
  /// - [sendAfterAuth]: A boolean indicating whether to wait for authentication
  /// before sending the query. Defaults to `false`.
  ///
  /// Returns a list of received events.
  Future<List<Event>> queryEvents(
    List<Map<String, dynamic>> filters, {
    String? id,
    List<String>? tempRelays,
    List<String>? targetRelays,
    List<int> relayTypes = RelayType.all,
    bool sendAfterAuth = false,
  }) async {
    var eventBox = EventMemBox(sortAfterAdd: false);
    var completer = Completer();
    query(
      filters,
      id: id,
      tempRelays: tempRelays,
      targetRelays: targetRelays,
      relayTypes: relayTypes,
      sendAfterAuth: sendAfterAuth,
      (event) => eventBox.add(event),
      onComplete: () => completer.complete(),
    );
    await completer.future;
    return eventBox.all();
  }

  /// Queries the relays with the specified filters and parameters.
  ///
  /// This method allows you to query a pool of relays using a set of filters
  /// and handle events as they are received.
  ///
  /// - [filters]: A list of maps containing the filters to apply to the query.
  /// - [onEvent]: A callback function that is triggered for each event
  /// received.
  /// - [id]: (Optional) A unique identifier for the query.
  /// - [onComplete]: (Optional) A callback function that is triggered when the
  /// query is complete.
  /// - [tempRelays]: (Optional) A list of temporary relays to use for the
  /// query.
  /// - [targetRelays]: (Optional) A list of target relays to focus the query
  /// on.
  /// - [relayTypes]: A list of relay types to configure which kind of relays
  /// are queried. Defaults to [RelayType.all].
  /// - [sendAfterAuth]: A boolean indicating whether to wait for authentication
  /// before sending the query. Defaults to `false`.
  ///
  /// Returns the subscription ID.
  String query(
    List<Map<String, dynamic>> filters,
    Function(Event) onEvent, {
    String? id,
    Function? onComplete,
    List<String>? tempRelays,
    List<String>? targetRelays,
    List<int> relayTypes = RelayType.all,
    bool sendAfterAuth = false,
  }) {
    return _pool.query(
      filters,
      onEvent,
      id: id,
      onComplete: onComplete,
      tempRelays: tempRelays,
      targetRelays: targetRelays,
      relayTypes: relayTypes,
      sendAfterAuth: sendAfterAuth,
    );
  }

  String queryByFilters(Map<String, List<Map<String, dynamic>>> filtersMap,
      Function(Event) onEvent,
      {String? id, Function? onComplete}) {
    return _pool.queryByFilters(filtersMap, onEvent,
        id: id, onComplete: onComplete);
  }

  Future<bool> addRelay(
    Relay relay, {
    bool autoSubscribe = false,
    bool init = false,
    int relayType = RelayType.normal,
  }) async {
    return await _pool.add(relay,
        autoSubscribe: autoSubscribe, init: init, relayType: relayType);
  }

  void removeRelay(String url, {int relayType = RelayType.normal}) {
    _pool.remove(url, relayType: relayType);
  }

  List<Relay> activeRelays() {
    return _pool.activeRelays();
  }

  Relay? getRelay(String url) {
    return _pool.getRelay(url);
  }

  Relay? getTempRelay(String url) {
    return _pool.getTempRelay(url);
  }

  void reconnect() {
    log("nostr reconnect");
    _pool.reconnect();
  }

  List<String> getExtralReadableRelays(
      List<String> extraRelays, int maxRelayNum) {
    return _pool.getExtralReadableRelays(extraRelays, maxRelayNum);
  }

  void removeTempRelay(String addr) {
    _pool.removeTempRelay(addr);
  }

  bool readable() {
    return _pool.readable();
  }

  bool writable() {
    return _pool.writable();
  }

  bool isReadOnly() {
    return nostrSigner is PubkeyOnlyNostrSigner;
  }
}
