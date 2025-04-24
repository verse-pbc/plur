import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../consts/router_path.dart';
import '../../util/router_util.dart';
import '../../features/create_community/create_community_dialog.dart';
import '../../generated/l10n.dart';
import '../../util/theme_util.dart';
import 'community_widget.dart';

/// A widget that displays a grid of communities.
class CommunitiesGridWidget extends StatelessWidget {
  /// List of group identifiers to be displayed in the grid.
  final List<GroupIdentifier> groupIds;

  const CommunitiesGridWidget({super.key, required this.groupIds});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final localization = S.of(context);
    final separatorColor = themeData.customColors.separatorColor;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 52),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 0.0,
        mainAxisSpacing: 32.0,
        childAspectRatio: 1,
      ),
      itemCount: groupIds.length + 1, // Add 1 for the create button
      itemBuilder: (context, index) {
        if (index == 0) {
          // Create Community button
          return InkWell(
            onTap: () => CreateCommunityDialog.show(context),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: separatorColor,
                      width: 4,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.add,
                      size: 48,
                      color: themeData.customColors.primaryForegroundColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 120,
                  child: Text(
                    localization.Create_Community,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: themeData.textTheme.bodyMedium!.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          );
        }
        final groupIdentifier = groupIds[index - 1];
        return InkWell(
          onTap: () {
            RouterUtil.router(context, RouterPath.groupDetail, groupIdentifier);
          },
          child: CommunityWidget(groupIdentifier),
        );
      },
    );
  }
}
