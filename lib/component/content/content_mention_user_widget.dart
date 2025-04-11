import 'package:flutter/material.dart';
import 'package:nostrmo/component/user/simple_name_widget.dart';
import 'package:provider/provider.dart';

import '../../consts/router_path.dart';
import '../../data/user.dart';
import '../../provider/user_provider.dart';
import '../../util/router_util.dart';
import 'content_str_link_widget.dart';

class ContentMentionUserWidget extends StatefulWidget {
  final String pubkey;

  const ContentMentionUserWidget({super.key, required this.pubkey});

  @override
  State<StatefulWidget> createState() {
    return _ContentMentionUserWidgetState();
  }
}

class _ContentMentionUserWidgetState extends State<ContentMentionUserWidget> {
  @override
  Widget build(BuildContext context) {
    return Selector<UserProvider, User?>(
      builder: (context, user, child) {
        String name =
            SimpleNameWidget.getSimpleName(widget.pubkey, user);

        return ContentStrLinkWidget(
          str: "@$name",
          // Based on the design, mentions should have an underline like other links
          showUnderline: true,
          onTap: () {
            RouterUtil.router(context, RouterPath.user, widget.pubkey);
          },
        );
      },
      selector: (_, provider) {
        return provider.getUser(widget.pubkey);
      },
    );
  }
}
