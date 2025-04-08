import 'package:flutter/material.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:provider/provider.dart';

/// Widget that displays the title for the combined communities feed
class CommunityTitleWidget extends StatelessWidget {
  const CommunityTitleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final listProvider = Provider.of<ListProvider>(context);
    final communityCount = listProvider.groupIdentifiers.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.forum_outlined, size: 20),
        const SizedBox(width: 8),
        Text('${l10n.Communities} Feed'),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$communityCount',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}