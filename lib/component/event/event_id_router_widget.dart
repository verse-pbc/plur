import 'package:flutter/material.dart';
import 'package:nostrmo/provider/single_event_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../../consts/router_path.dart';
import '../../generated/l10n.dart';

class EventIdRouterWidget extends StatefulWidget {
  final String eventId;

  final String? relayAddr;

  const EventIdRouterWidget(this.eventId, this.relayAddr, {super.key});

  static Future<void> router(
    BuildContext context,
    String eventId, {
    String? relayAddr,
  }) async {
    final navigator = Navigator.of(context);

    var event = await showDialog(
      context: context,
      useRootNavigator: false,
      builder: (_) {
        return EventIdRouterWidget(eventId, relayAddr);
      },
    );

    if (event != null) {
      if (!navigator.mounted) return;
      RouterUtil.router(navigator.context, RouterPath.getThreadDetailPath(), event);
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
        child: Text(localization.noteLoading),
      ),
    );
  }
}
