import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/editor/zap_split_input_item_widget.dart';
import 'package:nostrmo/component/user/metadata_top_widget.dart';
import 'package:nostrmo/main.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../zap/zap_split_icon_widget.dart';
import 'search_mention_user_widget.dart';
import 'text_input_and_search_dialog.dart';

class ZapSplitInputWidget extends StatefulWidget {
  final List<EventZapInfo> eventZapInfos;

  const ZapSplitInputWidget(
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
    final themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize!;
    final localization = S.of(context);

    List<Widget> list = [];
    list.add(Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.only(right: Base.basePaddingHalf),
          child: ZapSplitIconWidget(titleFontSize + 2),
        ),
        Text(
          localization.Split_and_Transfer_Zap,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(child: Container()),
        MetadataTextBtn(text: localization.Add_User, onTap: addUser),
      ],
    ));

    list.add(const Divider());

    list.add(Container(
      margin: const EdgeInsets.only(bottom: Base.basePaddingHalf),
      child: Text(
        localization.Split_Zap_Tip,
        style: TextStyle(
          color: themeData.hintColor,
        ),
      ),
    ));

    for (var zapInfo in widget.eventZapInfos) {
      list.add(Container(
        margin: const EdgeInsets.only(top: Base.basePaddingHalf),
        child: ZapSplitInputItemWidget(
          zapInfo,
          recountWeightAndRefresh,
        ),
      ));
    }

    return Container(
      // color: Colors.red,
      padding: const EdgeInsets.only(
        left: Base.basePadding,
        right: Base.basePadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
    );
  }

  Future<void> addUser() async {
    final localization = S.of(context);
    var pubkey = await TextInputAndSearchDialog.show(
      context,
      localization.Search,
      localization.Please_input_user_pubkey,
      const SearchMentionUserWidget(),
      hintText: localization.User_Pubkey,
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
