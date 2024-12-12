import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_sdk/nip19/nip19_tlv.dart';
import 'package:nostr_sdk/relay/relay_status.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/router/relays/relay_speed_widget.dart';
import 'package:nostrmo/util/router_util.dart';

import '../../consts/base.dart';
import '../../consts/client_connected.dart';
import '../../generated/l10n.dart';

class RelaysItemWidget extends StatefulWidget {
  String addr;

  RelayStatus relayStatus;

  bool editable;

  String rwText;

  RelaysItemWidget({
    super.key,
    required this.addr,
    required this.relayStatus,
    this.editable = true,
    this.rwText = "",
  });

  @override
  State<StatefulWidget> createState() {
    return _RelaysItemWidgetState();
  }
}

class _RelaysItemWidgetState extends State<RelaysItemWidget> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var smallFontSize = themeData.textTheme.bodySmall!.fontSize;
    var cardColor = themeData.cardColor;
    Color borderLeftColor = Colors.green;
    if (widget.relayStatus.connected == ClientConneccted.UN_CONNECT) {
      borderLeftColor = Colors.red;
    } else if (widget.relayStatus.connected == ClientConneccted.CONNECTING) {
      borderLeftColor = Colors.yellow;
    }

    List<Widget> list = [];
    Widget leftWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 2),
          child: Text(StringUtil.breakWord(widget.addr)),
        ),
        Row(
          children: [
            Container(
              margin: const EdgeInsets.only(right: Base.BASE_PADDING),
              child: RelaysItemNumWidget(
                iconData: Icons.mail,
                num: widget.relayStatus.noteReceived,
              ),
            ),
            RelaysItemNumWidget(
              iconColor: Colors.red,
              iconData: Icons.error,
              num: widget.relayStatus.error,
            ),
            Container(
              margin: const EdgeInsets.only(
                left: Base.BASE_PADDING,
              ),
              child: Text(
                widget.rwText,
                style: TextStyle(
                  fontSize: smallFontSize,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    if (widget.editable) {
      list.add(Expanded(
        child: leftWidget,
      ));

      list.add(RelaySpeedWidget(widget.addr));

      list.add(GestureDetector(
        onTap: () {
          var text = NIP19Tlv.encodeNrelay(Nrelay(widget.addr));
          Clipboard.setData(ClipboardData(text: text)).then((_) {
            BotToast.showText(text: S.of(context).Copy_success);
          });
        },
        child: Container(
          margin: const EdgeInsets.only(right: Base.BASE_PADDING),
          child: const Icon(
            Icons.copy,
          ),
        ),
      ));
      list.add(GestureDetector(
        onTap: () {
          removeRelay(widget.addr);
        },
        child: const Icon(
          Icons.delete,
          color: Colors.red,
        ),
      ));
    } else {
      list.add(leftWidget);
    }

    Widget main = GestureDetector(
      onTap: () {
        var relay = nostr!.getRelay(widget.addr);
        relay ??= nostr!.getTempRelay(widget.addr);
        if (relay != null && relay.info != null) {
          RouterUtil.router(context, RouterPath.RELAY_INFO, relay);
        }
      },
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Container(
          padding: const EdgeInsets.only(
            top: Base.BASE_PADDING_HALF,
            bottom: Base.BASE_PADDING_HALF,
            left: Base.BASE_PADDING,
            right: Base.BASE_PADDING,
          ),
          decoration: BoxDecoration(
            color: cardColor,
            border: Border(
              left: BorderSide(
                width: 6,
                color: borderLeftColor,
              ),
            ),
          ),
          child: Row(
            children: list,
          ),
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(
        bottom: Base.BASE_PADDING,
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      child: main,
    );
  }

  void removeRelay(String addr) {
    relayProvider.removeRelay(addr);
  }
}

class RelaysItemNumWidget extends StatelessWidget {
  Color? iconColor;

  IconData iconData;

  int num;

  RelaysItemNumWidget({
    super.key,
    this.iconColor,
    required this.iconData,
    required this.num,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var smallFontSize = themeData.textTheme.bodySmall!.fontSize;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(right: Base.BASE_PADDING_HALF),
          child: Icon(
            iconData,
            color: iconColor,
            size: smallFontSize,
          ),
        ),
        Text(
          num.toString(),
          style: TextStyle(
            fontSize: smallFontSize,
          ),
        ),
      ],
    );
  }
}
