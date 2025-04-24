import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/main.dart';

final noteProvider = Provider((ref) => NoteProvider());

class NoteProvider {
  Future<void> sendNote({
    required String content,
    required int kind,
    required List<List<String>> tags,
  }) async {
    if (nostr == null) {
      throw Exception('Nostr client not initialized');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Create the event
    final event = Event(nostr!.publicKey, kind, tags, content);

    try {
      // Sign and publish the event
      await nostr!.signEvent(event);
      await nostr!.sendEvent(event);
    } catch (e) {
      // Handle any errors during signing or sending
      rethrow;
    }
  }
}
