import 'dart:convert';

import 'package:sentry_flutter/sentry_flutter.dart';

import '../signer/nostr_signer.dart';
import '../utils/string_util.dart';

/// A class representing a remote request in the Nostr protocol.
class NostrRemoteRequest {
  /// The unique identifier for the request.
  String id;

  /// The method name of the request.
  String method;

  /// The parameters for the request.
  List<String> params;

  /// Creates a new NostrRemoteRequest with the given method and parameters.
  ///
  /// A unique ID is generated for the request.
  NostrRemoteRequest(this.method, this.params) : id = StringUtil.rndNameStr(12);

  /// Encrypts the request using the given [signer] and [pubkey].
  ///
  /// The request is converted to a JSON string and then encrypted.
  /// Returns the encrypted string or null if the encryption fails.
  Future<String?> encrypt(NostrSigner signer, String pubkey) async {
    // Create a JSON map with the request details.
    Map<String, dynamic> jsonMap = {};
    jsonMap["id"] = id;
    jsonMap["method"] = method;
    jsonMap["params"] = params;

    // Convert the JSON map to a string.
    var jsonStr = jsonEncode(jsonMap);

    // Encrypt the JSON string using the signer.
    return await signer.nip44Encrypt(pubkey, jsonStr);
  }

  /// Decrypts the given [ciphertext] using the [signer] and [pubkey].
  ///
  /// If the decryption is successful, a NostrRemoteRequest object is created
  /// from the decrypted data and returned. Returns null if the decryption
  /// fails.
  static Future<NostrRemoteRequest?> decrypt(
      String ciphertext, NostrSigner signer, String pubkey) async {
    try {
      // Decrypt the ciphertext using the signer.
      var plaintext = await signer.nip44Decrypt(pubkey, ciphertext);

      // Check if the plaintext is not blank.
      if (StringUtil.isNotBlank(plaintext)) {
        // Decode the JSON string to a map.
        var jsonMap = jsonDecode(plaintext!);

        // Extract the request details from the JSON map.
        var id = jsonMap["id"];
        var method = jsonMap["method"];
        var params = jsonMap["params"];

        // Create a list for the request parameters.
        List<String> requestParams = [];
        if (params != null && params is List) {
          for (var param in params) {
            requestParams.add(param);
          }
        }

        // Check if the ID and method are valid.
        if (id != null && id is String && method != null && method is String) {
          // Create a new NostrRemoteRequest object with the decrypted details.
          var request = NostrRemoteRequest(method, requestParams);
          request.id = id;
          return request;
        }
      }
    } catch (exception, stackTrace) {
      await Sentry.captureException(exception, stackTrace: stackTrace);
    }

    return null;
  }
}
