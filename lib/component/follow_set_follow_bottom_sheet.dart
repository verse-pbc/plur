import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/contact_list_provider.dart';
import 'package:provider/provider.dart';

import '../consts/base.dart';
import '../generated/l10n.dart';
import '../router/index/index_drawer_content.dart';

class FollowSetFollowBottomSheet extends StatefulWidget {
  final String pubkey;

  const FollowSetFollowBottomSheet(this.pubkey, {super.key});

  @override
  State<StatefulWidget> createState() {
    return _FollowSetFollowBottomSheet();
  }
}

class _FollowSetFollowBottomSheet extends State<FollowSetFollowBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);

    final themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var backgroundColor = themeData.scaffoldBackgroundColor;

    var contactListProvider = Provider.of<ContactListProvider>(context);

    List<Widget> list = [];
    list.add(Container(
      padding: const EdgeInsets.only(
        top: Base.basePaddingHalf,
        bottom: Base.basePaddingHalf,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: hintColor,
          ),
        ),
      ),
      child: IndexDrawerItemWidget(
        iconData: Icons.people,
        name: localization.Follow_set,
        onTap: () {},
      ),
    ));

    list.add(Container(
      padding: const EdgeInsets.only(
        top: Base.basePaddingHalf,
        bottom: Base.basePaddingHalf,
        left: Base.basePadding,
        right: Base.basePadding,
      ),
      margin: const EdgeInsets.only(bottom: Base.basePaddingHalf),
      color: themeData.cardColor,
      child: Row(
        children: [
          Expanded(child: Container()),
          SizedBox(
            width: 60,
            child: Tooltip(
              message: localization.Private,
              child: const Icon(Icons.lock_outline),
            ),
          ),
          SizedBox(
            width: 60,
            child: Tooltip(
              message: localization.Public,
              child: const Icon(Icons.lock_open),
            ),
          ),
        ],
      ),
    ));

    var followSets = contactListProvider.followSetMap.values;
    List<Widget> selectList = [];
    for (var followSet in followSets) {
      selectList.add(Container(
        margin: const EdgeInsets.only(bottom: Base.basePaddingHalf),
        child: FollowSetFollowItemWidget(
          followSet,
          followSet.privateFollow(widget.pubkey),
          onPrivateChange,
          followSet.publicFollow(widget.pubkey),
          onPublicChange,
        ),
      ));
    }

    list.add(Container(
      height: 300,
      color: backgroundColor,
      child: SingleChildScrollView(
        child: Column(
          children: selectList,
        ),
      ),
    ));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: list,
    );
  }

  onPrivateChange(FollowSet fs, bool? b) {
    if (b != null) {
      if (fs.privateFollow(widget.pubkey)) {
        // is following
        fs.removePrivate(widget.pubkey);
      } else {
        fs.addPrivate(Contact(publicKey: widget.pubkey));
      }
    }

    contactListProvider.addFollowSet(fs);
  }

  onPublicChange(FollowSet fs, bool? b) {
    if (b != null) {
      if (fs.publicFollow(widget.pubkey)) {
        // is following
        fs.removePublic(widget.pubkey);
      } else {
        fs.addPublic(Contact(publicKey: widget.pubkey));
      }
    }

    contactListProvider.addFollowSet(fs);
  }
}

class FollowSetFollowItemWidget extends StatefulWidget {
  final FollowSet followSet;

  final bool privateValue;

  final Function(FollowSet, bool?) onPrivateChange;

  final bool publicValue;

  final Function(FollowSet, bool?) onPublicChange;

  const FollowSetFollowItemWidget(
    this.followSet,
    this.privateValue,
    this.onPrivateChange,
    this.publicValue,
    this.onPublicChange, 
    {super.key}
  );

  @override
  State<StatefulWidget> createState() {
    return _FollowSetFollowItemWidgetState();
  }
}

class _FollowSetFollowItemWidgetState extends State<FollowSetFollowItemWidget> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Container(
      padding: const EdgeInsets.only(
        top: Base.basePaddingHalf,
        bottom: Base.basePaddingHalf,
        left: Base.basePadding,
        right: Base.basePadding,
      ),
      color: themeData.cardColor,
      child: Row(
        children: [
          Expanded(
            child: Text(widget.followSet.displayName()),
          ),
          SizedBox(
            width: 60,
            child: Checkbox(
              value: widget.privateValue,
              onChanged: (b) {
                widget.onPrivateChange(widget.followSet, b);
              },
            ),
          ),
          SizedBox(
            width: 60,
            child: Checkbox(
              value: widget.publicValue,
              onChanged: (b) {
                widget.onPublicChange(widget.followSet, b);
              },
            ),
          ),
        ],
      ),
    );
  }
}
