import 'package:flutter/material.dart';
import 'package:nostr_sdk/event_relation.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/editor/zap_split_input_item_component.dart';
import 'package:nostrmo/component/user/metadata_top_component.dart';
import 'package:nostrmo/main.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../zap/zap_split_icon_component.dart';
import 'search_mention_user_component.dart';
import 'text_input_and_search_dialog.dart';

class ZapSplitInputWidget extends StatefulWidget {
  List<EventZapInfo> eventZapInfos;

  ZapSplitInputWidget(
    this.eventZapInfos, {super.key}
  );

  @override
  State<StatefulWidget> createState() {
    return _ZapSplitInputWidgetState();
  }
}

class _ZapSplitInputWidgetState extends State<ZapSplitInputWidget> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize!;
    var s = S.of(context);

    List<Widget> list = [];
    list.add(Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.only(right: Base.BASE_PADDING_HALF),
          child: ZapSplitIconWidget(titleFontSize + 2),
        ),
        Text(
          s.Split_and_Transfer_Zap,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(child: Container()),
        MetadataTextBtn(text: s.Add_User, onTap: addUser),
      ],
    ));

    list.add(const Divider());

    list.add(Container(
      margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      child: Text(
        s.Split_Zap_Tip,
        style: TextStyle(
          color: themeData.hintColor,
        ),
      ),
    ));

    for (var zapInfo in widget.eventZapInfos) {
      list.add(Container(
        margin: const EdgeInsets.only(top: Base.BASE_PADDING_HALF),
        child: ZapSplitInputItemWidget(
          zapInfo,
          recountWeightAndRefresh,
        ),
      ));
    }

    return Container(
      // color: Colors.red,
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
    );
  }

  Future<void> addUser() async {
    var s = S.of(context);
    var pubkey = await TextInputAndSearchDialog.show(
      context,
      s.Search,
      s.Please_input_user_pubkey,
      const SearchMentionUserWidget(),
      hintText: s.User_Pubkey,
    );

    if (StringUtil.isNotBlank(pubkey)) {
      String relay = "";
      var relayListMetadata = metadataProvider.getRelayListMetadata(pubkey!);
      if (relayListMetadata != null &&
          relayListMetadata.writeAbleRelays.isNotEmpty) {
        relay = relayListMetadata.writeAbleRelays.first;
      }

      widget.eventZapInfos.add(EventZapInfo(pubkey, relay, 0.5));
      recountWeightAndRefresh();
    }
  }

  void recountWeightAndRefresh() {
    double totalWeight = 0;
    for (var zapInfo in widget.eventZapInfos) {
      totalWeight += zapInfo.weight;
    }

    for (var zapInfo in widget.eventZapInfos) {
      zapInfo.weight =
          double.parse((zapInfo.weight / totalWeight).toStringAsFixed(2));
    }

    setState(() {});
  }
}
