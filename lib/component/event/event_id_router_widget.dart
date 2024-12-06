import 'package:flutter/material.dart';
import 'package:nostrmo/provider/single_event_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../../consts/router_path.dart';
import '../../generated/l10n.dart';

class EventIdRouterWidget extends StatefulWidget {
  String eventId;

  String? relayAddr;

  EventIdRouterWidget(this.eventId, this.relayAddr);

  static Future<void> router(
    BuildContext context,
    String eventId, {
    String? relayAddr,
  }) async {
    var event = await showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        return EventIdRouterWidget(eventId, relayAddr);
      },
    );

    if (event != null) {
      RouterUtil.router(context, RouterPath.getThreadDetailPath(), event);
    }
  }

  @override
  State<StatefulWidget> createState() {
    return _EventIdRouterWidgetState();
  }
}

class _EventIdRouterWidgetState extends State<EventIdRouterWidget> {
  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    var singleEventProvider = Provider.of<SingleEventProvider>(context);
    var event = singleEventProvider.getEvent(widget.eventId,
        eventRelayAddr: widget.relayAddr);
    if (event != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        RouterUtil.back(context, event);
      });
    } else {}

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.loading),
      ),
      body: Center(
        child: Text(localization.Note_loading),
      ),
    );
  }
}
