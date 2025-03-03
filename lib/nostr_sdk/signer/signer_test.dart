import 'dart:convert';
import 'dart:developer' as developer;

import '../event.dart';
import '../event_kind.dart';
import 'nostr_signer.dart';

Future<void> signerTest(NostrSigner nostrSigner) async {
  var pubkey = await nostrSigner.getPublicKey();
  developer.log("pubkey $pubkey");

  await Future.delayed(const Duration(seconds: 10));

  {
    var ciphertext = await nostrSigner.encrypt(pubkey, "Hello");
    developer.log("ciphertext $ciphertext");

    await Future.delayed(const Duration(seconds: 10));

    var plaintext = await nostrSigner.decrypt(pubkey, ciphertext);
    developer.log("plaintext $plaintext");
  }

  await Future.delayed(const Duration(seconds: 10));

  {
    var ciphertext = await nostrSigner.nip44Encrypt(pubkey, "Hello");
    developer.log("ciphertext $ciphertext");

    await Future.delayed(const Duration(seconds: 10));

    var plaintext = await nostrSigner.nip44Decrypt(pubkey, ciphertext);
    developer.log("plaintext $plaintext");
  }

  await Future.delayed(const Duration(seconds: 10));

  Event? event = Event(pubkey!, EventKind.TEXT_NOTE, [], "Hello");
  event = await nostrSigner.signEvent(event);
  developer.log(event.toString());
  developer.log(jsonEncode(event!.toJson()));
}
