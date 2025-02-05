import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../component/appbar4stack.dart';
import '../../component/cust_state.dart';
import '../../consts/base.dart';
import '../../consts/coffee_ids.dart';
import '../../generated/l10n.dart';
import '../../main.dart';

class DonateWidget extends StatefulWidget {
  const DonateWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _DonateWidgetState();
  }
}

class _DonateWidgetState extends CustState<DonateWidget> {
  @override
  Widget doBuild(BuildContext context) {
    final localization = S.of(context);

    final themeData = Theme.of(context);
    var cardColor = themeData.cardColor;

    Color? appbarBackgroundColor = Colors.transparent;
    var appBar = Appbar4Stack(
      backgroundColor: appbarBackgroundColor,
      title: Text(
        localization.Donate,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    List<Widget> list = [];
    list.add(const Icon(
      Icons.coffee_outlined,
      size: 160,
      // color: mainColor,
    ));

    list.add(Container(
      margin: const EdgeInsets.only(
        bottom: 40,
      ),
      child: Text(localization.Buy_me_a_coffee),
    ));

    list.add(Container(
      margin: const EdgeInsets.only(
        bottom: 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _DonateButtonWidget(
            name: "X1",
            onTap: () {
              buy(CoffeeIds.COFFEE1);
            },
            price: price1,
          ),
          _DonateButtonWidget(
            name: "X2",
            onTap: () {
              buy(CoffeeIds.COFFEE2);
            },
            price: price2,
          ),
        ],
      ),
    ));

    list.add(Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _DonateButtonWidget(
          name: "X5",
          onTap: () {
            buy(CoffeeIds.COFFEE5);
          },
          price: price5,
        ),
        _DonateButtonWidget(
          name: "X10",
          onTap: () {
            buy(CoffeeIds.COFFEE2);
          },
          price: price10,
        ),
      ],
    ));

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: mediaDataCache.size.width,
            height: mediaDataCache.size.height - mediaDataCache.padding.top,
            margin: EdgeInsets.only(top: mediaDataCache.padding.top),
            child: Container(
              color: cardColor,
              child: Center(
                child: SizedBox(
                  width: mediaDataCache.size.width * 0.8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: list,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: mediaDataCache.padding.top,
            child: SizedBox(
              width: mediaDataCache.size.width,
              child: appBar,
            ),
          ),
        ],
      ),
    );
  }

  String price1 = "";
  String price2 = "";
  String price5 = "";
  String price10 = "";

  Future<void> updateIAPItems() async {
    var list = await FlutterInappPurchase.instance.getProducts([
      CoffeeIds.COFFEE1,
      CoffeeIds.COFFEE2,
      CoffeeIds.COFFEE5,
      CoffeeIds.COFFEE10
    ]);

    for (var item in list) {
      if (StringUtil.isNotBlank(item.price) &&
          item.productId == CoffeeIds.COFFEE1) {
        price1 = item.localizedPrice!;
      } else if (StringUtil.isNotBlank(item.price) &&
          item.productId == CoffeeIds.COFFEE2) {
        price2 = item.localizedPrice!;
      } else if (StringUtil.isNotBlank(item.price) &&
          item.productId == CoffeeIds.COFFEE5) {
        price5 = item.localizedPrice!;
      } else if (StringUtil.isNotBlank(item.price) &&
          item.productId == CoffeeIds.COFFEE10) {
        price10 = item.localizedPrice!;
      }
    }
    setState(() {});
  }

  Future<void> buy(String id) async {
    await FlutterInappPurchase.instance.requestPurchase(id);
  }

  @override
  Future<void> onReady(BuildContext context) async {
    updateIAPItems();
  }
}

class _DonateButtonWidget extends StatelessWidget {
  String name;

  Function onTap;

  String price;

  _DonateButtonWidget({
    super.key,
    required this.name,
    required this.onTap,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var textColor = themeData.textTheme.bodyMedium!.color;
    var largeTextSize = themeData.textTheme.bodyLarge!.fontSize;

    return Container(
      margin: const EdgeInsets.only(
        left: 30,
        right: 30,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () {
              onTap();
            },
            style: ButtonStyle(
              side: MaterialStateProperty.all(BorderSide(
                width: 1,
                color: hintColor.withOpacity(0.4),
              )),
            ),
            child: Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              child: Text(
                name,
                style: TextStyle(
                  fontSize: largeTextSize,
                  color: textColor,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: Base.BASE_PADDING_HALF),
            child: Text(price),
          ),
        ],
      ),
    );
  }
}
