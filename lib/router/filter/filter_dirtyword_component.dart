import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/filter_provider.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';
import 'package:nostr_sdk/utils/string_util.dart';

class FilterDirtywordWidget extends StatefulWidget {
  const FilterDirtywordWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _FilterDirtywordWidgetState();
  }
}

class _FilterDirtywordWidgetState extends State<FilterDirtywordWidget> {
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var filterProvider = Provider.of<FilterProvider>(context);
    var dirtywordList = filterProvider.dirtywordList;

    List<Widget> list = [];
    for (var dirtyword in dirtywordList) {
      list.add(FilterDirtywordItemWidget(word: dirtyword));
    }

    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(Base.BASE_PADDING),
            child: Wrap(
              spacing: Base.BASE_PADDING,
              runSpacing: Base.BASE_PADDING,
              children: list,
            ),
          ),
        ),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.abc),
            hintText: s.Input_dirtyword,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: addDirtyWord,
            ),
          ),
        ),
      ],
    );
  }

  void addDirtyWord() {
    var word = controller.text;
    if (StringUtil.isBlank(word)) {
      BotToast.showText(text: S.of(context).Word_can_t_be_null);
      return;
    }

    filterProvider.addDirtyword(word);
    controller.clear();
    FocusScope.of(context).unfocus();
  }
}

class FilterDirtywordItemWidget extends StatefulWidget {
  String word;

  FilterDirtywordItemWidget({super.key, required this.word});

  @override
  State<StatefulWidget> createState() {
    return _FilterDirtywordItemWidgetState();
  }
}

class _FilterDirtywordItemWidgetState extends State<FilterDirtywordItemWidget> {
  bool showDel = false;

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var mainColor = themeData.primaryColor;
    var fontColor = themeData.appBarTheme.titleTextStyle!.color;

    List<Widget> list = [
      GestureDetector(
        onTap: () {
          setState(() {
            showDel = true;
          });
        },
        child: Container(
          padding: const EdgeInsets.only(
            left: Base.BASE_PADDING_HALF,
            right: Base.BASE_PADDING_HALF,
            top: 4,
            bottom: 4,
          ),
          decoration: BoxDecoration(
            color: mainColor.withOpacity(0.8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.word,
            style: TextStyle(
              color: fontColor,
            ),
          ),
        ),
      )
    ];

    if (showDel) {
      list.add(GestureDetector(
        onTap: () {
          filterProvider.removeDirtyword(widget.word);
        },
        child: const Icon(
          Icons.delete,
          color: Colors.red,
        ),
      ));
    }

    return Stack(
      alignment: Alignment.center,
      children: list,
    );
  }
}
