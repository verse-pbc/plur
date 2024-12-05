import 'package:flutter/material.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/util/router_util.dart';

import 'content_str_link_widget.dart';

class ContentTagWidget extends StatelessWidget {
  String tag;

  ContentTagWidget({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    return ContentStrLinkWidget(
      str: tag,
      onTap: () {
        var plainTag = tag.replaceFirst("#", "");
        RouterUtil.router(context, RouterPath.TAG_DETAIL, plainTag);
      },
    );
  }
}
