import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:nostrmo/features/emergency_alert/emergency_alert_controller.dart';

final isEmergencyProvider = StateProvider<bool>((ref) => true);
final messageProvider = StateProvider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

class EmergencyAlertScreen extends ConsumerWidget {
  final GroupIdentifier groupIdentifier;

  const EmergencyAlertScreen({
    super.key,
    required this.groupIdentifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageController = ref.watch(messageProvider);
    final isEmergency = ref.watch(isEmergencyProvider);
    final themeData = Theme.of(context);
    final cardColor = themeData.cardColor;
    final textColor = themeData.textTheme.bodyMedium!.color;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      color: cardColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            backgroundColor: cardColor,
            title: Text(
              'Sending Emergency Alert',
              style: TextStyle(color: textColor),
            ),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: Icon(Icons.close, color: textColor),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  value: isEmergency,
                  onChanged: (value) => ref
                      .read(isEmergencyProvider.notifier)
                      .state = value ?? true,
                  title: Text(
                    'This is an emergency',
                    style: TextStyle(color: textColor),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 16),
                Text(
                  'Message:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: messageController,
                  maxLines: 5,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Enter emergency message...',
                    hintStyle: TextStyle(color: themeData.hintColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: themeData.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: themeData.primaryColor),
                    ),
                    filled: true,
                    fillColor: cardColor,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final message = messageController.text;
                      if (message.isEmpty) {
                        BotToast.showText(text: 'Please enter a message');
                        return;
                      }

                      if (!isEmergency) {
                        BotToast.showText(
                          text:
                              'If this is not an emergency please go back and post a normal announcement using the + button.',
                          duration: const Duration(seconds: 4),
                        );
                        return;
                      }

                      try {
                        await ref
                            .read(emergencyAlertControllerProvider)
                            .sendEmergencyAlert(
                              message,
                              groupIdentifier.groupId,
                            );
                        messageController.clear();
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                      } catch (e) {
                        BotToast.showText(
                            text: 'Failed to send alert: ${e.toString()}');
                      }
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Send'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
