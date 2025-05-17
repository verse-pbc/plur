import 'dart:convert';
import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:google_fonts/google_fonts.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/enum_selector_widget.dart';
import 'package:nostrmo/component/json_view_dialog.dart';
import 'package:nostrmo/component/like_text_select_bottom_sheet.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/like_select_type.dart';
import 'package:nostrmo/consts/plur_colors.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../consts/base_consts.dart';
import '../../consts/router_path.dart';
import '../../data/event_reactions.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/event_reactions_provider.dart';
import '../../router/edit/editor_widget.dart';
import '../../util/number_format_util.dart';
import '../../util/router_util.dart';
import '../../util/store_util.dart';
import '../editor/cust_embed_types.dart';
import '../event_delete_callback.dart';
import '../event_reply_callback.dart';
import '../zap/zap_bottom_sheet_widget.dart';
import 'event_top_zaps_widget.dart';
import '../report_event_dialog.dart';

class EventReactionsWidget extends StatefulWidget {
  final ScreenshotController screenshotController;

  final Event event;

  final EventRelation eventRelation;

  final bool showDetailBtn;

  const EventReactionsWidget({
    super.key,
    required this.screenshotController,
    required this.event,
    required this.eventRelation,
    this.showDetailBtn = true,
  });

  @override
  State<StatefulWidget> createState() {
    return _EventReactionsWidgetState();
  }
}

class _EventReactionsWidgetState extends State<EventReactionsWidget> {
  List<Event>? myLikeEvents;

  bool readOnly = false;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var mainColor = themeData.primaryColor;
    readOnly = nostr!.isReadOnly();

    return Selector<EventReactionsProvider, EventReactions?>(
      builder: (context, eventReactions, child) {
        int replyNum = 0;
        int repostNum = 0;
        int likeNum = 0;
        int zapNum = 0;
        Color likeColor = hintColor;

        if (eventReactions != null) {
          replyNum = eventReactions.replies.length;
          repostNum = eventReactions.repostNum;
          likeNum = eventReactions.likeNum;
          zapNum = eventReactions.zapNum;

          myLikeEvents = eventReactions.myLikeEvents;
        }
        if (myLikeEvents != null && myLikeEvents!.isNotEmpty) {
          likeColor = mainColor;
        }

        String? iconText;
        Widget? showMoreIconWidget;
        IconData likeIconData = Icons.add_reaction_outlined;
        if (eventReactions != null) {
          var mapLength = eventReactions.likeNumMap.length;
          if (mapLength == 1) {
            // only one emoji
            IconData? iconData;
            eventReactions.likeNumMap.forEach((key, value) {
              iconText = key;
              iconData = getIconDataByContent(key);
              if (iconData != null) {
                likeIconData = iconData!;
              }
            });
          } else if (mapLength > 1) {
            var max = 0;
            eventReactions.likeNumMap.forEach((key, value) {
              if (value > max) {
                max = value;
                iconText = key;
              }
            });
            if (iconText == LikeSelectType.like) {
              likeIconData = Icons.favorite;
            } else if (iconText == LikeSelectType.funnyFace) {
              likeIconData = Icons.emoji_emotions;
            } else if (iconText == LikeSelectType.party) {
              likeIconData = Icons.celebration;
            } else if (iconText == LikeSelectType.ok) {
              likeIconData = Icons.thumb_up;
            } else if (iconText == LikeSelectType.fire) {
              likeIconData = Icons.local_fire_department;
            } else {
              showMoreIconWidget = InkWell(
                customBorder: const CircleBorder(),
                onTap: showMoreLikeTap,
                child: const Icon(
                  Icons.expand_more,
                  size: 15,
                ),
              );
            }
          }
        }

        List<Widget> mainList = [];

        // zapmore
        // likeMore

        if (showMoreZap) {
          List<Widget> zapList = [];
          int counter = 0;
          eventReactions!.zapNumMap.forEach((key, value) {
            if (counter == 0) {
              counter++;
              return;
            }
            if (value > 0) {
              zapList.add(Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: Base.basePaddingHalf,
                ),
                child: Text("$key $value"),
              ));
            }
          });
          mainList.add(SizedBox(
            width: double.maxFinite,
            child: Wrap(
              alignment: WrapAlignment.center,
              children: zapList,
            ),
          ));
        }

