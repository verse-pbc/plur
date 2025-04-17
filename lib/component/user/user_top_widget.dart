import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/nip05_valid_widget.dart';
import 'package:nostrmo/component/qrcode_dialog.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/component/webview_widget.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/table_mode_util.dart';

import '../../consts/base.dart';
import '../../data/user.dart';
import '../confirm_dialog.dart';
import '../image_widget.dart';
import '../image_preview_dialog.dart';
import '../zap/zap_bottom_sheet_widget.dart';
import 'follow_btn_widget.dart';

class UserTopWidget extends StatefulWidget {
  static double getPcBannerHeight(double maxHeight) {
    var height = maxHeight * 0.2;
    if (height > 200) {
      return 200;
    }

    return height;
  }

  final String pubkey;
  final User? user;
  // is local user
  final bool isLocal;
  final bool jumpable;
  final bool userPicturePreview;

  const UserTopWidget({
    super.key,
    required this.pubkey,
    this.user,
    this.isLocal = false,
    this.jumpable = false,
    this.userPicturePreview = false,
  });

  @override
  State<StatefulWidget> createState() {
    return _UserTopWidgetState();
  }
}

class _UserTopWidgetState extends State<UserTopWidget> {
  static const double imageBorder = 4;
  static const double imageWidth = 80;
  static const double halfImageWidth = 40;

  late String nip19PubKey;

  @override
  void initState() {
    super.initState();

    nip19PubKey = Nip19.encodePubKey(widget.pubkey);
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var scaffoldBackgroundColor = themeData.scaffoldBackgroundColor;
    var maxWidth = mediaDataCache.size.width;
    var largeFontSize = themeData.textTheme.bodyLarge!.fontSize;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final navHeight = statusBarHeight + 46; // status bar + nav bar height
    var bannerHeight = maxWidth / 3;

    if (TableModeUtil.isTableMode()) {
      bannerHeight =
          UserTopWidget.getPcBannerHeight(mediaDataCache.size.height);
    }

    String nip19Name = Nip19.encodeSimplePubKey(widget.pubkey);
    String displayName = "";
    if (widget.user != null) {
      if (StringUtil.isNotBlank(widget.user!.displayName)) {
        displayName = widget.user!.displayName!;
      } else if (StringUtil.isNotBlank(widget.user!.name)) {
        displayName = widget.user!.name!;
      }
    }

    Widget? bannerImage;
    if (widget.user != null && StringUtil.isNotBlank(widget.user!.banner)) {
      bannerImage = ImageWidget(
        url: widget.user!.banner!,
        width: maxWidth,
        height: bannerHeight,
        fit: BoxFit.cover,
      );
    }

    List<Widget> topBtnList = [
      Expanded(
        child: Container(),
      )
    ];

    if (!TableModeUtil.isTableMode() && widget.pubkey == nostr!.publicKey) {
      // is phont and local
      topBtnList.add(wrapBtn(MetadataIconBtn(
        iconData: Icons.qr_code_scanner,
        onTap: handleScanner,
      )));
    }

    topBtnList.add(wrapBtn(MetadataIconBtn(
      iconData: Icons.qr_code,
      onTap: () {
        QrcodeDialog.show(context, widget.pubkey);
      },
    )));

    if (!widget.isLocal) {
      if (widget.user != null &&
          (StringUtil.isNotBlank(widget.user!.lud06) ||
              StringUtil.isNotBlank(widget.user!.lud16))) {
        topBtnList.add(wrapBtn(MetadataIconBtn(
          onTap: openZapDialog,
          iconData: Icons.currency_bitcoin,
        )));
      }

      topBtnList.add(wrapBtn(MetadataIconBtn(
        iconData: Icons.mail,
        onTap: openDMSession,
      )));
      topBtnList.add(wrapBtn(FollowBtnWidget(
        pubkey: widget.pubkey,
        followedBorderColor: mainColor,
      )));
    }

    if (StringUtil.isBlank(displayName)) {
      displayName = nip19Name;
    }

    Widget userNameWidget = Container(
      width: double.maxFinite,
      margin: const EdgeInsets.only(
        left: Base.basePadding,
        right: Base.basePadding,
        bottom: Base.basePaddingHalf,
      ),
      child: Text.rich(
        TextSpan(
          text: displayName,
          style: TextStyle(
            fontSize: largeFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
    if (widget.jumpable) {
      userNameWidget = GestureDetector(
        onTap: jumpToUserRouter,
        child: userNameWidget,
      );
    }

    List<Widget> topList = [];
    topList.add(Container(
      width: maxWidth,
      height: bannerImage != null ? bannerHeight : 0,
      margin: EdgeInsets.only(top: navHeight),
      child: bannerImage,
    ));

    topList.add(Container(
      height: bannerImage != null
          ? 50
          : imageWidth + imageBorder * 2 + Base.basePadding * 2,
      margin: EdgeInsets.only(top: bannerImage != null ? 0 : Base.basePadding),
      child: Row(
        children: topBtnList,
      ),
    ));
    topList.add(userNameWidget);
    if (widget.user != null) {
      topList.add(MetadataIconDataComp(
        iconData: Icons.key,
        text: nip19PubKey,
        textBG: true,
        onTap: copyPubKey,
      ));
      if (StringUtil.isNotBlank(widget.user!.nip05)) {
        topList.add(MetadataIconDataComp(
          text: widget.user!.nip05!,
          leftWidget: Container(
            margin: const EdgeInsets.only(right: 2),
            child: Nip05ValidWidget(pubkey: widget.pubkey),
          ),
        ));
      }
      if (widget.user != null) {
        if (StringUtil.isNotBlank(widget.user!.website)) {
          topList.add(MetadataIconDataComp(
            iconData: Icons.link,
            text: widget.user!.website!,
            onTap: () {
              WebViewWidget.open(context, widget.user!.website!);
            },
          ));
        }
        if (StringUtil.isNotBlank(widget.user!.lud16)) {
          topList.add(MetadataIconDataComp(
            iconData: Icons.bolt,
            iconColor: Colors.orange,
            text: widget.user!.lud16!,
          ));
        }
      }
    }

    Widget userImageWidget = UserPicWidget(
      pubkey: widget.pubkey,
      width: imageWidth,
      user: widget.user,
    );
    if (widget.userPicturePreview) {
      userImageWidget = GestureDetector(
        onTap: userPicturePreview,
        child: userImageWidget,
      );
    } else if (widget.jumpable) {
      userImageWidget = GestureDetector(
        onTap: jumpToUserRouter,
        child: userImageWidget,
      );
    }

    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: topList,
        ),
        Positioned(
          left: Base.basePadding,
          top: bannerImage != null
              ? bannerHeight + navHeight - halfImageWidth
              : navHeight + Base.basePadding,
          child: Container(
            height: imageWidth + imageBorder * 2,
            width: imageWidth + imageBorder * 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(halfImageWidth + imageBorder),
              border: Border.all(
                width: imageBorder,
                color: scaffoldBackgroundColor,
              ),
            ),
            child: userImageWidget,
          ),
        )
      ],
    );
  }

