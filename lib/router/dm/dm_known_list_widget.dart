import 'package:flutter/material.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/provider/notice_provider.dart';
import 'package:nostrmo/provider/setting_provider.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:provider/provider.dart';

import '../../provider/dm_provider.dart';
import 'dm_notice_item_widget.dart';
import 'dm_session_list_item_widget.dart';

class DMKnownListWidget extends StatefulWidget {
  const DMKnownListWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _DMKnownListWidgetState();
  }
}

class _DMKnownListWidgetState extends State<DMKnownListWidget> {
  @override
  Widget build(BuildContext context) {
    final settingProvider = Provider.of<SettingProvider>(context);
    var _dmProvider = Provider.of<DMProvider>(context);
    var details = _dmProvider.knownList;
    var allLength = details.length;

    var _noticeProvider = Provider.of<NoticeProvider>(context);
    var notices = _noticeProvider.notices;
    bool hasNewNotice = _noticeProvider.hasNewMessage();
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
            if (settingProvider.hideRelayNotices != OpenStatus.CLOSE) {
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
        _dmProvider.query(queryAll: true);
      },
    );
  }
}