        if (showMoreLike) {
          List<Widget> ers = [];
          int counter = 0;
          eventReactions!.likeNumMap.forEach((key, value) {
            if (counter == 0) {
              counter++;
              return;
            }
            if (value > 0) {
              ers.add(Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: Base.basePaddingHalf,
                ),
                child: Text("$key $value"),
              ));
            }
          });
          mainList.add(SizedBox(
            width: double.maxFinite,
            child: Wrap(
              alignment: WrapAlignment.center,
              children: ers,
            ),
          ));
        }

        return Container(
          padding: const EdgeInsets.only(
            bottom: Base.basePaddingHalf,
          ),
          decoration: BoxDecoration(
            color: themeData.customColors.cardBgColor, // Use ThemeData extension for card background
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.eventRelation.zapInfos.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(
                    bottom: Base.basePaddingHalf,
                  ),
                  child: EventTopZapsWidget(
                    zapEvents: const [], // Pass empty list and let the widget handle these internally
                    event: widget.event, 
                    eventRelation: widget.eventRelation,
                  ),
                ),
              // Redesigned reaction bar with modern styling
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Reply button
                    _buildReactionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      count: replyNum,
                      color: hintColor,
                      onTap: tapReply,
                    ),
                    
                    // Repost button
                    _buildReactionButton(
                      icon: Icons.repeat_rounded,
                      count: repostNum,
                      color: hintColor,
                      onTap: tapRepost,
                    ),
                    
                    // Like button
                    _buildReactionButton(
                      icon: likeIconData,
                      count: likeNum,
                      color: likeColor,
                      onTap: tapLike,
                      extraWidget: showMoreIconWidget,
                    ),
                    
                    // Zap button
                    _buildReactionButton(
                      icon: Icons.bolt_rounded, 
                      count: zapNum,
                      color: hintColor,
                      onTap: tapZap,
                    ),
                    
                    // More options button
                    if (widget.showDetailBtn)
                      _buildReactionButton(
                        icon: Icons.more_horiz_rounded, 
                        count: null, // No count for this button
                        color: hintColor,
                        onTap: tapMore,
                        showLabel: false,
                      ),
                  ],
                ),
              ),
              ...mainList,
            ],
          ),
        );
      },
      selector: (_, provider) {
        return provider.get(widget.event.id);
      },
      shouldRebuild: (previous, next) {
        if ((previous == null && next != null) ||
            (previous != null &&
                next != null &&
                (previous.replies.length != next.replies.length ||
                    previous.repostNum != next.repostNum ||
                    previous.likeNum != next.likeNum ||
                    previous.zapNum != next.zapNum))) {
          return true;
        }

        return false;
      },
    );
  }
  
  // Helper method for creating consistent reaction buttons with theme support
  Widget _buildReactionButton({
    required IconData icon,
    required int? count,
    required Color color,
    required VoidCallback onTap,
    Widget? extraWidget,
    bool showLabel = true,
  }) {
    final theme = Theme.of(context);
    final fontSize = theme.textTheme.bodyMedium!.fontSize!;
    
    // Determine if this button is active (e.g. liked/reacted)
    final bool isActive = color != theme.hintColor;
    
    // Choose color based on active state
    final buttonColor = isActive 
        ? PlurColors.primaryPurple // Active buttons always use primary color
        : PlurColors.secondaryTextColor(context); // Non-active buttons use secondary text color
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: fontSize + 3,
                color: buttonColor,
              ),
              if (showLabel && count != null)
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  child: Text(
                    NumberFormatUtil.format(count),
                    style: GoogleFonts.nunito(
                      textStyle: TextStyle(
                        color: buttonColor,
                        fontSize: fontSize - 1,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              if (extraWidget != null)
                Container(
                  margin: const EdgeInsets.only(left: 2),
                  child: extraWidget,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void onPopupSelected(String value) {
    if (value == "copyEvent") {
      var text = jsonEncode(widget.event.toJson());
      JsonViewDialog.show(context, text);
    } else if (value == "copyPubkey") {
      var text = Nip19.encodePubKey(widget.event.pubkey);
      _doCopy(text);
    } else if (value == "copyId") {
      var text = Nip19.encodeNoteId(widget.event.id);
      _doCopy(text);
    } else if (value == "detail") {
      RouterUtil.router(context, RouterPath.eventDetail, widget.event);
    } else if (value == "share") {
      onShareTap();
    } else if (value == "addToPrivateBookmark") {
      var item = BookmarkItem.getFromEventReactions(widget.eventRelation);
      listProvider.addPrivateBookmark(item);
    } else if (value == "addToPublicBookmark") {
      var item = BookmarkItem.getFromEventReactions(widget.eventRelation);
      listProvider.addPublicBookmark(item);
    } else if (value == "removeFromPrivateBookmark") {
      var item = BookmarkItem.getFromEventReactions(widget.eventRelation);
      listProvider.removePrivateBookmark(item.value);
    } else if (value == "removeFromPublicBookmark") {
      var item = BookmarkItem.getFromEventReactions(widget.eventRelation);
      listProvider.removePublicBookmark(item.value);
    } else if (value == "broadcase") {
      nostr!.broadcase(widget.event);
    } else if (value == "source") {
      List<EnumObj> list = [];
      for (var source in widget.event.sources) {
        list.add(EnumObj(source, source));
      }
      EnumSelectorWidget.show(context, list);
    } else if (value == "block") {
      filterProvider.addBlock(widget.event.pubkey);
    } else if (value == "delete") {
      if (widget.event.kind == EventKind.groupNote ||
          widget.event.kind == EventKind.groupNoteReply) {
        var groupIdentifier = widget.event.relations().groupIdentifier;
        if (groupIdentifier != null) {
          groupProvider.deleteEvent(groupIdentifier, widget.event.id);
          var deleteCallback = EventDeleteCallback.of(context);
          if (deleteCallback != null) {
            deleteCallback.onDelete(widget.event);
          }
        }
      } else {
        List<String>? relayAddrs = getGroupRelays();
        nostr!.deleteEvent(widget.event.id,
            tempRelays:
                relayAddrs); // delete event send to groupRelays and myRelays
        followEventProvider.deleteEvent(widget.event.id);
        mentionMeProvider.deleteEvent(widget.event.id);
        var deleteCallback = EventDeleteCallback.of(context);
        if (deleteCallback != null) {
          deleteCallback.onDelete(widget.event);
        }
      }
    } else if (value == "report") {
      showDialog(
        context: context,
        builder: (context) => const ReportEventDialog(),
      ).then((result) {
        if (result != null) {
          final reason = result['reason'];
          final details = result['details'];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Report submitted: $reason${details != null && details.isNotEmpty ? ", $details" : ""}')),
          );
          // TODO: Implement event generation and relay publishing here
        }
      });
    }
  }

  void _doCopy(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      if (!mounted) return;
      BotToast.showText(text: S.of(context).copySuccess);
    });
  }

  @override
  void dispose() {
    super.dispose();
    var id = widget.event.id;
    eventReactionsProvider.removePending(id);
  }

  Future<void> onCommmentTap() async {
    if (readOnly) {
      return;
    }

    var er = widget.eventRelation;
    List<dynamic> tags = [];
    List<dynamic> tagsAddedWhenSend = [];
    String relayAddr = "";
    if (widget.event.sources.isNotEmpty) {
      relayAddr = widget.event.sources[0];
    }
    String directMarked = "reply";
    if (StringUtil.isBlank(er.rootId)) {
      directMarked = "root";
    }
    tagsAddedWhenSend.add(["e", widget.event.id, relayAddr, directMarked]);

    List<dynamic> tagPs = [];
    tagPs.add(["p", widget.event.pubkey]);
    if (er.tagPList.isNotEmpty) {
      for (var p in er.tagPList) {
        tagPs.add(["p", p]);
      }
    }
    if (StringUtil.isNotBlank(er.rootId)) {
      String relayAddr = "";
      if (StringUtil.isNotBlank(er.rootRelayAddr)) {
        relayAddr = er.rootRelayAddr!;
      }
      if (StringUtil.isBlank(relayAddr)) {
        var rootEvent = singleEventProvider.getEvent(er.rootId!);
        if (rootEvent != null && rootEvent.sources.isNotEmpty) {
          relayAddr = rootEvent.sources[0];
        }
      }
      tags.add(["e", er.rootId, relayAddr, "root"]);
    }

    GroupIdentifier? groupIdentifier;
    int? groupEventKind;
    if (widget.event.kind == EventKind.groupNote ||
        widget.event.kind == EventKind.groupNoteReply) {
      groupIdentifier = widget.event.relations().groupIdentifier;
      if (groupIdentifier != null) {
        groupEventKind = EventKind.groupNoteReply;
      }
    }

    // TODO reply maybe change the placeholder in editor router.
    var event = await EditorWidget.open(
      context,
      tags: tags,
      tagsAddedWhenSend: tagsAddedWhenSend,
      tagPs: tagPs,
      groupIdentifier: groupIdentifier,
      groupEventKind: groupEventKind,
    );

    if (!mounted) return;

    if (event != null) {
      eventReactionsProvider.addEventAndHandle(event);
      var callback = EventReplyCallback.of(context);
      if (callback != null) {
        callback.onReply(event);
      }
    }
  }

  Future<void> onRepostTap(String value) async {
    if (value == "boost") {
      String? relayAddr;
      if (widget.event.sources.isNotEmpty) {
        relayAddr = widget.event.sources[0];
      }

      List<String>? relayAddrs = getGroupRelays();

      var content = jsonEncode(widget.event.toJson());
      var repostEvent = await nostr!.sendRepost(widget.event.id,
          relayAddr: relayAddr,
          content: content,
          tempRelays: relayAddrs,
          targetRelays: relayAddrs);
      if (repostEvent != null) {
        eventReactionsProvider.addRepost(widget.event.id);
      }

      if (settingsProvider.broadcaseWhenBoost == OpenStatus.open) {
        nostr!.broadcase(widget.event);
      }
    } else if (value == "quote") {
      await EditorWidget.open(context, initEmbeds: [
        quill.CustomBlockEmbed(CustEmbedTypes.mentionEvent, widget.event.id)
      ]);
    }
  }

  Future<void> onLikeTap() async {
    if (readOnly) {
      return;
    }

    List<String>? relayAddrs = getGroupRelays();

    relayAddrs ??= [];
    relayAddrs
        .addAll(userProvider.getExtralRelays(widget.event.pubkey, false));

    if (myLikeEvents == null || myLikeEvents!.isEmpty) {
      // like
      // get emoji text
      var emojiText = await selectLikeEmojiText();
      if (StringUtil.isBlank(emojiText)) {
        return;
      }

      var likeEvent = await nostr!.sendLike(widget.event.id,
          content: emojiText, tempRelays: relayAddrs, targetRelays: relayAddrs);
      if (likeEvent != null) {
        eventReactionsProvider.addLike(widget.event.id, likeEvent);
      }
    } else {
      // delete like
      bool deleted = false;
      for (var event in myLikeEvents!) {
        var deleteEvent = await nostr!.deleteEvent(event.id,
            tempRelays:
                relayAddrs); // delete event send to groupRelay and myRelays
        if (deleteEvent != null) {
          deleted = true;
        }
      }
      if (deleted) {
        eventReactionsProvider.deleteLike(widget.event.id);
      }
    }
  }

  void onShareTap() {
    widget.screenshotController.capture().then((Uint8List? imageData) async {
      if (imageData != null) {
        var tempFile = await StoreUtil.saveBS2TempFile(
          "png",
          imageData,
        );
        Share.shareXFiles([XFile(tempFile)]);
      }
    }).catchError((onError) {
      log("onShareTap error $onError");
    });
  }

  bool showMoreZap = false;

  void showMoreZapTap() {
    setState(() {
      showMoreZap = !showMoreZap;
    });
  }

  bool showMoreLike = false;

  void showMoreLikeTap() {
    setState(() {
      showMoreLike = !showMoreLike;
    });
  }

  Future<String?> selectLikeEmojiText() async {
    var text = await showModalBottomSheet(
      isScrollControlled: false,
      context: context,
      builder: (context) {
        return const LikeTextSelectBottomSheet();
      },
    );

    return text;
  }

  void openZapDialog() {
    ZapBottomSheetWidget.show(context, widget.event, widget.eventRelation);
  }

  List<String>? getGroupRelays() {
    List<String>? relayAddrs;
    if (widget.event.kind == EventKind.groupNote ||
        widget.event.kind == EventKind.groupNoteReply) {
      var groupIdentifier = widget.event.relations().groupIdentifier;
      if (groupIdentifier != null) {
        var metadata = groupProvider.getMetadata(groupIdentifier);
        // post to our main relays.
        relayAddrs = [];
        if (metadata != null && metadata.relays != null) {
          relayAddrs = List<String>.from(metadata.relays!);
        }
        if (StringUtil.isNotBlank(groupIdentifier.host)) {
          relayAddrs.add(groupIdentifier.host);
        }
      }
    }
    return relayAddrs;
  }

  void tapLike() {
    onLikeTap();
  }

  void tapZap() {
    if (readOnly) {
      return;
    }
    openZapDialog();
  }

  void tapReply() {
    onCommmentTap();
  }

  void tapRepost() {
    if (readOnly) {
      return;
    }

    var localization = S.of(context);
    final themeData = Theme.of(context);
    var popFontStyle = TextStyle(
      fontSize: themeData.textTheme.bodyMedium!.fontSize,
    );

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              title: Text(
                localization.boost,
                style: popFontStyle,
              ),
              leading: const Icon(Icons.repeat),
              onTap: () {
                Navigator.of(context).pop();
                onRepostTap("boost");
              },
            ),
            ListTile(
              title: Text(
                localization.quote,
                style: popFontStyle,
              ),
              leading: const Icon(Icons.format_quote),
              onTap: () {
                Navigator.of(context).pop();
                onRepostTap("quote");
              },
            ),
          ],
        );
      },
    );
  }

  void tapMore() {
    var localization = S.of(context);
    final themeData = Theme.of(context);
    var popFontStyle = TextStyle(
      fontSize: themeData.textTheme.bodyMedium!.fontSize,
    );
    var myPubkey = settingsProvider.privateKey == null
        ? null
        : settingsProvider.pubkey; // Use pubkey from settingsProvider instead of deriving it

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        var list = [
          ListTile(
            title: Text(
              localization.copyNoteId,
              style: popFontStyle,
            ),
            leading: const Icon(Icons.copy),
            onTap: () {
              Navigator.of(context).pop();
              onPopupSelected("copyId");
            },
          ),
          ListTile(
            title: Text(
              localization.copyNotePubkey,
              style: popFontStyle,
            ),
            leading: const Icon(Icons.copy),
            onTap: () {
              Navigator.of(context).pop();
              onPopupSelected("copyPubkey");
            },
          ),
          ListTile(
            title: Text(
              localization.openNoteDetail,
              style: popFontStyle,
            ),
            leading: const Icon(Icons.open_in_new),
            onTap: () {
              Navigator.of(context).pop();
              onPopupSelected("detail");
            },
          ),
          ListTile(
            title: Text(
              localization.share,
              style: popFontStyle,
            ),
            leading: const Icon(Icons.share),
            onTap: () {
              Navigator.of(context).pop();
              onPopupSelected("share");
            },
          ),
          ListTile(
            title: Text(
              localization.copyNoteJson,
              style: popFontStyle,
            ),
            leading: const Icon(Icons.content_copy),
            onTap: () {
              Navigator.of(context).pop();
              onPopupSelected("copyEvent");
            },
          ),
          ListTile(
            title: Text(
              localization.broadcast,
              style: popFontStyle,
            ),
            leading: const Icon(Icons.send),
            onTap: () {
              Navigator.of(context).pop();
              onPopupSelected("broadcase");
            },
          ),
          ListTile(
            title: Text(
              localization.source,
              style: popFontStyle,
            ),
            leading: const Icon(Icons.link),
            onTap: () {
              Navigator.of(context).pop();
              onPopupSelected("source");
            },
          ),
          ListTile(
            title: Text(
              localization.report,
              style: popFontStyle,
            ),
            leading: const Icon(Icons.flag),
            onTap: () {
              Navigator.of(context).pop();
              onPopupSelected("report");
            },
          ),
        ];

        if (listProvider.privateBookmarkContains(widget.event.id)) {
          list.add(ListTile(
            title: Text(
              localization.removeFromPrivateBookmark,
              style: popFontStyle,
            ),
            leading: const Icon(Icons.bookmark_remove),
            onTap: () {
              Navigator.of(context).pop();
              onPopupSelected("removeFromPrivateBookmark");
            },
          ));
        } else {
          list.add(ListTile(
            title: Text(
              localization.addToPrivateBookmark,
              style: popFontStyle,
            ),
            leading: const Icon(Icons.bookmark_add),
            onTap: () {
              Navigator.of(context).pop();
              onPopupSelected("addToPrivateBookmark");
            },
          ));
        }

        if (listProvider.publicBookmarkContains(widget.event.id)) {
          list.add(ListTile(
            title: Text(
              localization.removeFromPublicBookmark,
              style: popFontStyle,
            ),
            leading: const Icon(Icons.bookmark_remove),
            onTap: () {
              Navigator.of(context).pop();
              onPopupSelected("removeFromPublicBookmark");
            },
          ));
        } else {
          list.add(ListTile(
            title: Text(
              localization.addToPublicBookmark,
              style: popFontStyle,
            ),
            leading: const Icon(Icons.bookmark_add),
            onTap: () {
              Navigator.of(context).pop();
              onPopupSelected("addToPublicBookmark");
            },
          ));
        }

        list.add(ListTile(
          title: Text(
            localization.block,
            style: popFontStyle,
          ),
          leading: const Icon(Icons.block),
          onTap: () {
            Navigator.of(context).pop();
            onPopupSelected("block");
          },
        ));

        if (myPubkey != null && myPubkey == widget.event.pubkey) {
          list.add(ListTile(
            title: Text(
              localization.delete,
              style: popFontStyle,
            ),
            leading: const Icon(Icons.delete_forever),
            onTap: () {
              Navigator.of(context).pop();
              onPopupSelected("delete");
            },
          ));
        }

        return Wrap(
          children: list,
        );
      },
    );
  }

  IconData? getIconDataByContent(String content) {
    if (content == LikeSelectType.like) {
      return Icons.favorite;
    } else if (content == LikeSelectType.funnyFace) {
      return Icons.emoji_emotions;
    } else if (content == LikeSelectType.party) {
      return Icons.celebration;
    } else if (content == LikeSelectType.ok) {
      return Icons.thumb_up;
    } else if (content == LikeSelectType.fire) {
      return Icons.local_fire_department;
    }

    return null;
  }
}