import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../consts/base.dart';
import '../generated/l10n.dart';
import '../util/router_util.dart';
import '../util/theme_util.dart';

class LightningQrcodeDialog extends StatefulWidget {
  final String? title;

  final String text;

  const LightningQrcodeDialog({
    super.key,
    this.title,
    required this.text,
  });

  static Future<bool?> show(BuildContext context, String text,
      {String? content, String? title}) async {
    return await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        return LightningQrcodeDialog(
          text: text,
          title: title,
        );
      },
    );
  }

  @override
  State<StatefulWidget> createState() {
    return _LightningQrcodeDialog();
  }
}

class _LightningQrcodeDialog extends State<LightningQrcodeDialog> {
  static const double qrWidth = 200;

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    final themeData = Theme.of(context);
    Color cardColor = themeData.cardColor;
    var hintColor = themeData.hintColor;

    List<Widget> list = [];
    if (widget.title == null) {
      list.add(Text(localization.Use_lightning_wallet_scan_and_send_sats));
    } else {
      if (StringUtil.isNotBlank(widget.title)) {
        list.add(Text(localization.Use_lightning_wallet_scan_and_send_sats));
      }
    }
    list.add(Container(
      margin: const EdgeInsets.only(
        top: Base.basePadding,
        bottom: Base.basePadding,
        left: Base.basePaddingHalf,
        right: Base.basePaddingHalf,
      ),
          child: PrettyQrView.data(
            data: widget.text,
          ),
    ));
    list.add(GestureDetector(
      onTap: () {
        _doCopy(widget.text);
      },
      child: Container(
        padding: const EdgeInsets.all(Base.basePaddingHalf),
        margin: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: Base.basePaddingHalf,
        ),
        decoration: BoxDecoration(
          color: hintColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SelectableText(
          widget.text,
          onTap: () {
            _doCopy(widget.text);
          },
        ),
      ),
    ));

    var main = Container(
      width: qrWidth + 200,
      padding: const EdgeInsets.only(
        top: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        color: cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    );

    return Scaffold(
      backgroundColor: ThemeUtil.getDialogCoverColor(themeData),
      body: FocusScope(
        // autofocus: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            RouterUtil.back(context);
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
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

  void _doCopy(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      if (!mounted) return;
      BotToast.showText(text: S.of(context).Copy_success);
    });
  }
}
