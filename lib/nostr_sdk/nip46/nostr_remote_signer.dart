import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:sentry_flutter/sentry_flutter.dart';

import '../nip19/nip19.dart';
import '../relay/client_connected.dart';
import '../event.dart';
import '../event_kind.dart';
import '../filter.dart';
import '../relay/relay.dart';
import '../relay/relay_base.dart';
import '../relay/relay_isolate.dart';
import '../relay/relay_mode.dart';
import '../relay/relay_status.dart';
import '../signer/local_nostr_signer.dart';
import '../signer/nostr_signer.dart';
import '../utils/string_util.dart';
import 'nostr_remote_request.dart';
import 'nostr_remote_response.dart';
import 'nostr_remote_signer_info.dart';

class NostrRemoteSigner extends NostrSigner {
  /// The mode of the relay, either base or isolate.
  int relayMode;

  /// Information about the remote signer.
  NostrRemoteSignerInfo info;

  /// An instance of [LocalNostrSigner] for local signing operations.
  late LocalNostrSigner localNostrSigner;

  /// The list of [Relay] objects this signer is connected to.
  List<Relay> relays = [];

  /// A map of request callbacks.
  Map<String, Completer<String?>> callbacks = {};

  /// Remote signer public key tags.
  List<String>? _remotePubkeyTags;

  /// Constructs a [NostrRemoteSigner] with the specified relay mode and signer
  /// info.
  NostrRemoteSigner(
    this.relayMode,
    this.info,
  );

  /// Connects to the remote relays.
  /// If [sendConnectRequest] is true, it sends a connection request.
  Future<void> connect({bool sendConnectRequest = true}) async {
    if (StringUtil.isBlank(info.nsec)) {
      return;
    }

    localNostrSigner = LocalNostrSigner(Nip19.decode(info.nsec!));

    for (var remoteRelayAddr in info.relays) {
      var relay = await _connectToRelay(remoteRelayAddr);
      relays.add(relay);
    }

    if (sendConnectRequest) {
      var request = NostrRemoteRequest("connect", [
        info.remoteSignerPubkey,
        info.optionalSecret ?? "",
        "sign_event,get_relays,get_public_key,nip04_encrypt,nip04_decrypt,nip44_encrypt,nip44_decrypt"
      ]);
      await sendAndWaitForResult(request, timeout: 120);
    }
  }

  /// Pulls the public key from the remote signer.
  Future<String?> pullPubkey() async {
    var request = NostrRemoteRequest("get_public_key", []);
    var pubkey = await sendAndWaitForResult(request, timeout: 120);
    info.userPubkey = pubkey;
    return pubkey;
  }

  /// Handles incoming messages from the relay.
  Future<void> onMessage(Relay relay, List<dynamic> json) async {
    final messageType = json[0];
    if (messageType == 'EVENT') {
      try {
        relay.relayStatus.noteReceive();

        final event = Event.fromJson(json[2]);
        if (event.kind == EventKind.NOSTR_REMOTE_SIGNING) {
          var response = await NostrRemoteResponse.decrypt(
              event.content, localNostrSigner, event.pubkey);
          if (response != null) {
            var completer = callbacks.remove(response.id);
            if (completer != null) {
              completer.complete(response.result);
            }
          }
        }
      } catch (exception, stackTrace) {
        await Sentry.captureException(exception, stackTrace: stackTrace);
      }
    }
  }

  /// Connects to a relay based on the specified address.
  Future<Relay> _connectToRelay(String relayAddr) async {
    RelayStatus relayStatus = RelayStatus(relayAddr);
    Relay? relay;
    if (relayMode == RelayMode.BASE_MODE) {
      relay = RelayBase(
        relayAddr,
        relayStatus,
      );
    } else {
      relay = RelayIsolate(
        relayAddr,
        relayStatus,
      );
    }
    relay.onMessage = onMessage;
    addPenddingQueryMsg(relay);
    relay.relayStatusCallback = () {
      if (relayStatus.connected == ClientConneccted.UN_CONNECT) {
        if (relay!.pendingMessages.isEmpty) {
          addPenddingQueryMsg(relay);
        }
      }
    };

    await relay.connect();

    return relay;
  }

