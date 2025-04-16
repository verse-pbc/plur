import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/user/name_widget.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/data/user.dart';
import 'package:nostrmo/provider/user_provider.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../util/lightning_util.dart';
import '../../util/router_util.dart';
import '../../util/theme_util.dart';
import '../../util/zap_action.dart';
import '../user/user_top_widget.dart';

class ZapsSendDialog extends StatefulWidget {
  final Map<String, int> pubkeyZapNumbers;

  final List<EventZapInfo> zapInfos;

  final String? comment;

  const ZapsSendDialog({
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
  final double height = 50;

  final double rightHeight = 40;

  final double rightWidth = 80;

  final String pubkey;

  final int zapNumber;

  final String? invoiceCode;

  final bool? sent;

  final Function(String, String, int) sendZapFunction;

  const ZapsSendDialogItem(this.pubkey, this.zapNumber, this.sendZapFunction,
      {super.key, this.invoiceCode, this.sent});

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    return Selector<UserProvider, User?>(
        builder: (context, user, child) {
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
              user: user,
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
              text: localization.send,
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
      return provider.getUser(pubkey);
    });
  }
}
