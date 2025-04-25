import 'package:flutter/material.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/provider/notice_provider.dart';
import 'package:nostrmo/provider/settings_provider.dart';
import 'package:provider/provider.dart';

import '../../provider/dm_provider.dart';
import 'dm_notice_item_widget.dart';
import 'dm_session_list_item_widget.dart';

class DMKnownListWidget extends StatefulWidget {
  const DMKnownListWidget({super.key});

  @override
  State<StatefulWidget> createState() =>
      _DMKnownListWidgetState();
}

class _DMKnownListWidgetState extends State<DMKnownListWidget> {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dmProvider = Provider.of<DMProvider>(context, listen: false);
      dmProvider.query(queryAll: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    var dmProvider = Provider.of<DMProvider>(context);
    var details = dmProvider.knownList;
    var allLength = details.length;

    var noticeProvider = Provider.of<NoticeProvider>(context);
    var notices = noticeProvider.notices;
    bool hasNewNotice = noticeProvider.hasNewMessage();
    int flag = 0;
    if (notices.isNotEmpty) {
      allLength += 1;
      flag = 1;
    }

    return RefreshIndicator(
      child: ListView.builder(
        itemBuilder: (context, index) {
          if (index >= allLength) {
            return null;
          }

          if (index == 0 && flag > 0) {
            if (settingsProvider.hideRelayNotices != OpenStatus.close) {
              return Container();
            } else {
              return DMNoticeItemWidget(
                newestNotice: notices.last,
                hasNewMessage: hasNewNotice,
              );
            }
          } else {
            var detail = details[index - flag];
            return DMSessionListItemWidget(
              detail: detail,
            );
          }
        },
        itemCount: allLength,
      ),
      onRefresh: () async {
        dmProvider.query(queryAll: true);
      },
    );
  }
}
