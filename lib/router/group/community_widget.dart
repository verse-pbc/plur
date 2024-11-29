
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:provider/provider.dart';

import '../../consts/colors.dart';

class CommunityWidget extends StatelessWidget {
  final GroupIdentifier groupIdentifier;

  const CommunityWidget(this.groupIdentifier, {super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GroupProvider>(context);
    final community = provider.getMetadata(groupIdentifier);
    final imageUrl = community?.picture;
    const double imageSize = 120;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: ColorList.borderColor,
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
                : const Icon(Icons.group, color: Colors.white, size: 64),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: imageSize,
          child: SizedBox(
            height: 60,
            child: Text(
              groupIdentifier.groupId,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
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