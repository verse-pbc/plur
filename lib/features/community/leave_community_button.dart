import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/util/theme_util.dart';

import '../../data/group_identifier_repository.dart';
import '../../util/router_util.dart';
import '../../consts/router_path.dart';

class LeaveCommunityButton extends ConsumerWidget {
  final GroupIdentifier groupIdentifier;
  final VoidCallback? onLeft;

  const LeaveCommunityButton(this.groupIdentifier, {this.onLeft, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(groupIdentifierRepositoryProvider);
    return IconButton(
      icon: const Icon(Icons.group_remove_outlined),
      tooltip: 'Leave community',
      onPressed: () => _showLeaveConfirmation(context, controller),
    );
  }
  
  void _showLeaveConfirmation(BuildContext context, GroupIdentifierRepository controller) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final localization = S.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: customColors.feedBgColor,
        title: Text(
          localization.leaveGroupQuestion,
          style: TextStyle(
            color: customColors.primaryForegroundColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          localization.leaveGroupConfirmation,
          style: TextStyle(
            color: customColors.primaryForegroundColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              localization.cancel,
              style: TextStyle(
                color: customColors.primaryForegroundColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              // Leave the group
              await controller.removeGroupIdentifier(groupIdentifier);
              
              // Close the dialog
              if (context.mounted) Navigator.of(context).pop();
              
              // Execute callback if provided
              onLeft?.call();
              
              // Navigate back to the main screen
              // This is the safest approach to avoid routing issues
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  RouterPath.index, 
                  (route) => false, // Remove all previous routes
                );
              }
            },
            child: Text(
              localization.leave,
              style: const TextStyle(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
