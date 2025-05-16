import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/provider/index_provider.dart';
import 'package:nostrmo/theme/app_colors.dart';

import '../../data/group_identifier_repository.dart';
import '../../main.dart'; // For indexProvider
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
    final localization = S.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.feedBackground,
        title: Text(
          localization.leaveGroupQuestion,
          style: TextStyle(
            color: context.colors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          localization.leaveGroupConfirmation,
          style: TextStyle(
            color: context.colors.primaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              localization.cancel,
              style: TextStyle(
                color: context.colors.primaryText,
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
              
              // Navigate back to the main index screen without creating duplicate keys
              // Pop all the way back to first route if mounted
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
                
                // Refresh the current index in the IndexProvider to ensure we're on the main screen
                indexProvider.setCurrentTap(0);
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
