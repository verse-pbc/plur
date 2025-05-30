import 'dart:convert';
import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/enum_selector_widget.dart';
import 'package:nostrmo/component/group_identifier_inherited_widget.dart';
import 'package:nostrmo/component/json_view_dialog.dart';
import 'package:nostrmo/component/like_text_select_bottom_sheet.dart';
import 'package:nostrmo/consts/base.dart';
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
    final localization = S.of(context);
    final themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var fontSize = themeData.textTheme.bodyMedium!.fontSize!;
    var mainColor = themeData.primaryColor;
    var mediumFontSize = themeData.textTheme.bodyMedium!.fontSize;
    var popFontStyle = TextStyle(
      fontSize: mediumFontSize,
    );
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
            iconText = eventReactions.likeNumMap.keys.first;
          } else if (mapLength > 1) {
            int maxNum = 0;
            for (var entry in eventReactions.likeNumMap.entries) {
              if (entry.value > maxNum) {
                iconText = entry.key;
                maxNum = entry.value;
              }
            }

            var iconData = Icons.keyboard_double_arrow_down_rounded;
            if (showMoreLike) {
              iconData = Icons.keyboard_double_arrow_up_rounded;
            }

            showMoreIconWidget = GestureDetector(
              onTap: showMoreLikeTap,
              child: Icon(
                iconData,
                color: likeColor,
                size: 24,
              ),
            );
          }
        }
        Widget likeWidget = EventReactionNumWidget(
          num: likeNum,
          iconText: iconText,
          iconData: likeIconData,
          onTap: onLikeTap,
          color: likeColor,
          fontSize: fontSize,
          showMoreWidget: showMoreIconWidget,
        );

        Widget? showMoreZapWidget;
        if (eventReactions != null && eventReactions.zaps.isNotEmpty) {
          var iconData = Icons.keyboard_double_arrow_up_rounded;
          if (showMoreZap) {
            iconData = Icons.keyboard_double_arrow_down_rounded;
          }

          showMoreZapWidget = GestureDetector(
            onTap: showMoreZapTap,
            child: Icon(
              iconData,
              color: hintColor,
              size: 24,
            ),
          );
        }

        Widget moreBtnWidget = Container(
          alignment: Alignment.center,
          child: PopupMenuButton<String>(
            tooltip: localization.More,
            itemBuilder: (context) {
              var bookmarkItem =
                  BookmarkItem.getFromEventReactions(widget.eventRelation);

              List<PopupMenuEntry<String>> list = [
                PopupMenuItem(
                  value: "copyEvent",
                  child: Text(localization.Copy_Note_Json, style: popFontStyle),
                ),
                PopupMenuItem(
                  value: "copyPubkey",
                  child:
                      Text(localization.Copy_Note_Pubkey, style: popFontStyle),
                ),
                PopupMenuItem(
                  value: "copyId",
                  child: Text(localization.Copy_Note_Id, style: popFontStyle),
                ),
                const PopupMenuDivider(),
              ];

              if (widget.showDetailBtn) {
                list.add(PopupMenuItem(
                  value: "detail",
                  child: Text(localization.Detail, style: popFontStyle),
                ));
              }

              list.add(PopupMenuItem(
                value: "share",
                child: Text(localization.Share, style: popFontStyle),
              ));
              list.add(const PopupMenuDivider());
              if (!readOnly) {
                if (listProvider.checkPrivateBookmark(bookmarkItem)) {
                  list.add(PopupMenuItem(
                    value: "removeFromPrivateBookmark",
                    child: Text(localization.Remove_from_private_bookmark,
                        style: popFontStyle),
                  ));
                } else {
                  list.add(PopupMenuItem(
                    value: "addToPrivateBookmark",
                    child: Text(localization.Add_to_private_bookmark,
                        style: popFontStyle),
                  ));
                }
                if (listProvider.checkPublicBookmark(bookmarkItem)) {
                  list.add(PopupMenuItem(
                    value: "removeFromPublicBookmark",
                    child: Text(localization.Remove_from_public_bookmark,
                        style: popFontStyle),
                  ));
                } else {
                  list.add(PopupMenuItem(
                    value: "addToPublicBookmark",
                    child: Text(localization.Add_to_public_bookmark,
                        style: popFontStyle),
                  ));
                }
                list.add(const PopupMenuDivider());
              }
              list.add(PopupMenuItem(
                value: "source",
                child: Text(localization.Source, style: popFontStyle),
              ));
              list.add(PopupMenuItem(
                value: "broadcast",
                child: Text(localization.Broadcast, style: popFontStyle),
              ));
              list.add(PopupMenuItem(
                value: "block",
                child: Text(localization.Block, style: popFontStyle),
              ));

              var groupAdmins =
                  GroupIdentifierInheritedWidget.getGroupAdmins(context);
              var isGroupEvent = (widget.event.kind == EventKind.groupNote ||
                  widget.event.kind == EventKind.groupNoteReply);
              var pubkey = nostr!.publicKey;
              if ((!isGroupEvent && widget.event.pubkey == pubkey) ||
                  (isGroupEvent &&
                      (groupAdmins?.containsUser(pubkey) ?? false))) {
                list.add(const PopupMenuDivider());
                list.add(PopupMenuItem(
                  value: "delete",
                  child: Text(
                    localization.Delete,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: mediumFontSize,
                    ),
                  ),
                ));
              }

              return list;
            },
            onSelected: onPopupSelected,
            child: Container(
              height: double.infinity,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(
                left: Base.basePaddingHalf,
                right: Base.basePaddingHalf,
              ),
              child: Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: hintColor,
              ),
            ),
          ),
        );

        var topReactionsWidget = Row(
          children: [
            Expanded(
                child: Container(
              alignment: Alignment.centerLeft,
              child: EventReactionNumWidget(
                num: replyNum,
                iconData: Icons.comment_rounded,
                onTap: onCommmentTap,
                color: hintColor,
                fontSize: fontSize,
              ),
            )),
            Expanded(
                child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: openZapDialog,
              child: SizedBox(
                height: double.infinity,
                child: EventReactionNumWidget(
                  num: zapNum,
                  iconData: Icons.bolt_rounded,
                  onTap: null,
                  color: hintColor,
                  fontSize: fontSize,
                  showMoreWidget: showMoreZapWidget,
                ),
              ),
            )),
            Expanded(
                child: Container(
              alignment: Alignment.center,
              child: likeWidget,
            )),
            Expanded(
              child: Container(
                alignment: Alignment.center,
                child: PopupMenuButton<String>(
                  tooltip: localization.Boost,
                  enabled: !readOnly,
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem(
                        value: "boost",
                        child: Text(localization.Boost),
                      ),
                      PopupMenuItem(
                        value: "quote",
                        child: Text(localization.Quote),
                      ),
                    ];
                  },
                  onSelected: onRepostTap,
                  child: EventReactionNumWidget(
                    num: repostNum,
                    iconData: Icons.repeat_rounded,
                    color: hintColor,
                    fontSize: fontSize,
                  ),
                ),
              ),
            ),
            moreBtnWidget,
          ],
        );

        List<Widget> mainList = [];

        if (showMoreZap &&
            eventReactions != null &&
            eventReactions.zaps.isNotEmpty) {
          mainList.add(Container(
            margin: const EdgeInsets.only(
              top: Base.basePadding,
              bottom: Base.basePaddingHalf,
            ),
            child: EventTopZapsWidget(eventReactions.zaps),
          ));
        }

        mainList.add(SizedBox(
          height: 34,
          child: topReactionsWidget,
        ));

        if (showMoreLike &&
            eventReactions != null &&
            eventReactions.likeNumMap.length > 1) {
          Map<String, int> myLikeMap = {};
          if (eventReactions.myLikeEvents != null) {
            for (var event in eventReactions.myLikeEvents!) {
              var likeText = EventReactions.getLikeText(event);
              myLikeMap[likeText] = 1;
            }
          }
          List<Widget> ers = [];
          for (var entry in eventReactions.likeNumMap.entries) {
            var likeText = entry.key;
            var num = entry.value;

            Color color = hintColor;
            if (myLikeMap[likeText] != null) {
              color = mainColor;
            }

            ers.add(Container(
              margin: const EdgeInsets.only(right: Base.basePaddingHalf),
              child: EventReactionEmojiNumWidget(
                iconData: Icons.favorite_rounded,
                iconText: likeText,
                num: num,
                color: color,
                fontSize: fontSize,
              ),
            ));
          }

          mainList.add(Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.only(
              left: Base.basePadding,
              right: Base.basePadding,
              bottom: Base.basePaddingHalf,
            ),
            width: double.maxFinite,
            child: Wrap(
              runSpacing: Base.basePaddingHalf,
              spacing: Base.basePaddingHalf,
              alignment: WrapAlignment.center,
              children: ers,
            ),
          ));
        }

        return Container(
          padding: const EdgeInsets.only(
            bottom: Base.basePaddingHalf,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: mainList,
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
    } else if (value == "broadcast") {
      nostr!.broadcast(widget.event);
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
    }
  }

  void _doCopy(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      if (!mounted) return;
      BotToast.showText(text: S.of(context).Copy_success);
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

    // later: reply maybe change the placeholder in editor router.
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

      if (settingsProvider.broadcastWhenBoost == OpenStatus.open) {
        nostr!.broadcast(widget.event);
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
    relayAddrs.addAll(userProvider.getExtraRelays(widget.event.pubkey, false));

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
      var groupIdentifier =
          GroupIdentifierInheritedWidget.getGroupIdentifier(context);
      if (groupIdentifier != null) {
        relayAddrs = [groupIdentifier.host];
      }
    }

    return relayAddrs;
  }
}

