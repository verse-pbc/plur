import 'dart:typed_data';
import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/user/name_widget.dart';
import 'package:nostrmo/component/user/metadata_top_widget.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/data/metadata.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../consts/base.dart';
import '../generated/l10n.dart';
import '../main.dart';
import '../provider/metadata_provider.dart';
import '../util/router_util.dart';
import '../util/store_util.dart';
import '../util/theme_util.dart';
import 'image_widget.dart';

class QrcodeDialog extends StatefulWidget {
  String pubkey;

  QrcodeDialog({required this.pubkey});

  static Future<String?> show(BuildContext context, String pubkey) async {
    return await showDialog<String>(
        context: context,
        useRootNavigator: false,
        builder: (_context) {
          return QrcodeDialog(
            pubkey: pubkey,
          );
        });
  }

  @override
  State<StatefulWidget> createState() {
    return _QrcodeDialog();
  }
}

class _QrcodeDialog extends State<QrcodeDialog> {
  static const double IMAGE_WIDTH = 40;
  static const double QR_WIDTH = 200;

  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    Color cardColor = themeData.cardColor;
    var hintColor = themeData.hintColor;

    List<Widget> list = [];
    var nip19Pubkey = Nip19.encodePubKey(widget.pubkey);
    Widget topWidget = Selector<MetadataProvider, Metadata?>(
      builder: (context, metadata, child) {
        Widget userImageWidget = UserPicWidget(
          pubkey: widget.pubkey,
          width: IMAGE_WIDTH,
          metadata: metadata,
        );

        Widget userNameWidget = NameWidget(
          pubkey: widget.pubkey,
          metadata: metadata,
        );

        return Container(
          width: QR_WIDTH,
          margin: const EdgeInsets.only(
            left: Base.basePaddingHalf,
            right: Base.basePaddingHalf,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              userImageWidget,
              Container(
                margin: const EdgeInsets.only(left: Base.basePaddingHalf),
                child: Container(
                  width: QR_WIDTH - IMAGE_WIDTH - Base.basePaddingHalf,
                  child: userNameWidget,
                ),
              ),
            ],
          ),
        );
      },
      selector: (content, _provider) {
        return _provider.getMetadata(widget.pubkey);
      },
    );
    list.add(topWidget);
    list.add(Container(
      margin: const EdgeInsets.only(
        top: Base.basePadding,
        bottom: Base.basePadding,
        left: Base.basePaddingHalf,
        right: Base.basePaddingHalf,
      ),
      child: PrettyQr(
        data: nip19Pubkey,
        size: QR_WIDTH,
        elementColor: themeData.textTheme.bodyMedium!.color ?? Colors.black,
        image: AssetImage("assets/imgs/logo/logo512.png"),
      ),
    ));
    list.add(GestureDetector(
      onTap: () {
        _doCopy(nip19Pubkey);
      },
      child: Container(
        width: QR_WIDTH + Base.basePaddingHalf * 2,
        padding: EdgeInsets.all(Base.basePaddingHalf),
        decoration: BoxDecoration(
          color: hintColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SelectableText(
          nip19Pubkey,
          onTap: () {
            _doCopy(nip19Pubkey);
          },
        ),
      ),
    ));

    var main = Stack(
      children: [
        Screenshot(
          controller: screenshotController,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: list,
            ),
          ),
        ),
        Positioned(
          right: Base.basePaddingHalf,
          top: Base.basePaddingHalf,
          child: MetadataIconBtn(
            iconData: Icons.share,
            onTap: onShareTap,
          ),
        ),
      ],
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
      BotToast.showText(text: S.of(context).key_has_been_copy);
    });
  }

  void onShareTap() {
    screenshotController.capture().then((Uint8List? imageData) async {
      if (imageData != null) {
        var tempFile = await StoreUtil.saveBS2TempFile(
          "png",
          imageData,
        );
        Share.shareXFiles([XFile(tempFile)]);
      }
    }).catchError((onError) {
      log("onShareTap error $onError");
    });
  }
}
