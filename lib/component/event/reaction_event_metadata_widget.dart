import 'package:flutter/material.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../../data/user.dart';
import '../../provider/metadata_provider.dart';
import '../user/simple_name_widget.dart';

class ReactionEventMetadataWidget extends StatefulWidget {
  String pubkey;

  ReactionEventMetadataWidget({super.key, 
    required this.pubkey,
  });

  @override
  State<StatefulWidget> createState() {
    return _ReactionEventMetadataWidgetState();
  }
}

class _ReactionEventMetadataWidgetState extends State<ReactionEventMetadataWidget> {
  static const double IMAGE_WIDTH = 20;

  @override
  Widget build(BuildContext context) {
    return Selector<MetadataProvider, User?>(
        builder: (context, user, child) {
      List<Widget> list = [];

      var name = SimpleNameWidget.getSimpleName(widget.pubkey, user);

      list.add(UserPicWidget(
        pubkey: widget.pubkey,
        width: IMAGE_WIDTH,
        user: user,
      ));

      list.add(Container(
        margin: const EdgeInsets.only(left: 5),
        child: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ));

      return GestureDetector(
        onTap: () {
          RouterUtil.router(context, RouterPath.USER, widget.pubkey);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: list,
        ),
      );
    }, selector: (_, provider) {
      return provider.getUser(widget.pubkey);
    });
  }
}
