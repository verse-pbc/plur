import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../consts/router_path.dart';
import '../../data/group_metadata_repository.dart';
import '../../util/router_util.dart';
import 'community_widget.dart';

/// A widget that displays a grid of communities.
class CommunitiesGridWidget extends ConsumerWidget {
  /// List of group identifiers to be displayed in the grid.
  final List<GroupIdentifier> groupIds;

  const CommunitiesGridWidget({super.key, required this.groupIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Log that this widget is being built/displayed
    debugPrint("🔍 SCREEN DISPLAYED: CommunitiesGridWidget (Communities grid)");
    
    // Pre-fetch metadata for all communities immediately
    // This will trigger a single batch of requests instead of loading one by one
    final bulkLoadingState = ref.watch(bulkGroupMetadataProvider(groupIds));
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate cross axis count based on width
        int crossAxisCount = 2; // Default for mobile
        if (constraints.maxWidth > 800) {
          crossAxisCount = 3; // Medium sized screens
        }
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 4; // Large screens
        }
        
        return GridView.builder(
          padding: const EdgeInsets.only(top: 52, bottom: 80), // Increased bottom padding
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 0.0,
            mainAxisSpacing: 40.0, // Increased to give more vertical space
            childAspectRatio: 0.9, // Adjusted to make cells taller than they are wide
          ),
          itemCount: groupIds.length,
          itemBuilder: (context, index) {
            final groupIdentifier = groupIds[index];
            return InkWell(
              onTap: () {
                RouterUtil.router(
                    context, RouterPath.groupDetail, groupIdentifier);
              },
              child: CommunityWidget(groupIdentifier),
            );
          },
        );
      },
    );
  }
}
