import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../generated/l10n.dart';
import 'leave_community_controller.dart';

class LeaveCommunityButton extends ConsumerWidget {
  final GroupIdentifier groupIdentifier;
  final VoidCallback? onLeft;

  const LeaveCommunityButton(this.groupIdentifier, {this.onLeft, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = S.of(context);
    return IconButton(
      icon: const Icon(Icons.group_remove),
      onPressed: () async {
        final themeData = Theme.of(context);
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) =>
              Theme(
                data: themeData,
                child: AlertDialog(
                  backgroundColor: themeData.colorScheme.surface,
                  content: Text(
                    localization.Confirm_Leave,
                    style: TextStyle(
                      color: themeData.colorScheme.onSurface,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(localization.Cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(localization.Leave),
                    ),
                  ],
                ),
              ),
        );

        if (shouldLeave != true) return;

        final controller = ref.read(leaveCommunityControllerProvider.notifier);
        final success = await controller.leaveCommunity(groupIdentifier);

        if (success) {
          onLeft?.call();
        }
      },
    );
  }
}
