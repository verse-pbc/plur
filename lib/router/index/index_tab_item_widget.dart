import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:widget_size/widget_size.dart';

import 'index_app_bar.dart';

class IndexTabItemWidget extends StatefulWidget {
  String text;

  String? omitText;

  TextStyle textStyle;

  IndexTabItemWidget(
    this.text,
    this.textStyle, {
      super.key,
    this.omitText,
  });

  @override
  State<StatefulWidget> createState() {
    return _IndexTabItemWidgetState();
  }
}

class _IndexTabItemWidgetState extends State<IndexTabItemWidget> {
  bool showFullText = true;

  @override
  Widget build(BuildContext context) {
    return WidgetSize(
      onChange: (size) {
        if (size.width < 50) {
          if (showFullText && StringUtil.isNotBlank(widget.omitText)) {
            setState(() {
              showFullText = false;
            });
          }
        } else {
          if (!showFullText) {
            setState(() {
              showFullText = true;
            });
          }
        }
      },
      child: Container(
        height: IndexAppBar.height,
        width: double.infinity,
        alignment: Alignment.center,
        child: Text(
          showFullText ? widget.text : widget.omitText!,
          style: widget.textStyle,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
