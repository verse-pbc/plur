import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../data/metadata.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/metadata_provider.dart';
import '../../util/router_util.dart';
import '../../util/zap_action.dart';
import '../content/content_str_link_widget.dart';

class GenLnbcWidget extends StatefulWidget {
  const GenLnbcWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _GenLnbcWidgetState();
  }
}

class _GenLnbcWidgetState extends State<GenLnbcWidget> {
  late TextEditingController controller;
  late TextEditingController commentController;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    commentController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<MetadataProvider, Metadata?>(
      builder: (context, metadata, child) {
        final themeData = Theme.of(context);
        Color cardColor = themeData.cardColor;
        var mainColor = themeData.primaryColor;
        var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
        final localization = S.of(context);
        if (metadata == null ||
            (StringUtil.isBlank(metadata.lud06) &&
                StringUtil.isBlank(metadata.lud16))) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localization.Lnurl_and_Lud16_can_t_found,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(Base.basePadding),
                  child: ContentStrLinkWidget(
                    str: localization.Add_now,
                    onTap: () async {
                      await RouterUtil.router(
                          context, RouterPath.PROFILE_EDITOR, metadata);
                      metadataProvider.update(nostr!.publicKey);
                    },
                  ),
                )
              ],
            ),
          );
        }

        List<Widget> list = [];

        list.add(Container(
          margin: const EdgeInsets.only(bottom: Base.basePadding),
          child: Text(
            localization.Input_Sats_num_to_gen_lightning_invoice,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: titleFontSize,
            ),
          ),
        ));

        list.add(Container(
          margin: const EdgeInsets.only(bottom: Base.basePadding),
          child: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 1,
            autofocus: true,
            decoration: InputDecoration(
              hintText: localization.Input_Sats_num,
              border: const OutlineInputBorder(borderSide: BorderSide(width: 1)),
            ),
          ),
        ));

        list.add(TextField(
          controller: commentController,
          minLines: 1,
          maxLines: 1,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "${localization.Input_Comment} (${localization.Optional})",
            border: const OutlineInputBorder(borderSide: BorderSide(width: 1)),
          ),
        ));

        list.add(Expanded(child: Container()));

        list.add(Container(
          margin: const EdgeInsets.only(
            top: Base.basePadding,
            bottom: 6,
          ),
          child: Ink(
            decoration: BoxDecoration(color: mainColor),
            child: InkWell(
              onTap: () {
                _onConfirm(metadata.pubkey!);
              },
              highlightColor: mainColor.withOpacity(0.2),
              child: Container(
                color: mainColor,
                height: 40,
                alignment: Alignment.center,
                child: Text(
                  S.of(context).Confirm,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ));

        var main = Container(
          padding: const EdgeInsets.all(Base.basePadding),
          decoration: BoxDecoration(
            color: cardColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: list,
          ),
        );

        return main;
      },
      selector: (_, provider) {
        return provider.getMetadata(nostr!.publicKey);
      },
    );
  }

  Future<void> _onConfirm(String pubkey) async {
    var text = controller.text;
    var num = int.tryParse(text);
    if (num == null) {
      BotToast.showText(text: S.of(context).Number_parse_error);
      return;
    }

    var comment = commentController.text;
    log("comment $comment");
    var lnbcStr =
        await ZapAction.genInvoiceCode(context, num, pubkey, comment: comment);
    if (StringUtil.isNotBlank(lnbcStr)) {
      RouterUtil.back(context, lnbcStr);
    }
  }
}
