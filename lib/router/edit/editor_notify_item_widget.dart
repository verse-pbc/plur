import 'package:flutter/material.dart';
import 'package:nostrmo/data/metadata.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
import 'package:provider/provider.dart';

import '../../component/user/simple_name_widget.dart';
import '../../consts/base.dart';

class EditorNotifyItem {
  String pubkey;

  bool selected;

  EditorNotifyItem({required this.pubkey, this.selected = true});
}

class EditorNotifyItemWidget extends StatefulWidget {
  EditorNotifyItem item;

  EditorNotifyItemWidget({required this.item});

  @override
  State<StatefulWidget> createState() {
    return _EditorNotifyItemWidgetState();
  }
}

class _EditorNotifyItemWidgetState extends State<EditorNotifyItemWidget> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var textColor = themeData.appBarTheme.titleTextStyle!.color;

    List<Widget> list = [];
    list.add(Selector<MetadataProvider, Metadata?>(
        builder: (context, metadata, child) {
      String name =
          SimpleNameWidget.getSimpleName(widget.item.pubkey, metadata);
      return Text(
        name,
        style: TextStyle(color: textColor),
      );
    }, selector: (_, provider) {
      return provider.getMetadata(widget.item.pubkey);
    }));

    list.add(SizedBox(
      width: 24,
      height: 24,
      child: Checkbox(
        value: widget.item.selected,
        onChanged: (value) {
          setState(() {
            widget.item.selected = !widget.item.selected;
          });
        },
        side: BorderSide(color: textColor!.withOpacity(0.6), width: 2),
      ),
    ));

    return Container(
      decoration: BoxDecoration(
        color: mainColor.withOpacity(0.65),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.only(
        left: Base.basePadding,
        right: Base.basePadding,
        top: Base.BASE_PADDING_HALF / 2,
        bottom: Base.BASE_PADDING_HALF / 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    );
  }
}
