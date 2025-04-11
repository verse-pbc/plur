import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/consts/plur_colors.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/community_approved_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:nostrmo/util/theme_util.dart';

import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../util/router_util.dart';
import 'event_bitcoin_icon_widget.dart';
import 'event_main_widget.dart';

class EventListWidget extends StatefulWidget {
  final Event event;

  final String? pagePubkey;

  final bool jumpable;

  final bool showVideo;

  final bool imageListMode;

  final bool showDetailBtn;

  final bool showLongContent;

  final bool showCommunity;

  const EventListWidget({
    super.key,
    required this.event,
    this.pagePubkey,
    this.jumpable = true,
    this.showVideo = false,
    this.imageListMode = true,
    this.showDetailBtn = true,
    this.showLongContent = false,
    this.showCommunity = true,
  });

  @override
  State<StatefulWidget> createState() {
    return _EventListWidgetState();
  }
}

class _EventListWidgetState extends State<EventListWidget> {
  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var eventRelation = EventRelation.fromEvent(widget.event);

    // Create a card with our new styling from design
    Widget main = Screenshot(
      controller: screenshotController,
      child: Container(
        // Apply new card styling
        margin: const EdgeInsets.symmetric(
          horizontal: Base.basePadding, 
          vertical: Base.basePaddingHalf,
        ),
        decoration: BoxDecoration(
          color: PlurColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias, // Ensures content respects border radius
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main content (profile pic, name, content, etc.)
            Padding(
              padding: const EdgeInsets.only(
                top: Base.basePadding,
                bottom: Base.basePaddingHalf,
              ),
              child: EventMainWidget(
                screenshotController: screenshotController,
                event: widget.event,
                pagePubkey: widget.pagePubkey,
                textOnTap: widget.jumpable ? jumpToThread : null,
                showVideo: widget.showVideo,
                imageListMode: widget.imageListMode,
                showDetailBtn: widget.showDetailBtn,
                showLongContent: widget.showLongContent,
                showCommunity: widget.showCommunity,
                eventRelation: eventRelation,
              ),
            ),
            
            // Optional separator line
            Container(
              height: 1,
              color: PlurColors.separator.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );

    if (widget.event.kind == EventKind.zap) {
      main = EventBitcoinIconWidget.wrapper(main);
    }

    Widget approvedWrap = Selector<CommunityApprovedProvider, bool>(
        builder: (context, approved, child) {
      if (approved) {
        return main;
      }

      return Container();
    }, selector: (_, provider) {
      return provider.check(widget.event.pubkey, widget.event.id,
          aId: eventRelation.aId);
    });

    if (widget.jumpable) {
      return GestureDetector(
        onTap: jumpToThread,
        child: approvedWrap,
      );
    } else {
      return approvedWrap;
    }
  }

  void jumpToThread() {
    if (widget.event.kind == EventKind.repost) {
      // try to find target event
      if (widget.event.content.contains("\"pubkey\"")) {
        try {
          var jsonMap = jsonDecode(widget.event.content);
          var repostEvent = Event.fromJson(jsonMap);
          RouterUtil.router(
              context, RouterPath.getThreadDetailPath(), repostEvent);
          return;
        } catch (e) {
          log("jumpToThread error $e");
        }
      }

      var eventRelation = EventRelation.fromEvent(widget.event);
      if (StringUtil.isNotBlank(eventRelation.rootId)) {
        var event = singleEventProvider.getEvent(eventRelation.rootId!,
            eventRelayAddr: eventRelation.rootRelayAddr);
        if (event != null) {
          RouterUtil.router(context, RouterPath.getThreadDetailPath(), event);
          return;
        }
      }
    }
    RouterUtil.router(context, RouterPath.getThreadDetailPath(), widget.event);
  }
}
