import 'package:flutter/material.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:provider/provider.dart';

/// Widget that displays the title for the combined communities feed
class CommunityTitleWidget extends StatelessWidget {
  const CommunityTitleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final listProvider = Provider.of<ListProvider>(context);
    final communityCount = listProvider.groupIdentifiers.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.view_agenda, size: 20),
        const SizedBox(width: 8),
        const Text('Combined Feed'),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withAlpha(25), // 10% opacity
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