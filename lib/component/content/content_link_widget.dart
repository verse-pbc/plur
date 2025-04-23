import 'package:flutter/material.dart';
import 'package:nostrmo/component/content/content_str_link_widget.dart';

import '../link_router_util.dart';

class ContentLinkWidget extends StatelessWidget {
  final String link;

  final String? title;

  const ContentLinkWidget({
    super.key, 
    required this.link,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    // Use the title if provided, otherwise format the URL nicely
    final displayText = title != null ? title! : link;
    
    // Direct URL display is handled by ContentStrLinkWidget
    return ContentStrLinkWidget(
      str: displayText,
      onTap: () {
        LinkRouterUtil.router(context, link);
      },
      // Apply special styling for direct URL display if needed
      showUnderline: true,
    );
  }
}
