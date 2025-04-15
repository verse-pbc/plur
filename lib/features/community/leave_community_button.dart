import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../data/group_identifier_repository.dart';

class LeaveCommunityButton extends ConsumerWidget {
  final GroupIdentifier groupIdentifier;
  final VoidCallback? onLeft;

  const LeaveCommunityButton(this.groupIdentifier, {this.onLeft, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(groupIdentifierRepositoryProvider);
    return IconButton(
      icon: const Icon(Icons.group_remove_outlined),
      onPressed: () async {
        await controller.removeGroupIdentifier(groupIdentifier);
        onLeft?.call();
      },
    );
  }
}
