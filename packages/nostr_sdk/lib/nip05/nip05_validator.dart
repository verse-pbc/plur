import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';

class Nip05Validator {
  static final Map<String, int> _checking = {};

  static var dio = Dio();

  static Future<bool?> valid(String nip05Address, String pubkey) async {
    if (_checking[nip05Address] != null) {
      return null;
    }

    try {
      _checking[nip05Address] = 1;
      return await _doValid(nip05Address, pubkey);
    } finally {
      _checking.remove(nip05Address);
    }
  }

  static Future<bool> _doValid(String nip05Address, String pubkey) async {
    var remotePubkey = await getPubkey(nip05Address);
    if (remotePubkey == pubkey) {
      return true;
    }

    return false;
  }

  static Future<String?> getPubkey(String nip05Address) async {
    var name = "_";
    var address = nip05Address;
    var strs = nip05Address.split("@");
    if (strs.length > 1) {
      name = strs[0];
      address = strs[1];
    }

    var url = "https://$address/.well-known/nostr.json?name=$name";
    try {
      var response = await dio.get(url);
      if (response.data != null) {
        var map = response.data;
        if (map is String) {
          map = jsonDecode(response.data);
        }

        if (map is Map && map["names"] != null) {
          var dataPubkey = map["names"][name];
          if (dataPubkey != null && dataPubkey is String) {
            return dataPubkey;
          }
        }
      }
    } catch (e) {
      log("getPubkey error in nip05 validator: $e");
    }

    return null;
  }

  /// Retrieves the full JSON data from a NIP-05 identifier
  /// including any custom fields like "bunker" URLs
  static Future<Map<String, dynamic>?> getJson(String nip05Address) async {
    var name = "_";
    var address = nip05Address;
    var strs = nip05Address.split("@");
    if (strs.length > 1) {
      name = strs[0];
      address = strs[1];
    }

    var url = "https://$address/.well-known/nostr.json?name=$name";
    try {
      var response = await dio.get(url);
      if (response.data != null) {
        dynamic rawMap = response.data;
        if (rawMap is String) {
          rawMap = jsonDecode(response.data);
        }

        if (rawMap is Map) {
          // Check if this nip05 address's metadata exists
          if (rawMap["names"] != null && rawMap["names"][name] != null) {
            // Cast to the specific type we need
            Map<String, dynamic> typedMap = Map<String, dynamic>.from(rawMap);
            // Success - we found the user's metadata
            return typedMap;
          }
        }
      }
    } catch (e) {
      log("getJson error in nip05 validator: $e");
    }

    return null;
  }
}
