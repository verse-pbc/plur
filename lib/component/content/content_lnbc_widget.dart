
import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/util/lightning_util.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';

class ContentLnbcWidget extends StatelessWidget {
  String lnbc;

  ContentLnbcWidget({super.key, required this.lnbc});

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    final themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var cardColor = themeData.cardColor;
    double largeFontSize = 20;

    var numStr = localization.Any;
    var num = ZapInfoUtil.getNumFromStr(lnbc);
    if (num > 0) {
      numStr = num.toString();
    }

    return Container(
      margin: const EdgeInsets.all(Base.basePadding),
      padding: const EdgeInsets.all(Base.basePadding * 2),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 0),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.only(bottom: Base.basePadding),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 1,
                  color: hintColor,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bolt,
                  color: Colors.orange,
                ),
                Text(localization.Lightning_Invoice),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(
              top: Base.basePadding,
              bottom: Base.basePadding,
            ),
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: Base.basePaddingHalf),
                  child: Text(
                    numStr,
                    style: TextStyle(
                      fontSize: largeFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  "sats",
                  style: TextStyle(
                    fontSize: largeFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.maxFinite,
            child: InkWell(
              onTap: () async {
                // call to pay
                if (num > 0) {
                  LightningUtil.goToPay(context, lnbc, zapNum: num);
                }
              },
              child: Container(
                color: Colors.black,
                height: 50,
                alignment: Alignment.center,
                child: Text(
                  localization.Pay,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
