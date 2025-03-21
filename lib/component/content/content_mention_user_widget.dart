import 'package:flutter/material.dart';
import 'package:nostrmo/component/user/simple_name_widget.dart';
import 'package:provider/provider.dart';

import '../../consts/router_path.dart';
import '../../data/metadata.dart';
import '../../provider/metadata_provider.dart';
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
    return Selector<MetadataProvider, Metadata?>(
      builder: (context, metadata, child) {
        String name =
            SimpleNameWidget.getSimpleName(widget.pubkey, metadata);

        return ContentStrLinkWidget(
          str: "@$name",
          showUnderline: false,
          onTap: () {
            RouterUtil.router(context, RouterPath.USER, widget.pubkey);
          },
        );
      },
      selector: (_, provider) {
        return provider.getMetadata(widget.pubkey);
      },
    );
  }
}