  /// Adds a pending query message to the relay.
  Future<void> addPenddingQueryMsg(Relay relay) async {
    // add a query event
    var queryMsg = await genQueryMsg();
    if (queryMsg != null) {
      relay.pendingMessages.add(queryMsg);
    }
  }

  /// Generates a query message.
  Future<List?> genQueryMsg() async {
    var pubkey = await localNostrSigner.getPublicKey();
    if (pubkey == null) {
      return null;
    }
    var filter = Filter(
      since: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      p: [pubkey],
      kinds: [EventKind.NOSTR_REMOTE_SIGNING],
    );
    List<dynamic> queryMsg = ["REQ", StringUtil.rndNameStr(12)];
    queryMsg.add(filter.toJson());

    return queryMsg;
  }

  /// Sends a request and waits for the result.
  Future<String?> sendAndWaitForResult(NostrRemoteRequest request,
      {int timeout = 60}) async {
    var senderPubkey = await localNostrSigner.getPublicKey();
    var content =
        await request.encrypt(localNostrSigner, info.remoteSignerPubkey);
    if (StringUtil.isNotBlank(senderPubkey) && content != null) {
      Event? event = Event(senderPubkey!, EventKind.NOSTR_REMOTE_SIGNING,
          [getRemoteSignerPubkeyTags()], content);
      event = await localNostrSigner.signEvent(event);
      if (event != null) {
        var json = ["EVENT", event.toJson()];

        var completer = Completer<String?>();
        callbacks[request.id] = completer;

        for (var relay in relays) {
          relay.send(json, forceSend: true);
        }

        return await completer.future.timeout(Duration(seconds: timeout),
            onTimeout: () {
          return null;
        });
      }
    }
    return null;
  }

  @override
  Future<String?> decrypt(pubkey, ciphertext) async {
    var request = NostrRemoteRequest("nip04_decrypt", [pubkey, ciphertext]);
    return await sendAndWaitForResult(request);
  }

  @override
  Future<String?> encrypt(pubkey, plaintext) async {
    var request = NostrRemoteRequest("nip04_encrypt", [pubkey, plaintext]);
    return await sendAndWaitForResult(request);
  }

  @override
  Future<String?> getPublicKey() async {
    return info.userPubkey;
  }

  @override
  Future<Map?> getRelays() async {
    var request = NostrRemoteRequest("get_relays", []);
    var result = await sendAndWaitForResult(request);
    if (StringUtil.isNotBlank(result)) {
      return jsonDecode(result!);
    }
    return null;
  }

  @override
  Future<String?> nip44Decrypt(pubkey, ciphertext) async {
    var request = NostrRemoteRequest("nip44_decrypt", [pubkey, ciphertext]);
    return await sendAndWaitForResult(request);
  }

  @override
  Future<String?> nip44Encrypt(pubkey, plaintext) async {
    var request = NostrRemoteRequest("nip44_encrypt", [pubkey, plaintext]);
    return await sendAndWaitForResult(request);
  }

  @override
  Future<Event?> signEvent(Event event) async {
    var eventJsonMap = event.toJson();
    eventJsonMap.remove("id");
    eventJsonMap.remove("pubkey");
    eventJsonMap.remove("sig");
    var eventJsonText = jsonEncode(eventJsonMap);
    var request = NostrRemoteRequest("sign_event", [eventJsonText]);
    var result = await sendAndWaitForResult(request);
    if (StringUtil.isNotBlank(result)) {
      var eventMap = jsonDecode(result!);
      return Event.fromJson(eventMap);
    }

    return null;
  }

  /// Returns the remote signer public key tags.
  List<String> getRemoteSignerPubkeyTags() {
    _remotePubkeyTags ??= ["p", info.remoteSignerPubkey];
    return _remotePubkeyTags!;
  }
}
