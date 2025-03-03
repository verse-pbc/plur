import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/relay_provider.dart';
import 'package:nostrmo/router/relays/relay_speed_widget.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../util/router_util.dart';

class UserRelayWidget extends StatefulWidget {
  const UserRelayWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _UserRelayWidgetState();
  }
}

class _UserRelayWidgetState extends State<UserRelayWidget> {
  List<RelayMetadata>? relays;
  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    if (relays == null) {
      relays = [];
      var arg = RouterUtil.routerArgs(context);
      if (arg != null && arg is List<dynamic>) {
        for (var tag in arg) {
          if (tag is List<dynamic>) {
            var length = tag.length;
            bool write = true;
            bool read = true;
            if (length > 1) {
              var name = tag[0];
              var value = tag[1];
              if (name == "r") {
                if (length > 2) {
                  var operType = tag[2];
                  if (operType == "read") {
                    write = false;
                  } else if (operType == "write") {
                    read = false;
                  }
                }

                relays!.add(RelayMetadata(value, read, write));
              }
            }
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        title: Text(localization.Relays),
      ),
      body: Container(
        margin: const EdgeInsets.only(
          top: Base.BASE_PADDING,
        ),
        child: ListView.builder(
          itemBuilder: (context, index) {
            var relayMetadata = relays![index];
            return Selector<RelayProvider, RelayStatus?>(
                builder: (context, relayStatus, child) {
              return RelayMetadataWidget(
                relayMetadata: relayMetadata,
                addAble: relayStatus == null,
              );
            }, selector: (_, provider) {
              return provider.getRelayStatus(relayMetadata.addr);
            });
          },
          itemCount: relays!.length,
        ),
      ),
    );
  }
}

class RelayMetadataWidget extends StatelessWidget {
  RelayMetadata? relayMetadata;

  String? addr;

  bool addAble;

  RelayMetadataWidget({super.key, this.relayMetadata, this.addr, this.addAble = true})
      : assert(relayMetadata != null || addr != null);

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    final themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var hintColor = themeData.hintColor;
    var bodySmallFontSize = themeData.textTheme.bodySmall!.fontSize;

    String? relayAddr = addr;
    if (relayMetadata != null) {
      relayAddr = relayMetadata!.addr;
    }

    if (StringUtil.isBlank(relayAddr)) {
      return Container();
    }

    List<Widget> rightList = [];
    if (relayAddr != null) {
      rightList.add(RelaySpeedWidget(relayAddr));
    }
    Widget rightBtn = Row(
      children: rightList,
    );
    if (addAble) {
      rightList.add(GestureDetector(
        onTap: () {
          relayProvider.addRelay(relayAddr!);
        },
        child: const Icon(
          Icons.add,
        ),
      ));
    }

    Widget bottomWidget = Container();
    if (relayMetadata != null) {
      bottomWidget = Row(
        children: [
          Container(
            margin: const EdgeInsets.only(right: Base.BASE_PADDING),
            child: Text(
              localization.Read,
              style: TextStyle(
                fontSize: bodySmallFontSize,
                color: relayMetadata!.read ? Colors.green : Colors.red,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: Base.BASE_PADDING),
            child: Text(
              localization.Write,
              style: TextStyle(
                fontSize: bodySmallFontSize,
                color: relayMetadata!.write ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.only(
        bottom: Base.BASE_PADDING,
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
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
              color: hintColor,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    child: Text(relayAddr!),
                  ),
                  bottomWidget,
                ],
              ),
            ),
            rightBtn,
          ],
        ),
      ),
    );
  }
}
