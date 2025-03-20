import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/user/name_widget.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/data/metadata.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../util/lightning_util.dart';
import '../../util/router_util.dart';
import '../../util/theme_util.dart';
import '../../util/zap_action.dart';
import '../user/metadata_top_widget.dart';

class ZapsSendDialog extends StatefulWidget {
  Map<String, int> pubkeyZapNumbers;

  List<EventZapInfo> zapInfos;

  String? comment;

  ZapsSendDialog({
    super.key, 
    required this.zapInfos,
    required this.pubkeyZapNumbers,
    this.comment,
  });

  @override
  State<StatefulWidget> createState() {
    return _ZapsSendDialog();
  }
}

class _ZapsSendDialog extends CustState<ZapsSendDialog> {
  Map<String, String> invoicesMap = {};

  Map<String, bool> sentMap = {};

  @override
  Widget doBuild(BuildContext context) {
    final themeData = Theme.of(context);
    Color cardColor = themeData.cardColor;

    List<Widget> list = [];
    for (var zapInfo in widget.zapInfos) {
      var pubkey = zapInfo.pubkey;
      var invoiceCode = invoicesMap[pubkey];
      var sent = sentMap[pubkey];
      var zapNumber = widget.pubkeyZapNumbers[pubkey];
      if (zapNumber == null) {
        continue;
      }

      list.add(Container(
        margin: const EdgeInsets.only(
          top: Base.basePaddingHalf,
          bottom: Base.basePaddingHalf,
        ),
        child: ZapsSendDialogItem(
          pubkey,
          zapNumber,
          sendZapFunction,
          invoiceCode: invoiceCode,
          sent: sent,
        ),
      ));
    }

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

    return Scaffold(
      backgroundColor: ThemeUtil.getDialogCoverColor(themeData),
      body: FocusScope(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            RouterUtil.back(context);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              left: Base.basePadding,
              right: Base.basePadding,
            ),
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {},
              child: main,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    invoicesMap.clear();
    sentMap.clear();

    for (var zapInfo in widget.zapInfos) {
      var pubkey = zapInfo.pubkey;
      var zapNum = widget.pubkeyZapNumbers[pubkey];
      if (zapNum == null) {
        continue;
      }

      var invoiceCode = await ZapAction.genInvoiceCode(context, zapNum, pubkey);
      if (StringUtil.isNotBlank(invoiceCode)) {
        setState(() {
          invoicesMap[pubkey] = invoiceCode!;
        });
      }
    }
  }

  void sendZapFunction(String pubkey, String invoiceCode, int zapNum) {
    LightningUtil.goToPay(context, invoiceCode, zapNum: zapNum);
    setState(() {
      sentMap[pubkey] = true;
    });
  }
}

class ZapsSendDialogItem extends StatelessWidget {
  double height = 50;

  double rightHeight = 40;

  double rightWidth = 80;

  String pubkey;

  int zapNumber;

  String? invoiceCode;

  bool? sent;

  Function(String, String, int) sendZapFunction;

  ZapsSendDialogItem(this.pubkey, this.zapNumber, this.sendZapFunction,
      {super.key, this.invoiceCode, this.sent});

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    return Selector<MetadataProvider, Metadata?>(
        builder: (context, metadata, child) {
      var userPicComp = UserPicWidget(pubkey: pubkey, width: height);

      var nameColum = Container(
        margin: const EdgeInsets.only(
          left: Base.basePadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NameWidget(
              pubkey: pubkey,
              metadata: metadata,
            ),
            Text(
              "$zapNumber Sats",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      );

      Widget rightComp = SizedBox(
        height: rightHeight,
        width: rightWidth,
        child: const Icon(
          Icons.done,
          color: Colors.green,
        ),
      );
      if (sent != true && invoiceCode != null) {
        rightComp = GestureDetector(
          child: SizedBox(
            height: rightHeight,
            width: rightWidth,
            child: MetadataTextBtn(
              text: localization.Send,
              onTap: () {
                sendZapFunction(pubkey, invoiceCode!, zapNumber);
              },
            ),
          ),
        );
      } else if (invoiceCode == null) {
        rightComp = SizedBox(
          height: rightHeight,
          width: rightWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: rightHeight,
                height: rightHeight,
                child: const CircularProgressIndicator(),
              ),
            ],
          ),
        );
      }

      return Row(
        children: [
          userPicComp,
          nameColum,
          Expanded(child: Container()),
          rightComp,
        ],
      );
    }, selector: (context, provider) {
      return provider.getMetadata(pubkey);
    });
  }
}
