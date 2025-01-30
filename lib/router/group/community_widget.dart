
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:provider/provider.dart';

import '../../util/theme_util.dart';

class CommunityWidget extends StatelessWidget {
  final GroupIdentifier groupIdentifier;

  const CommunityWidget(this.groupIdentifier, {super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GroupProvider>(context);
    final metadata = provider.getMetadata(groupIdentifier);
    final imageUrl = metadata?.picture;
    const double imageSize = 120;
    final themeData = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: themeData.customColors.separatorColor,
              width: 4,
            ),
          ),
          child: ClipOval(
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: imageSize,
                    height: imageSize,
                  )
                : Icon(Icons.group, color: themeData.customColors.dimmedColor, size: 64),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: imageSize,
          child: SizedBox(
            height: 60,
            child: Text(
              metadata?.name ?? groupIdentifier.groupId,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: themeData.textTheme.labelMedium!.color,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ),
      ],
    );
  }

}