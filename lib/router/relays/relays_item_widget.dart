
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/router/relays/relay_speed_widget.dart';
import 'package:nostrmo/util/router_util.dart';

import '../../consts/base.dart';
import '../../consts/client_connected.dart';
import '../../generated/l10n.dart';

class RelaysItemWidget extends StatefulWidget {
  final String addr;

  final RelayStatus relayStatus;

  final bool editable;

  final String rwText;

  const RelaysItemWidget({
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
    final localization = S.of(context);
    var smallFontSize = themeData.textTheme.bodySmall!.fontSize;
    var cardColor = themeData.cardColor;
    Color borderLeftColor = Colors.green;
    if (widget.relayStatus.connected == ClientConnected.disconnected) {
      borderLeftColor = Colors.red;
    } else if (widget.relayStatus.connected == ClientConnected.connecting) {
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
              margin: const EdgeInsets.only(right: Base.basePadding),
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
                left: Base.basePadding,
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
            BotToast.showText(text: localization.Copy_success);
          });
        },
        child: Container(
          margin: const EdgeInsets.only(right: Base.basePadding),
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
          RouterUtil.router(context, RouterPath.relayInfo, relay);
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
            top: Base.basePaddingHalf,
            bottom: Base.basePaddingHalf,
            left: Base.basePadding,
            right: Base.basePadding,
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
        bottom: Base.basePadding,
        left: Base.basePadding,
        right: Base.basePadding,
      ),
      child: main,
    );
  }

  void removeRelay(String addr) {
    relayProvider.removeRelay(addr);
  }
}

class RelaysItemNumWidget extends StatelessWidget {
  final Color? iconColor;

  final IconData iconData;

  final int num;

  const RelaysItemNumWidget({
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
          margin: const EdgeInsets.only(right: Base.basePaddingHalf),
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
