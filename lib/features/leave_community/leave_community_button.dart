import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import 'leave_community_controller.dart';

class LeaveCommunityButton extends ConsumerWidget {
  final GroupIdentifier groupIdentifier;
  final VoidCallback? onLeft;

  const LeaveCommunityButton(this.groupIdentifier, {this.onLeft, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaveCommunityController = ref.watch(leaveCommunityControllerProvider.notifier);
    return IconButton(
      icon: const Icon(Icons.group_remove_outlined),
      onPressed: () async {
        final success = await leaveCommunityController.leaveCommunity(groupIdentifier);
        if (success) {
          onLeft?.call();
        }
      },
    );
  }
}
