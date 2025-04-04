import 'package:flutter/material.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/content/content_image_widget.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/link_preview_data_provider.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../link_router_util.dart';

class ContentLinkPreWidget extends StatefulWidget {
  final String link;

  const ContentLinkPreWidget({super.key, required this.link});

  @override
  State<StatefulWidget> createState() {
    return _ContentLinkPreWidgetState();
  }
}

class _ContentLinkPreWidgetState extends State<ContentLinkPreWidget> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var cardColor = themeData.cardColor;

    return Selector<LinkPreviewDataProvider, PreviewData?>(
      builder: (context, data, child) {
        if (data != null &&
            StringUtil.isBlank(data.title) &&
            StringUtil.isBlank(data.description) &&
            data.image != null &&
            StringUtil.isNotBlank(data.image!.url)) {
          return ContentImageWidget(imageUrl: widget.link);
        }

        return Container(
          margin: const EdgeInsets.all(Base.basePadding),
          decoration: BoxDecoration(
            color: cardColor,
            boxShadow: [
              BoxShadow(
                color: themeData.shadowColor,
                offset: const Offset(0, 0),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: LinkPreview(
            linkStyle: TextStyle(
              color: themeData.primaryColor,
              decorationColor: themeData.primaryColor,
            ),
            enableAnimation: true,
            onPreviewDataFetched: (data) {
              // Save preview data
              linkPreviewDataProvider.set(widget.link, data);
            },
            previewData: data,
            text: widget.link,
            width: mediaDataCache.size.width,
            onLinkPressed: (link) {
              LinkRouterUtil.router(context, link);
            },
          ),
        );
      },
      selector: (_, provider) {
        return provider.getPreviewData(widget.link);
      },
    );
  }
}
