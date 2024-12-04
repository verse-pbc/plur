import 'package:flutter/material.dart';
import 'package:nostrmo/component/user/simple_name_component.dart';
import 'package:provider/provider.dart';

import '../../consts/router_path.dart';
import '../../data/metadata.dart';
import '../../provider/metadata_provider.dart';
import '../../util/router_util.dart';
import '../user/name_component.dart';
import 'content_str_link_component.dart';

class ContentMentionUserWidget extends StatefulWidget {
  String pubkey;

  ContentMentionUserWidget({super.key, required this.pubkey});

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
      selector: (context, _provider) {
        return _provider.getMetadata(widget.pubkey);
      },
    );
  }
}
