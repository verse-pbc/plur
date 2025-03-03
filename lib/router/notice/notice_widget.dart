import 'package:flutter/material.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/main.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../consts/router_path.dart';
import '../../generated/l10n.dart';
import '../../provider/notice_provider.dart';
import '../../util/router_util.dart';
import '../edit/editor_widget.dart';
import 'notice_list_item_widget.dart';

class NoticeWidget extends StatefulWidget {
  const NoticeWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _NoticeWidgetState();
  }
}

class _NoticeWidgetState extends State<NoticeWidget> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;
    final localization = S.of(context);

    var noticeProvider = Provider.of<NoticeProvider>(context);
    var notices = noticeProvider.notices;
    var length = notices.length;

    Widget? main;
    if (length == 0) {
      main = Center(
        child: GestureDetector(
          onTap: () {
            EditorWidget.open(context);
          },
          child: Text(localization.Notices),
        ),
      );
    } else {
      main = ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          var notice = notices[length - 1 - index];
          return NoticeListItemWidget(
            notice: notice,
          );
        },
        itemCount: length,
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        title: Text(
          localization.Notices,
          style: TextStyle(
            fontSize: bodyLargeFontSize,
          ),
        ),
      ),
      body: main,
    );
  }
}