class EventReactionNumWidget extends StatelessWidget {
  final String? iconText;

  final IconData iconData;

  final int num;

  final GestureTapCallback? onTap;

  final GestureLongPressCallback? onLongPress;

  final Color color;

  final double fontSize;

  final Widget? showMoreWidget;

  const EventReactionNumWidget({
    super.key,
    this.iconText,
    required this.iconData,
    required this.num,
    this.onTap,
    this.onLongPress,
    required this.color,
    required this.fontSize,
    this.showMoreWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget? main;
    var iconWidget = Icon(
      iconData,
      size: 16,
      color: color,
    );

    List<Widget> list = [];
    if (StringUtil.isNotBlank(iconText)) {
      list.add(Text(iconText!));
    } else {
      list.add(iconWidget);
    }

    if (num != 0) {
      String numStr = NumberFormatUtil.format(num);

      list.add(Container(
        margin: const EdgeInsets.only(left: 4),
        child: Text(
          numStr,
          style: TextStyle(color: color, fontSize: fontSize),
        ),
      ));
      if (showMoreWidget != null) {
        list.add(showMoreWidget!);
      }
    }

    main = Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: list,
    );
    main = SizedBox(
      height: double.infinity,
      child: main,
    );

    if (onTap != null || onLongPress != null) {
      return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.translucent,
        child: main,
      );
    } else {
      return main;
    }
  }
}

class EventReactionEmojiNumWidget extends StatelessWidget {
  final String? iconText;

  final IconData iconData;

  final int num;

  final Color color;

  final double fontSize;

  const EventReactionEmojiNumWidget({
    super.key,
    this.iconText,
    required this.iconData,
    required this.num,
    required this.color,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Icon(
      iconData,
      size: 16,
      color: color,
    );

    List<Widget> list = [];
    if (StringUtil.isNotBlank(iconText)) {
      list.add(Text(iconText!));
    } else {
      list.add(iconWidget);
    }

    if (num != 0) {
      String numStr = NumberFormatUtil.format(num);

      list.add(Container(
        margin: const EdgeInsets.only(left: 4),
        child: Text(
          numStr,
          style: TextStyle(color: color, fontSize: fontSize),
        ),
      ));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: list,
    );
  }
}