  Widget wrapBtn(Widget child) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: child,
    );
  }

  copyPubKey() {
    final message = S.of(context).key_has_been_copy;
    Clipboard.setData(ClipboardData(text: nip19PubKey)).then((_) {
      BotToast.showText(text: message);
    });
  }

  void jumpToUserRouter() {
    RouterUtil.router(context, RouterPath.user, widget.pubkey);
  }

  void openDMSession() {
    var detail = dmProvider.findOrNewADetail(widget.pubkey);
    RouterUtil.router(context, RouterPath.dmDetail, detail);
  }

  Future<void> handleScanner() async {
    if (!mounted) return;
    var result = await RouterUtil.router(context, RouterPath.qrScanner);
    if (!mounted) return;
    if (StringUtil.isNotBlank(result)) {
      if (Nip19.isPubkey(result)) {
        var pubkey = Nip19.decode(result);
        RouterUtil.router(context, RouterPath.user, pubkey);
      } else if (NIP19Tlv.isNprofile(result)) {
        var nprofile = NIP19Tlv.decodeNprofile(result);
        if (nprofile != null) {
          RouterUtil.router(context, RouterPath.user, nprofile.pubkey);
        }
      } else if (Nip19.isNoteId(result)) {
        var noteId = Nip19.decode(result);
        RouterUtil.router(context, RouterPath.eventDetail, noteId);
      } else if (NIP19Tlv.isNevent(result)) {
        var nevent = NIP19Tlv.decodeNevent(result);
        if (nevent != null) {
          RouterUtil.router(context, RouterPath.eventDetail, nevent.id);
        }
      } else if (NIP19Tlv.isNrelay(result)) {
        var nrelay = NIP19Tlv.decodeNrelay(result);
        if (nrelay != null && mounted) {
          var dialogResult = await ConfirmDialog.show(
              context, S.of(context).Add_this_relay_to_local);
          if (dialogResult == true && mounted) {
            relayProvider.addRelay(nrelay.addr);
          }
        }
      } else if (result.indexOf("http") == 0) {
        if (!mounted) return;
        WebViewWidget.open(context, result);
      } else {
        if (!mounted) return;
        final message = S.of(context).Copy_success;
        await Clipboard.setData(ClipboardData(text: result));
        if (!mounted) return;
        BotToast.showText(text: message);
      }
    }
  }

  void userPicturePreview() {
    if (widget.user != null && StringUtil.isNotBlank(widget.user!.picture)) {
      List<ImageProvider> imageProviders = [];
      imageProviders.add(CachedNetworkImageProvider(widget.user!.picture!));

      MultiImageProvider multiImageProvider =
          MultiImageProvider(imageProviders, initialIndex: 0);

      ImagePreviewDialog.show(context, multiImageProvider,
          doubleTapZoomable: true, swipeDismissible: true);
    }
  }

  void openZapDialog() {
    List<EventZapInfo> list = [];
    String relayAddr = "";
    var relayListMetadata = userProvider.getRelayListMetadata(widget.pubkey);
    if (relayListMetadata != null &&
        relayListMetadata.writeAbleRelays.isNotEmpty) {
      relayAddr = relayListMetadata.writeAbleRelays.first;
    }
    list.add(EventZapInfo(widget.pubkey, relayAddr, 1));

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return ZapBottomSheetWidget(context, list);
      },
    );
  }
}

