import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/provider/community_approved_provider.dart';
import 'package:nostrmo/service/moderation_service.dart';
import 'package:nostrmo/component/moderation/moderated_post_widget.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../util/router_util.dart';
import '../../theme/app_colors.dart';
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
    
    // Check if this post has been moderated/removed
    final moderationService = Provider.of<ModerationService>(context);
    final isModerated = moderationService.isPostModerated(widget.event.id);
    
    // If moderated, show the moderation placeholder
    if (isModerated) {
      final moderationEvent = moderationService.getModerationEvent(widget.event.id);
      return ModeratedPostWidget(
        originalEvent: widget.event,
        moderationEvent: moderationEvent,
      );
    }

    // Create a card with enhanced styling following design system
    Widget main = Screenshot(
      controller: screenshotController,
      child: Container(
        // Improved card styling with refined margins
        margin: const EdgeInsets.symmetric(
          horizontal: Base.basePadding, 
          vertical: Base.basePaddingHalf,
        ),
        decoration: BoxDecoration(
          color: context.colors.cardBackground, // Use theme extension from the new AppColors
          borderRadius: BorderRadius.circular(16), // Slightly more rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08), // More subtle shadow
              blurRadius: 8,
              offset: const Offset(0, 3),
              spreadRadius: 1,
            ),
          ],
          border: Border.all(
            color: context.colors.divider.withOpacity(0.3), // Subtle border
            width: 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias, // Ensures content respects border radius
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main content (profile pic, name, content, etc.)
            Padding(
              padding: const EdgeInsets.only(
                left: Base.basePadding,
                right: Base.basePadding,
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
            
            // Refined separator with gradient fade at edges for a more polished look
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    context.colors.divider.withOpacity(0.6),
                    context.colors.divider.withOpacity(0.6),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.05, 0.95, 1.0],
                ),
              ),
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
