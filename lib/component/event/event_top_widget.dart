import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/relative_date_widget.dart';
import 'package:nostrmo/component/user/name_widget.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../data/metadata.dart';
import '../../main.dart';
import '../../provider/metadata_provider.dart';
import '../image_widget.dart';
import '../nip05_valid_widget.dart';

class EventTopWidget extends StatefulWidget {
  Event event;
  String? pagePubkey;

  EventTopWidget({
    required this.event,
    this.pagePubkey,
  });

  @override
  State<StatefulWidget> createState() {
    return _EventTopWidgetState();
  }
}

class _EventTopWidgetState extends State<EventTopWidget> {
  static const double IMAGE_WIDTH = 34;

  static const double HALF_IMAGE_WIDTH = 17;

  String? pubkey;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;

    pubkey = widget.event.pubkey;
    // if this is the zap event, change the pubkey from the zap tag info
    if (widget.event.kind == EventKind.ZAP) {
      for (var tag in widget.event.tags) {
        if (tag[0] == "description" && widget.event.tags.length > 1) {
          var description = tag[1];
          var jsonMap = jsonDecode(description);
          var sourceEvent = Event.fromJson(jsonMap);
          if (StringUtil.isNotBlank(sourceEvent.pubkey)) {
            pubkey = sourceEvent.pubkey;
          }
        }
      }
    }

    return Selector<MetadataProvider, Metadata?>(
      shouldRebuild: (previous, next) {
        return previous != next;
      },
      selector: (context, metadataProvider) {
        return metadataProvider.getMetadata(pubkey!);
      },
      builder: (context, metadata, child) {
        final themeData = Theme.of(context);

        String nip05Text = Nip19.encodeSimplePubKey(pubkey!);

        if (metadata != null) {
          if (StringUtil.isNotBlank(metadata.nip05)) {
            nip05Text = metadata.nip05!;
          }
        }

        return Container(
          padding: const EdgeInsets.only(
            left: Base.BASE_PADDING,
            right: Base.BASE_PADDING,
            bottom: Base.BASE_PADDING_HALF,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              jumpWrap(Container(
                margin: const EdgeInsets.only(top: 4),
                child: UserPicWidget(
                  width: IMAGE_WIDTH,
                  pubkey: pubkey!,
                  metadata: metadata,
                ),
              )),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(left: Base.BASE_PADDING_HALF),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: jumpWrap(
                              NameWidget(
                                pubkey: widget.event.pubkey,
                                metadata: metadata,
                                maxLines: 1,
                                textOverflow: TextOverflow.ellipsis,
                                showNip05: false,
                                showName: false,
                              ),
                            ),
                          ),
                          RelativeDateWidget(widget.event.createdAt)
                        ],
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: nip05Text,
                              style: TextStyle(
                                fontSize: smallTextSize,
                                color: themeData.hintColor,
                              ),
                            ),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.baseline,
                              baseline: TextBaseline.ideographic,
                              child: Container(
                                margin: const EdgeInsets.only(left: 3),
                                child: Nip05ValidWidget(pubkey: pubkey!),
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget jumpWrap(Widget c) {
    return GestureDetector(
      onTap: () {
        // disable jump when in same user page.
        if (widget.pagePubkey == widget.event.pubkey) {
          return;
        }

        RouterUtil.router(context, RouterPath.USER, pubkey);
      },
      child: c,
    );
  }
}