class MetadataIconBtn extends StatelessWidget {
  final void Function()? onTap;
  final void Function()? onLongPress;
  final IconData iconData;

  const MetadataIconBtn({
    super.key,
    required this.iconData,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    var decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        width: 1,
        color: themeData.textTheme.bodyMedium!.color ?? Colors.black,
      ),
    );
    var main = SizedBox(
      height: 28,
      width: 28,
      child: Icon(
        iconData,
        size: 18,
      ),
    );

    if (onTap != null || onLongPress != null) {
      // return Ink(
      //   decoration: decoration,
      //   child: InkWell(
      //     onTap: onTap,
      //     onLongPress: onLongPress,
      //     child: main,
      //   ),
      // );
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: decoration,
          child: main,
        ),
      );
    } else {
      return Container(
        decoration: decoration,
        child: main,
      );
    }
  }
}

class MetadataTextBtn extends StatelessWidget {
  final Function() onTap;
  final Function()? onLongPress;
  final String text;
  final Color? borderColor;

  const MetadataTextBtn({
    super.key,
    required this.text,
    required this.onTap,
    this.onLongPress,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        if (onLongPress != null) {
          onLongPress!();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: borderColor != null
              ? Border.all(width: 1, color: borderColor!)
              : Border.all(
                  width: 1,
                  color: themeData.textTheme.bodyMedium!.color ?? Colors.black,
                ),
        ),
        height: 32,
        padding: const EdgeInsets.only(left: 8, right: 8, bottom: 1),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: borderColor,
          ),
        ),
      ),
    );
  }
}

class MetadataIconDataComp extends StatelessWidget {
  final String text;
  final IconData? iconData;
  final Color? iconColor;
  final bool textBG;
  final Function? onTap;
  final Widget? leftWidget;

  const MetadataIconDataComp({
    super.key,
    required this.text,
    this.iconData = Icons.circle,
    this.leftWidget,
    this.iconColor,
    this.textBG = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    Color? cardColor = themeData.cardColor;
    if (cardColor == Colors.white) {
      cardColor = Colors.grey[300];
    }

    return Container(
      padding: const EdgeInsets.only(
        bottom: Base.basePaddingHalf,
        left: Base.basePadding,
        right: Base.basePadding,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (onTap != null) {
            onTap!();
          }
        },
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(
                right: Base.basePaddingHalf,
              ),
              child: leftWidget ??
                  Icon(
                    iconData ?? Icons.circle,
                    color: iconColor,
                    size: 16,
                  ),
            ),
            Expanded(
              child: Container(
                padding: textBG
                    ? const EdgeInsets.only(
                        left: Base.basePaddingHalf,
                        right: Base.basePaddingHalf,
                        top: 4,
                        bottom: 4,
                      )
                    : null,
                decoration: BoxDecoration(
                  color: textBG ? cardColor : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
