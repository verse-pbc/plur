import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip02/contact.dart';
import 'package:nostr_sdk/nip51/follow_set.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/contact_list_provider.dart';
import 'package:provider/provider.dart';

import '../consts/base.dart';
import '../generated/l10n.dart';
import '../router/index/index_drawer_content.dart';

class FollowSetFollowBottomSheet extends StatefulWidget {
  String pubkey;

  FollowSetFollowBottomSheet(this.pubkey, {super.key});

  @override
  State<StatefulWidget> createState() {
    return _FollowSetFollowBottomSheet();
  }
}

class _FollowSetFollowBottomSheet extends State<FollowSetFollowBottomSheet> {
  @override
  Widget build(BuildContext context) {
    var s = S.of(context);

    var themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var backgroundColor = themeData.scaffoldBackgroundColor;

    var _contactListProvider = Provider.of<ContactListProvider>(context);

    List<Widget> list = [];
    list.add(Container(
      padding: const EdgeInsets.only(
        top: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING_HALF,
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
        name: s.Follow_set,
        onTap: () {},
      ),
    ));

    list.add(Container(
      padding: const EdgeInsets.only(
        top: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING_HALF,
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      color: themeData.cardColor,
      child: Row(
        children: [
          Expanded(child: Container()),
          SizedBox(
            width: 60,
            child: Tooltip(
              message: s.Private,
              child: const Icon(Icons.lock_outline),
            ),
          ),
          SizedBox(
            width: 60,
            child: Tooltip(
              message: s.Public,
              child: const Icon(Icons.lock_open),
            ),
          ),
        ],
      ),
    ));

    var followSets = _contactListProvider.followSetMap.values;
    List<Widget> selectList = [];
    for (var followSet in followSets) {
      selectList.add(Container(
        margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
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
  FollowSet followSet;

  bool privateValue;

  Function(FollowSet, bool?) onPrivateChange;

  bool publicValue;

  Function(FollowSet, bool?) onPublicChange;

  FollowSetFollowItemWidget(
    this.followSet,
    this.privateValue,
    this.onPrivateChange,
    this.publicValue,
    this.onPublicChange,
  );

  @override
  State<StatefulWidget> createState() {
    return _FollowSetFollowItemWidgetState();
  }
}

class _FollowSetFollowItemWidgetState extends State<FollowSetFollowItemWidget> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);

    return Container(
      padding: const EdgeInsets.only(
        top: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING_HALF,
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
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
