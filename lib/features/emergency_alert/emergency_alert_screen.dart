import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:nostrmo/router/edit/editor_widget.dart';
import 'package:nostrmo/component/group_identifier_inherited_widget.dart';

final isEmergencyProvider = StateProvider<bool>((ref) => true);
final messageProvider = StateProvider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

class EmergencyAlertScreen extends ConsumerWidget {
  const EmergencyAlertScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageController = ref.watch(messageProvider);
    final isEmergency = ref.watch(isEmergencyProvider);
    final groupIdentifier =
        GroupIdentifierInheritedWidget.of(context)?.groupIdentifier;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sending Emergency Alert'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              value: isEmergency,
              onChanged: (value) =>
                  ref.read(isEmergencyProvider.notifier).state = value ?? true,
              title: const Text('This is an emergency'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16),
            const Text(
              'Message:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: messageController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter emergency message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (groupIdentifier == null) {
                    BotToast.showText(text: 'Group not found');
                    return;
                  }

                  final message = messageController.text;
                  if (message.isEmpty) {
                    BotToast.showText(text: 'Please enter a message');
                    return;
                  }

                  final event = await EditorWidget.open(
                    context,
                    tags: [],
                    tagsAddedWhenSend: [
                      ["broadcast", "emergency"],
                    ],
                    tagPs: [],
                    groupIdentifier: groupIdentifier,
                    groupEventKind: EventKind.groupNote,
                  );

                  if (!context.mounted) return;

                  if (event != null) {
                    Navigator.of(context).pop();
                  } else {
                    BotToast.showText(text: 'Failed to send alert');
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
    );
  }
}
