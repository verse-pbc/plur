import 'dart:convert';

import '../signer/nostr_signer.dart';
import '../utils/string_util.dart';

/// A class representing a remote response in the Nostr protocol.
class NostrRemoteResponse {
  /// The unique identifier for the response.
  String id;

  /// The result of the response.
  String result;

  /// The error message, if any.
  String? error;

  /// Creates a new NostrRemoteResponse with the given id, result, and optional
  /// error.
  NostrRemoteResponse(this.id, this.result, {this.error});

  /// Decrypts the given [ciphertext] using the [signer] and [pubkey].
  ///
  /// If the decryption is successful, a NostrRemoteResponse object is created
  /// from the decrypted data and returned. Returns null if the decryption
  /// fails.
  static Future<NostrRemoteResponse?> decrypt(
      String ciphertext, NostrSigner signer, String pubkey) async {
    // Decrypt the ciphertext using the signer.
    var plaintext = await signer.nip44Decrypt(pubkey, ciphertext);

    // Check if the plaintext is not blank.
    if (StringUtil.isNotBlank(plaintext)) {
      // Decode the JSON string to a map.
      var jsonMap = jsonDecode(plaintext!);

      // Extract the response details from the JSON map.
      var id = jsonMap["id"];
      var result = jsonMap["result"];

      // Check if the ID and result are valid.
      if (id != null && id is String && result != null && result is String) {
        // Create a new NostrRemoteResponse object with the decrypted details.
        return NostrRemoteResponse(id, result, error: jsonMap["error"]);
      }
    }

    return null;
  }

  /// Encrypts the response using the given [signer] and [pubkey].
  ///
  /// The response is converted to a JSON string and then encrypted.
  /// Returns the encrypted string or null if the encryption fails.
  Future<String?> encrypt(NostrSigner signer, String pubkey) async {
    // Create a JSON map with the response details.
    Map<String, dynamic> jsonMap = {};
    jsonMap["id"] = id;
    jsonMap["result"] = result;
    if (StringUtil.isNotBlank(error)) {
      jsonMap["error"] = error;
    }

    // Convert the JSON map to a string.
    var jsonStr = jsonEncode(jsonMap);

    // Encrypt the JSON string using the signer.
    return await signer.nip44Encrypt(pubkey, jsonStr);
  }

  @override
  String toString() {
    return "$id $result $error";
  }
}
