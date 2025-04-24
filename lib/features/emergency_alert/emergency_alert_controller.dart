import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/note_provider.dart';
import 'package:nostrmo/main.dart';

final emergencyAlertControllerProvider = Provider((ref) {
  return EmergencyAlertController(ref);
});

class EmergencyAlertController {
  final Ref _ref;

  EmergencyAlertController(this._ref);

  Future<Event> sendEmergencyAlert(String message, String groupId) async {
    final event = Event(
      nostr!.publicKey,
      EventKind.groupNote,
      [
        ["h", groupId],
      ],
      message,
    );

    final sentEvent = await nostr!
        .sendEvent(event, targetRelays: [groupId], tempRelays: [groupId]);
    if (sentEvent == null) {
      throw Exception('Failed to send emergency alert');
    }
    return sentEvent;
  }
}
