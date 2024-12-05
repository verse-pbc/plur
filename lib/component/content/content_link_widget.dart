import 'package:flutter/material.dart';
import 'package:nostrmo/component/content/content_str_link_widget.dart';

import '../link_router_util.dart';

class ContentLinkWidget extends StatelessWidget {
  String link;

  String? title;

  ContentLinkWidget({
    required this.link,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ContentStrLinkWidget(
      str: title != null ? title! : link,
      onTap: () {
        LinkRouterUtil.router(context, link);
      },
    );
  }
}
