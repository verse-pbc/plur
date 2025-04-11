import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/util/colors_util.dart';

import '../../consts/base.dart';
import '../../util/cashu_util.dart';

class ContentCashuWidget extends StatelessWidget {
  final String cashuStr;

  final Tokens tokens;

  const ContentCashuWidget({
    super.key,
    required this.tokens,
    required this.cashuStr,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var cardColor = themeData.cardColor;
    double largeFontSize = 20;

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
            margin: const EdgeInsets.only(
              bottom: 15,
            ),
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: Base.basePadding),
                  child: Image.asset(
                    "assets/imgs/cashu_logo.png",
                    width: 50,
                    height: 50,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          margin:
                              const EdgeInsets.only(right: Base.basePaddingHalf),
                          child: Text(
                            tokens.totalAmount().toString(),
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
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      child: Text(
                        tokens.memo != null ? tokens.memo! : "",
                        style: TextStyle(color: hintColor),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          SizedBox(
            width: double.maxFinite,
            child: InkWell(
              onTap: () async {
                // call to pay
                CashuUtil.goTo(context, cashuStr);
              },
              child: Container(
                color: ColorsUtil.hexToColor("#dcc099"),
                height: 42,
                alignment: Alignment.center,
                child: const Text(
                  "Claim",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
