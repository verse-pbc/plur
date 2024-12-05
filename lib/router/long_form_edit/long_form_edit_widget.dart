import 'package:flutter/material.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/editor/editor_mixin.dart';

class LongFormEditWidget extends StatefulWidget {
  const LongFormEditWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _LongFormEditWidgetState();
  }
}

class _LongFormEditWidgetState extends CustState<LongFormEditWidget>
    with EditorMixin {
  @override
  void initState() {
    super.initState();
    handleFocusInit();
  }

  @override
  Future<void> onReady(BuildContext context) async {}

  @override
  Widget doBuild(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }

  @override
  BuildContext getContext() {
    return context;
  }

  @override
  String? getPubkey() {
    return null;
  }

  @override
  List getTags() {
    return [];
  }

  @override
  List getTagsAddedWhenSend() {
    return [];
  }

  @override
  bool isDM() {
    return false;
  }

  @override
  void updateUI() {
    setState(() {});
  }
}
