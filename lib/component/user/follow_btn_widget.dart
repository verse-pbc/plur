import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../provider/contact_list_provider.dart';
import '../follow_set_follow_bottom_sheet.dart';
import 'metadata_top_widget.dart';

class FollowBtnWidget extends StatefulWidget {
  String pubkey;

  Color? borderColor;

  Color? followedBorderColor;

  FollowBtnWidget({
    super.key,
    required this.pubkey,
    this.borderColor,
    this.followedBorderColor,
  });

  @override
  State<StatefulWidget> createState() {
    return _FollowBtnWidgetState();
  }
}

class _FollowBtnWidgetState extends State<FollowBtnWidget> {
  @override
  Widget build(BuildContext context) {
    return Selector<ContactListProvider, Contact?>(
      builder: (context, contact, child) {
        if (contact == null) {
          return MetadataTextBtn(
            text: "Follow",
            borderColor: widget.borderColor,
            onTap: () {
              contactListProvider.addContact(Contact(publicKey: widget.pubkey));
            },
            onLongPress: onFollowPress,
          );
        } else {
          return MetadataTextBtn(
            text: "Unfollow",
            borderColor: widget.followedBorderColor,
            onTap: () {
              contactListProvider.removeContact(widget.pubkey);
            },
            onLongPress: onFollowPress,
          );
        }
      },
      selector: (_, provider) {
        return provider.getContact(widget.pubkey);
      },
    );
  }

  void onFollowPress() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return FollowSetFollowBottomSheet(widget.pubkey);
      },
    );
  }
}
