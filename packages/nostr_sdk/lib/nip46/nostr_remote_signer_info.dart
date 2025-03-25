import '../client_utils/keys.dart';
import '../nip19/nip19.dart';
import '../utils/string_util.dart';

/// This client is designed for nostr client.
class NostrRemoteSignerInfo {
  /// The public key of the remote signer.
  String remoteSignerPubkey;

  /// The list of relay URLs.
  List<String> relays;

  /// An optional secret, can be null.
  String? optionalSecret;

  /// The client's signer nsec, sometimes needed to save all info in one place.
  /// Can be null.
  String? nsec;

  /// The user's public key, sometimes needed to save all info in one place.
  /// Can be null.
  String? userPubkey;

  /// Constructs a [NostrRemoteSignerInfo] with the required remote signer
  /// public key and list of relay URLs.
  /// Optional parameters include the secret, nsec, and user public key.
  NostrRemoteSignerInfo({
    required this.remoteSignerPubkey,
    required this.relays,
    this.optionalSecret,
    this.nsec,
    this.userPubkey,
  });

  @override
  String toString() {
    Map<String, dynamic> pars = {};
    pars["relay"] = relays;
    pars["secret"] = optionalSecret;
    if (nsec != null) {
      pars["nsec"] = nsec;
    }
    if (userPubkey != null) {
      pars["userPubkey"] = userPubkey;
    }

    var uri = Uri(
      scheme: "bunker",
      host: remoteSignerPubkey,
      queryParameters: pars,
    );

    return uri.toString();
  }

  /// Checks if the given [url] is a valid bunker URL.
  static bool isBunkerUrl(String? url) {
    if (url == null) return false;
    return url.startsWith("bunker://");
  }

  /// Parses a bunker URL and returns a [NostrRemoteSignerInfo] object if valid.
  /// If nsec is not provided, it will be generated.
  static NostrRemoteSignerInfo? parseBunkerUrl(String url, {String? nsec}) {
    var uri = Uri.parse(url);

    var pars = uri.queryParametersAll;

    var remoteSignerPubkey = uri.host;

    var relays = pars["relay"];
    if (relays == null || relays.isEmpty) {
      return null;
    }

    var optionalSecrets = pars["secret"];
    String? optionalSecret;
    if (optionalSecrets != null && optionalSecrets.isNotEmpty) {
      optionalSecret = optionalSecrets.first;
    }

    if (StringUtil.isBlank(nsec)) {
      if (pars["nsec"] != null && pars["nsec"]!.isNotEmpty) {
        nsec = pars["nsec"]!.first;
      } else {
        nsec = Nip19.encodePrivateKey(generatePrivateKey());
      }
    }

    var userPubkeys = pars["userPubkey"];
    String? userPubkey;
    if (userPubkeys != null && userPubkeys.isNotEmpty) {
      userPubkey = userPubkeys.first;
    }

    return NostrRemoteSignerInfo(
      remoteSignerPubkey: remoteSignerPubkey,
      relays: relays,
      optionalSecret: optionalSecret,
      nsec: nsec!,
      userPubkey: userPubkey,
    );
  }
}
