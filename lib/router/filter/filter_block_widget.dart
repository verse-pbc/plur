import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/filter_provider.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';

class FilterBlockWidget extends StatefulWidget {
  const FilterBlockWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _FilterBlockWidgetState();
  }
}

class _FilterBlockWidgetState extends State<FilterBlockWidget> {
  @override
  Widget build(BuildContext context) {
    var filterProvider = Provider.of<FilterProvider>(context);
    var blockMap = filterProvider.blocks;
    var blocks = blockMap.keys.toList();
    return ListView.builder(
      itemBuilder: (context, index) {
        var pubkey = blocks[index];
        return FilterBlockItemWidget(pubkey: pubkey);
      },
      itemCount: blocks.length,
    );
  }
}

class FilterBlockItemWidget extends StatelessWidget {
  String pubkey;

  FilterBlockItemWidget({super.key, required this.pubkey});

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    final themeData = Theme.of(context);
    var cardColor = themeData.cardColor;

    var nip19Pubkey = Nip19.encodePubKey(pubkey);
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: nip19Pubkey)).then((_) {
          BotToast.showText(text: localization.key_has_been_copy);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: Base.basePaddingHalf),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(Base.basePadding),
        child: Row(children: [
          Expanded(child: Text(nip19Pubkey)),
          GestureDetector(
            onTap: delBlock,
            child: Container(
              margin: const EdgeInsets.only(left: Base.basePaddingHalf),
              child: const Icon(
                Icons.delete,
              ),
            ),
          )
        ]),
      ),
    );
  }

  void delBlock() {
    filterProvider.removeBlock(pubkey);
  }
}
