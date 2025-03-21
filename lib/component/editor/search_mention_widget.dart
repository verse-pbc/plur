import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';

import '../../generated/l10n.dart';

typedef ResultBuildFunc = Widget Function();

typedef HandleSearchFunc = void Function(String);

class SearchMentionWidget extends StatefulWidget {
  final ResultBuildFunc resultBuildFunc;

  final HandleSearchFunc handleSearchFunc;

  const SearchMentionWidget({
    super.key,
    required this.resultBuildFunc,
    required this.handleSearchFunc,
  });

  @override
  State<StatefulWidget> createState() {
    return _SearchMentionWidgetState();
  }
}

class _SearchMentionWidgetState extends State<SearchMentionWidget> {
  final _controller = TextEditingController();
  bool _showsClearButton = false;
  Timer? _debouncer;

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      final hasText = StringUtil.isNotBlank(_controller.text);
      if (_showsClearButton != hasText) {
        setState(() {
          _showsClearButton = hasText;
        });
      }

      _debouncer?.cancel();
      _debouncer = Timer(const Duration(milliseconds: 200), () {
        _checkInput();
      });
    });
  }

  @override
  void dispose() {
    _debouncer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var backgroundColor = themeData.scaffoldBackgroundColor;
    final localization = S.of(context);
    List<Widget> list = [];

    Widget? suffixWidget;
    if (_showsClearButton) {
      suffixWidget = GestureDetector(
        onTap: () {
          _controller.text = "";
        },
        child: const Icon(Icons.close),
      );
    }
    list.add(TextField(
      autofocus: true,
      controller: _controller,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: localization.Please_input_search_content,
        suffixIcon: suffixWidget,
      ),
      onEditingComplete: _checkInput,
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

  _checkInput() {
    widget.handleSearchFunc(_controller.text);
  }
}
