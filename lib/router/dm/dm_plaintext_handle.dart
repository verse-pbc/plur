import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/data/event_db.dart';
import 'dart:developer';

import '../../main.dart';

mixin DMPlaintextHandle<T extends StatefulWidget> on State<T> {
  // Static cache for decrypted messages to avoid repeated decryption
  static final Map<String, String> decryptionCache = {};
  
  String? currentPlainEventId;
  String? plainContent;

  void handleEncryptedText(Event event, String pubkey) {
    if (NIP04.isEncrypted(event.content)) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Check if already in cache
        if (decryptionCache.containsKey(event.id)) {
          setState(() {
            plainContent = decryptionCache[event.id];
            currentPlainEventId = event.id;
          });
          return;
        }
        
        var pc = await nostr!.nostrSigner.decrypt(pubkey, event.content);
        if (StringUtil.isNotBlank(pc)) {
          // save to db, avoid decrypt all the time
          try {
            event.content = pc!;
            EventDB.update(settingsProvider.privateKeyIndex!, event);
            
            // Store in cache
            decryptionCache[event.id] = pc;
          } catch (e, st) {
            log('$e');
            log(st.toString());
          }

          setState(() {
            plainContent = pc;
            currentPlainEventId = event.id;
          });
        }
      });
    }
  }
  
  // Helper to get cached content
  static String? getCachedContent(String eventId) {
    return decryptionCache[eventId];
  }
  
  // Helper to add to cache
  static void cacheContent(String eventId, String content) {
    decryptionCache[eventId] = content;
  }
}
