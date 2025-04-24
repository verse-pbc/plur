import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostrmo/provider/note_provider.dart';

final emergencyAlertControllerProvider =
    Provider((ref) => EmergencyAlertController(ref));

class EmergencyAlertController {
  final Ref ref;

  EmergencyAlertController(this.ref);

  Future<void> sendEmergencyAlert(String message, String groupId) async {
    // Create a kind 11 note with broadcast and group tags
    final noteSender = ref.read(noteProvider);
    await noteSender.sendNote(
      content: message,
      kind: 11,
      tags: [
        ["broadcast", "emergency"],
        ["h", groupId],
      ],
    );
  }
}
