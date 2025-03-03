import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';

import '../../data/metadata.dart';
import '../../generated/l10n.dart';
import '../../main.dart';

typedef ResultBuildFunc = Widget Function();

typedef HandleSearchFunc = void Function(String);

class SearchMentionWidget extends StatefulWidget {
  ResultBuildFunc resultBuildFunc;

  HandleSearchFunc handleSearchFunc;

  SearchMentionWidget({
    super.key,
    required this.resultBuildFunc,
    required this.handleSearchFunc,
  });

  @override
  State<StatefulWidget> createState() {
    return _SearchMentionWidgetState();
  }
}

class _SearchMentionWidgetState extends State<SearchMentionWidget>
    with WhenStopFunction {
  TextEditingController controller = TextEditingController();

  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      var hasText = StringUtil.isNotBlank(controller.text);
      if (!showSuffix && hasText) {
        setState(() {
          showSuffix = true;
        });
        return;
      } else if (showSuffix && !hasText) {
        setState(() {
          showSuffix = false;
        });
      }

      whenStop(checkInput);
    });
  }

  bool showSuffix = false;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var backgroundColor = themeData.scaffoldBackgroundColor;
    final localization = S.of(context);
    List<Widget> list = [];

    Widget? suffixWidget;
    if (showSuffix) {
      suffixWidget = GestureDetector(
        onTap: () {
          controller.text = "";
        },
        child: const Icon(Icons.close),
      );
    }
    list.add(TextField(
      autofocus: true,
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: localization.Please_input_search_content,
        suffixIcon: suffixWidget,
      ),
      onEditingComplete: checkInput,
    ));

    list.add(Expanded(
      child: Container(
        color: backgroundColor,
        child: widget.resultBuildFunc(),
      ),
    ));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: list,
    );
  }

  checkInput() {
    var text = controller.text;
    widget.handleSearchFunc(text);
  }
}
