import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/relative_date_widget.dart';
import 'package:nostrmo/component/user/name_widget.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/theme/app_colors.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../data/user.dart';
import '../../provider/user_provider.dart';
import '../nip05_valid_widget.dart';

class EventTopWidget extends StatefulWidget {
  final Event event;
  final String? pagePubkey;

  const EventTopWidget({
    super.key,
    required this.event,
    this.pagePubkey,
  });

  @override
  State<StatefulWidget> createState() {
    return _EventTopWidgetState();
  }
}

class _EventTopWidgetState extends State<EventTopWidget> {
  static const double imageWidth = 40; // Slightly larger avatar

  String? pubkey;

  @override
  Widget build(BuildContext context) {
    pubkey = widget.event.pubkey;
    // if this is the zap event, change the pubkey from the zap tag info
    if (widget.event.kind == EventKind.zap) {
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

    return Selector<UserProvider, User?>(
      shouldRebuild: (previous, next) {
        return previous != next;
      },
      selector: (context, userProvider) {
        return userProvider.getUser(pubkey!);
      },
      builder: (context, user, child) {
        String nip05Text = Nip19.encodeSimplePubKey(pubkey!);

        if (user != null && StringUtil.isNotBlank(user.nip05)) {
          nip05Text = user.nip05!;
        }

        String displayName = NameWidget.getSimpleName(pubkey!, user);

        return Container(
          padding: const EdgeInsets.only(
            left: Base.basePadding,
            right: Base.basePadding,
            bottom: Base.basePaddingHalf,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User avatar with slightly elevated look
              jumpWrap(Container(
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: UserPicWidget(
                  width: imageWidth,
                  pubkey: pubkey!,
                  user: user,
                ),
              )),
              
              // User info column
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(left: Base.basePaddingHalf * 1.5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Username with theme-adaptive styling
                          Expanded(
                            child: jumpWrap(
                              Text(
                                displayName,
                                style: GoogleFonts.nunito(
                                  textStyle: TextStyle(
                                    color: context.colors.highlightText,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    height: 1.29,
                                    letterSpacing: 0.68,
                                  ),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          
                          // Time stamp with theme-adaptive styling
                          RelativeDateWidget(
                            widget.event.createdAt,
                            style: GoogleFonts.nunito(
                              textStyle: TextStyle(
                                color: context.colors.secondaryText,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                height: 1.33,
                                letterSpacing: 0.60,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // NIP-05 identifier with new styling
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              nip05Text,
                              style: GoogleFonts.nunito(
                                textStyle: TextStyle(
                                  color: context.colors.secondaryText,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  height: 1.33,
                                  letterSpacing: 0.60,
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          // NIP-05 verification icon
                          Container(
                            margin: const EdgeInsets.only(left: 3),
                            child: Nip05ValidWidget(
                              pubkey: pubkey!,
                              size: 14,
                            ),
                          ),
                        ],
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

        RouterUtil.router(context, RouterPath.user, pubkey);
      },
      child: c,
    );
  }
}
