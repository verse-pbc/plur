import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/content/content_video_widget.dart';
import 'package:nostrmo/component/content/markdown/markdown_mention_event_element_builder.dart';
import 'package:nostrmo/component/event/event_torrent_widget.dart';
import 'package:nostrmo/component/event/event_zap_goals_widget.dart';
import 'package:nostrmo/component/user/simple_name_widget.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/consts/base64.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../consts/base.dart';
import '../../consts/base_consts.dart';
import '../../consts/router_path.dart';
import '../../data/metadata.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/metadata_provider.dart';
import '../../provider/settings_provider.dart';
import '../../util/router_util.dart';
import '../confirm_dialog.dart';
import '../content/content_widget.dart';
import '../content/content_image_widget.dart';
import '../content/content_link_widget.dart';
import '../content/content_tag_widget.dart';
import '../content/markdown/markdown_mention_event_inline_syntax.dart';
import '../content/markdown/markdown_mention_user_element_builder.dart';
import '../content/markdown/markdown_mention_user_inline_syntax.dart';
import '../content/markdown/markdown_naddr_inline_syntax.dart';
import '../content/markdown/markdown_nevent_inline_syntax.dart';
import '../content/markdown/markdown_nprofile_inline_syntax.dart';
import '../content/markdown/markdown_nrelay_element_builder.dart';
import '../content/markdown/markdown_nrelay_inline_syntax copy.dart';
import '../zap/zap_split_icon_widget.dart';
import 'event_poll_widget.dart';
import '../webview_widget.dart';
import 'event_quote_widget.dart';
import 'event_reactions_widget.dart';
import 'event_top_widget.dart';

class EventMainWidget extends StatefulWidget {
  final ScreenshotController screenshotController;

  final Event event;

  final String? pagePubkey;

  final bool showReplying;

  final Function? textOnTap;

  final bool showVideo;

  final bool imageListMode;

  final bool showDetailBtn;

  final bool showLongContent;

  final bool showSubject;

  final bool showCommunity;

  final EventRelation? eventRelation;

  final bool showLinkedLongForm;

  final bool inQuote;

  final bool traceMode;

  const EventMainWidget({
    super.key,
    required this.screenshotController,
    required this.event,
    this.pagePubkey,
    this.showReplying = true,
    this.textOnTap,
    this.showVideo = false,
    this.imageListMode = false,
    this.showDetailBtn = true,
    this.showLongContent = false,
    this.showSubject = true,
    this.showCommunity = true,
    this.eventRelation,
    this.showLinkedLongForm = true,
    this.inQuote = false,
    this.traceMode = false,
  });

  @override
  State<StatefulWidget> createState() {
    return _EventMainWidgetState();
  }
}

class _EventMainWidgetState extends State<EventMainWidget> {
  bool showWarning = false;

  late EventRelation eventRelation;

  @override
  void initState() {
    super.initState();
    if (widget.eventRelation == null) {
      eventRelation = EventRelation.fromEvent(widget.event);
    } else {
      eventRelation = widget.eventRelation!;
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return doBuild(context);
    } catch (e, stacktrace) {
      log(
        "build error",
        error: e,
        stackTrace: stacktrace
      );
      return Container();
    }
  }

  Widget doBuild(BuildContext context) {
    final localization = S.of(context);
    var settingsProvider = Provider.of<SettingsProvider>(context);
    if (eventRelation.id != widget.event.id) {
      // change when thread root load lazy
      eventRelation = EventRelation.fromEvent(widget.event);
    }

    bool imagePreview = settingsProvider.imagePreview == null ||
        settingsProvider.imagePreview == OpenStatus.OPEN;
    bool videoPreview = widget.showVideo;
    if (settingsProvider.videoPreview != null) {
      videoPreview = settingsProvider.videoPreview == OpenStatus.OPEN;
    }

    final themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;
    var largeTextSize = themeData.textTheme.bodyLarge!.fontSize;
    var mainColor = themeData.primaryColor;

    Event? repostEvent;
    if ((widget.event.kind == EventKind.repost ||
            widget.event.kind == EventKind.genericRepost) &&
        widget.event.content.contains("\"pubkey\"")) {
      try {
        var jsonMap = jsonDecode(widget.event.content);
        repostEvent = Event.fromJson(jsonMap);

        // set source to repost event
        if (repostEvent.id == eventRelation.rootId &&
            StringUtil.isNotBlank(eventRelation.rootRelayAddr)) {
          repostEvent.sources.add(eventRelation.rootRelayAddr!);
        } else if (repostEvent.id == eventRelation.replyId &&
            StringUtil.isNotBlank(eventRelation.replyRelayAddr)) {
          repostEvent.sources.add(eventRelation.replyRelayAddr!);
        }
      } catch (e) {
        log("repost event parse error", name: "event_main_widget", error: e);
      }
    }

    if (settingsProvider.autoOpenSensitive == OpenStatus.OPEN) {
      showWarning = true;
    }

    List<Widget> list = [];
    if (showWarning || !eventRelation.warning) {
      if (widget.event.kind == EventKind.longForm) {
        var longFormMargin =
            const EdgeInsets.only(bottom: Base.basePaddingHalf);

        List<Widget> subList = [];
        var longFormInfo = LongFormInfo.fromEvent(widget.event);
        if (StringUtil.isNotBlank(longFormInfo.title)) {
          subList.add(
            Container(
              margin: longFormMargin,
              child: Text(
                longFormInfo.title!,
                maxLines: 10,
                style: TextStyle(
                  fontSize: largeTextSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }
        if (longFormInfo.topics.isNotEmpty) {
          List<Widget> topicWidgets = [];
          for (var topic in longFormInfo.topics) {
            topicWidgets.add(ContentTagWidget(tag: "#$topic"));
          }

          subList.add(Container(
            margin: longFormMargin,
            child: Wrap(
              spacing: Base.basePaddingHalf,
              runSpacing: Base.basePaddingHalf / 2,
              children: topicWidgets,
            ),
          ));
        }
        if (StringUtil.isNotBlank(longFormInfo.summary)) {
          Widget summaryTextWidget = Text(
            longFormInfo.summary!,
            style: TextStyle(
              color: hintColor,
            ),
          );
          subList.add(
            Container(
              width: double.infinity,
              margin: longFormMargin,
              child: summaryTextWidget,
            ),
          );
        }
        if (StringUtil.isNotBlank(longFormInfo.image)) {
          subList.add(Container(
            margin: longFormMargin,
            child: ContentImageWidget(
              imageUrl: longFormInfo.image!,
            ),
          ));
        }

        list.add(
          SizedBox(
            width: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: subList,
            ),
          ),
        );

        if (widget.showLongContent &&
            StringUtil.isNotBlank(widget.event.content)) {
          var markdownWidget = buildMarkdownWidget(themeData);
          list.add(SizedBox(
            width: double.infinity,
            child: RepaintBoundary(child: markdownWidget),
          ));
        }

        if (eventRelation.zapInfos.isNotEmpty) {
          list.add(buildZapInfoWidgets(themeData));
        }

        list.add(EventReactionsWidget(
          screenshotController: widget.screenshotController,
          event: widget.event,
          eventRelation: eventRelation,
          showDetailBtn: widget.showDetailBtn,
        ));
      } else if (widget.event.kind == EventKind.repost ||
          widget.event.kind == EventKind.genericRepost) {
        list.add(Container(
          alignment: Alignment.centerLeft,
          child: Text("${localization.Boost}:"),
        ));
        if (repostEvent != null) {
          list.add(EventQuoteWidget(
            event: repostEvent,
            showVideo: widget.showVideo,
          ));
        } else {
          var rootId = eventRelation.rootId;
          var rootRelayAddr = eventRelation.rootRelayAddr;
          if (StringUtil.isBlank(rootId)) {
            // rootId can't find, try to find any e tag.
            for (var tag in widget.event.tags) {
              if (tag.length > 1) {
                var k = tag[0];
                var v = tag[1];

                if (k == "e") {
                  rootId = v;
                  if (tag.length > 2 && tag[2] != "") {
                    rootRelayAddr = tag[2];
                  }
                  break;
                }
              }
            }
          }

          if (StringUtil.isNotBlank(rootId)) {
            list.add(EventQuoteWidget(
              id: rootId,
              eventRelayAddr: rootRelayAddr,
              showVideo: widget.showVideo,
            ));
          } else {
            list.add(
              buildContentWidget(settingsProvider, imagePreview, videoPreview),
            );
          }
        }
      } else if (widget.event.kind == EventKind.storageSharedFile) {
        list.add(buildStorageSharedFileWidget());
        if (!widget.inQuote) {
          if (eventRelation.zapInfos.isNotEmpty) {
            list.add(buildZapInfoWidgets(themeData));
          }

          list.add(EventReactionsWidget(
            screenshotController: widget.screenshotController,
            event: widget.event,
            eventRelation: eventRelation,
            showDetailBtn: widget.showDetailBtn,
          ));
        }
      } else {
        if (widget.showReplying && eventRelation.tagPList.isNotEmpty) {
          var textStyle = TextStyle(
            color: hintColor,
            fontSize: smallTextSize,
          );
          List<Widget> replyingList = [];
          var length = eventRelation.tagPList.length;
          replyingList.add(Text(
            "${localization.Replying}: ",
            style: textStyle,
          ));
          for (var index = 0; index < length; index++) {
            var p = eventRelation.tagPList[index];
            var isLast = index < length - 1 ? false : true;
            replyingList.add(EventReplyingComponent(pubkey: p));
            if (!isLast) {
              replyingList.add(Text(
                " & ",
                style: textStyle,
              ));
            }
          }
          list.add(Container(
            width: double.maxFinite,
            padding: const EdgeInsets.only(
              bottom: Base.basePaddingHalf,
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: replyingList,
            ),
          ));
        } else {
          // hide the reply note subject!
          if (widget.showSubject) {
            if (StringUtil.isNotBlank(eventRelation.subject)) {
              list.add(Container(
                width: double.infinity,
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.only(bottom: Base.basePaddingHalf),
                child: Text(
                  eventRelation.subject!,
                  maxLines: 10,
                  style: TextStyle(
                    fontSize: largeTextSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ));
            }
          }
        }

        list.add(
          buildContentWidget(settingsProvider, imagePreview, videoPreview),
        );

        if (widget.event.kind == EventKind.poll) {
          list.add(EventPollWidget(
            event: widget.event,
          ));
        } else if (widget.event.kind == EventKind.zapGoals ||
            StringUtil.isNotBlank(eventRelation.zapraiser)) {
          list.add(EventZapGoalsWidget(
            event: widget.event,
            eventRelation: eventRelation,
          ));
        }

        if (widget.event.kind == EventKind.fileHeader ||
            widget.event.kind == EventKind.videoHorizontal ||
            widget.event.kind == EventKind.videoVertical) {
          String? m;
          String? url;
          List? imeta;
          String? previewImage;
          List<String> tagList = [];
          for (var tag in widget.event.tags) {
            if (tag.length > 1) {
              var key = tag[0];
              var value = tag[1];
              if (key == "url") {
                url = value;
              } else if (key == "m") {
                m = value;
              } else if (key == "imeta") {
                imeta = tag;
              } else if (key == "t") {
                tagList.add(value);
              }
            }
          }

          if (imeta != null) {
            for (var tagItem in imeta) {
              if (tagItem is! String) {
                continue;
              }

              var strs = tagItem.split(" ");
              if (strs.length > 1) {
                var key = strs[0];
                var value = strs[1];
                if (key == "url" && url == null) {
                  url = value;
                } else if (key == "m" && url == null) {
                  m = value;
                } else if (key == "image" && previewImage == null) {
                  previewImage = value;
                }
              }
            }
          }

          if (StringUtil.isNotBlank(url)) {
            if (widget.event.kind == EventKind.videoHorizontal ||
                widget.event.kind == EventKind.videoVertical) {
              if (settingsProvider.videoPreview == OpenStatus.OPEN &&
                  widget.showVideo) {
                list.add(ContentVideoWidget(url: url!));
              } else {
                list.add(ContentLinkWidget(link: url!));
              }
            } else {
              //  show and decode depend m
              if (StringUtil.isNotBlank(m)) {
                if (m!.indexOf("image/") == 0) {
                  list.add(ContentImageWidget(imageUrl: url!));
                } else if (m.indexOf("video/") == 0 && widget.showVideo) {
                  list.add(ContentVideoWidget(url: url!));
                } else {
                  list.add(ContentLinkWidget(link: url!));
                }
              } else {
                var fileType = PathTypeUtil.getPathType(url!);
                if (fileType == "image") {
                  list.add(ContentImageWidget(imageUrl: url));
                } else if (fileType == "video") {
                  if (settingsProvider.videoPreview != OpenStatus.OPEN &&
                      (settingsProvider.videoPreviewInList == OpenStatus.OPEN ||
                          widget.showVideo)) {
                    list.add(ContentVideoWidget(url: url));
                  } else {
                    list.add(ContentLinkWidget(link: url));
                  }
                } else {
                  list.add(ContentLinkWidget(link: url));
                }
              }
            }
          }

          if (tagList.isNotEmpty) {
            List<Widget> topicWidgets = [];
            for (var topic in tagList) {
              topicWidgets.add(ContentTagWidget(tag: "#$topic"));
            }

            list.add(Container(
              margin: const EdgeInsets.only(top: Base.basePaddingHalf),
              child: Wrap(
                spacing: Base.basePaddingHalf,
                runSpacing: Base.basePaddingHalf / 2,
                children: topicWidgets,
              ),
            ));
          }
        }

        if (eventRelation.aId != null &&
            eventRelation.aId!.kind == EventKind.longForm &&
            widget.showLinkedLongForm) {
          list.add(EventQuoteWidget(
            aId: eventRelation.aId!,
          ));
        }

        if (widget.event.kind == EventKind.torrents) {
          var torrentInfo = TorrentInfo.fromEvent(widget.event);
          if (torrentInfo != null) {
            list.add(EventTorrentWidget(torrentInfo));
          }
        }

        if (eventRelation.zapInfos.isNotEmpty) {
          list.add(buildZapInfoWidgets(themeData));
        }

        if (widget.event.kind != EventKind.zap &&
            !(widget.event.kind == EventKind.fileHeader && widget.inQuote)) {
          list.add(EventReactionsWidget(
            screenshotController: widget.screenshotController,
            event: widget.event,
            eventRelation: eventRelation,
            showDetailBtn: widget.showDetailBtn,
          ));
        } else {
          list.add(Container(
            height: Base.basePadding,
          ));
        }
      }
    } else {
      list.add(buildWarningWidget(largeTextSize!, mainColor));
    }

    List<Widget> eventAllList = [];

    if (eventRelation.aId != null &&
        eventRelation.aId!.kind == EventKind.communityDefinition &&
        widget.showCommunity) {
      var communityTitle = Row(
        children: [
          Icon(
            Icons.groups,
            size: largeTextSize,
            color: hintColor,
          ),
          Container(
            margin: const EdgeInsets.only(
              left: Base.basePaddingHalf,
              right: 3,
            ),
            child: Text(
              localization.From,
              style: TextStyle(
                color: hintColor,
                fontSize: smallTextSize,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              RouterUtil.router(
                  context, RouterPath.COMMUNITY_DETAIL, eventRelation.aId);
            },
            child: Text(
              eventRelation.aId!.title,
              style: TextStyle(
                fontSize: smallTextSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );

      eventAllList.add(Container(
        padding: EdgeInsets.only(
          left: Base.basePadding + 4,
          right: Base.basePadding + 4 + (widget.traceMode ? 40 : 0),
          bottom: Base.basePaddingHalf,
        ),
        child: communityTitle,
      ));
    }

    if (!(widget.inQuote &&
        (widget.event.kind == EventKind.fileHeader ||
            widget.event.kind == EventKind.storageSharedFile))) {
      eventAllList.add(EventTopWidget(
        event: widget.event,
        pagePubkey: widget.pagePubkey,
      ));
    }

    eventAllList.add(Container(
      width: double.maxFinite,
      padding: EdgeInsets.only(
        left: Base.basePadding + (widget.traceMode ? 40 : 0),
        right: Base.basePadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
    ));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: eventAllList,
    );
  }

  bool hideLongContent = false;

  Widget buildContentWidget(
      SettingsProvider settingsProvider, bool imagePreview, bool videoPreview) {
    var content = widget.event.content;
    if (StringUtil.isBlank(content) &&
        widget.event.kind == EventKind.zap &&
        StringUtil.isNotBlank(eventRelation.innerZapContent)) {
      content = eventRelation.innerZapContent!;
    }

    var main = SizedBox(
      width: double.maxFinite,
      child: ContentWidget(
        content: content,
        event: widget.event,
        textOnTap: widget.textOnTap,
        showImage: imagePreview,
        showVideo: videoPreview,
        showLinkPreview: settingsProvider.linkPreview == OpenStatus.OPEN,
        imageListMode: widget.imageListMode,
        eventRelation: eventRelation,
      ),
    );

    return main;
  }

  buildMarkdownWidget(ThemeData themeData) {
    // handle old mention, replace to NIP-27 style: nostr:note1xxxx or nostr:npub1xxx
    var content = widget.event.content;
    var tagLength = widget.event.tags.length;
    for (var i = 0; i < tagLength; i++) {
      var tag = widget.event.tags[i];
      String? link;

      if (tag is List && tag.length > 1) {
        var key = tag[0];
        var value = tag[1];
        if (key == "e") {
          link = "nostr:${Nip19.encodeNoteId(value)}";
        } else if (key == "p") {
          link = "nostr:${Nip19.encodePubKey(value)}";
        }
      }

      if (StringUtil.isNotBlank(link)) {
        content = content.replaceAll("#[$i]", link!);
      }
    }

    return MarkdownBody(
      data: content,
      selectable: true,
      builders: {
        MarkdownMentionUserElementBuilder.TAG:
            MarkdownMentionUserElementBuilder(),
        MarkdownMentionEventElementBuilder.TAG:
            MarkdownMentionEventElementBuilder(),
        MarkdownNrelayElementBuilder.TAG: MarkdownNrelayElementBuilder(),
      },
      blockSyntaxes: const [],
      inlineSyntaxes: [
        MarkdownMentionEventInlineSyntax(),
        MarkdownMentionUserInlineSyntax(),
        MarkdownNaddrInlineSyntax(),
        MarkdownNeventInlineSyntax(),
        MarkdownNprofileInlineSyntax(),
        MarkdownNrelayInlineSyntax(),
      ],
      imageBuilder: (Uri uri, String? title, String? alt) {
        if (settingsProvider.imagePreview == OpenStatus.CLOSE) {
          return ContentLinkWidget(
            link: uri.toString(),
            title: title,
          );
        }
        return ContentImageWidget(imageUrl: uri.toString());
      },
      styleSheet: MarkdownStyleSheet(
        a: TextStyle(
          color: themeData.primaryColor,
          decoration: TextDecoration.underline,
          decorationColor: themeData.primaryColor,
        ),
      ),
      onTapLink: (String text, String? href, String title) async {
        if (StringUtil.isNotBlank(href)) {
          if (href!.indexOf("http") == 0) {
            WebViewWidget.open(context, href);
          } else if (href.indexOf("nostr:") == 0) {
            var link = href.replaceFirst("nostr:", "");
            if (Nip19.isPubkey(link)) {
              // jump user page
              var pubkey = Nip19.decode(link);
              if (StringUtil.isNotBlank(pubkey)) {
                RouterUtil.router(context, RouterPath.USER, pubkey);
              }
            } else if (NIP19Tlv.isNprofile(link)) {
              var nprofile = NIP19Tlv.decodeNprofile(link);
              if (nprofile != null) {
                RouterUtil.router(context, RouterPath.USER, nprofile.pubkey);
              }
            } else if (Nip19.isNoteId(link)) {
              var noteId = Nip19.decode(link);
              if (StringUtil.isNotBlank(noteId)) {
                RouterUtil.router(context, RouterPath.EVENT_DETAIL, noteId);
              }
            } else if (NIP19Tlv.isNevent(link)) {
              var nevent = NIP19Tlv.decodeNevent(link);
              if (nevent != null) {
                RouterUtil.router(context, RouterPath.EVENT_DETAIL, nevent.id);
              }
            } else if (NIP19Tlv.isNaddr(link)) {
              var naddr = NIP19Tlv.decodeNaddr(link);
              if (naddr != null) {
                RouterUtil.router(context, RouterPath.EVENT_DETAIL, naddr.id);
              }
            } else if (NIP19Tlv.isNrelay(link)) {
              var nrelay = NIP19Tlv.decodeNrelay(link);
              if (nrelay != null) {
                var result = await ConfirmDialog.show(
                    context, S.of(context).Add_this_relay_to_local);
                if (result == true) {
                  relayProvider.addRelay(nrelay.addr);
                }
              }
            }
          }
        }
      },
    );
  }

  Widget buildWarningWidget(double largeTextSize, Color mainColor) {
    final localization = S.of(context);

    return Container(
      margin: const EdgeInsets.only(
          bottom: Base.basePadding, top: Base.basePadding),
      width: double.maxFinite,
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning),
              Container(
                margin: const EdgeInsets.only(left: Base.basePaddingHalf),
                child: Text(
                  localization.Content_warning,
                  style: TextStyle(fontSize: largeTextSize),
                ),
              )
            ],
          ),
          Text(localization.This_note_contains_sensitive_content),
          GestureDetector(
            onTap: () {
              setState(() {
                showWarning = true;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(top: Base.basePaddingHalf),
              padding: const EdgeInsets.only(
                top: 4,
                bottom: 4,
                left: Base.basePadding,
                right: Base.basePadding,
              ),
              decoration: BoxDecoration(
                color: mainColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                localization.Show,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStorageSharedFileWidget() {
    var content = widget.event.content;
    var type = eventRelation.type;

    if (!content.startsWith(BASE64.PREFIX)) {
      content = BASE64.PNG_PREFIX + content;
    }

    if (type != null && type.startsWith("image")) {
      return ContentImageWidget(
        imageUrl: content,
        fileMetadata: eventRelation.fileMetadatas[content],
      );
    } else if (type != null && type.startsWith("video")) {
      return ContentVideoWidget(
        url: content,
      );
    } else {
      log("buildSharedFileWidget not support type $type");
      return ContentWidget(
        content: widget.event.content,
        event: widget.event,
        eventRelation: eventRelation,
      );
    }
  }

  Widget buildZapInfoWidgets(ThemeData themeData) {
    List<Widget> list = [];

    list.add(ZapSplitIconWidget(themeData.textTheme.bodyMedium!.fontSize!));

    var imageWidgetHeight = themeData.textTheme.bodyMedium!.fontSize! + 10;
    var imageWidgetWidth = themeData.textTheme.bodyMedium!.fontSize! + 2;
    var imgSize = themeData.textTheme.bodyMedium!.fontSize! + 2;

    List<Widget> userWidgetList = [];
    for (var zapInfo in eventRelation.zapInfos) {
      userWidgetList.add(Container(
        margin: const EdgeInsets.only(left: Base.basePaddingHalf),
        child: Selector<MetadataProvider, Metadata?>(
          builder: (context, metadata, child) {
            return GestureDetector(
              onTap: () {
                RouterUtil.router(context, RouterPath.USER, zapInfo.pubkey);
              },
              child: Container(
                width: imageWidgetWidth,
                height: imageWidgetHeight,
                alignment: Alignment.center,
                child: UserPicWidget(
                  pubkey: zapInfo.pubkey,
                  width: imgSize,
                  metadata: metadata,
                ),
              ),
            );
          },
          selector: (buildContext, provider) {
            return provider.getMetadata(zapInfo.pubkey);
          },
        ),
      ));
    }
    list.add(Expanded(
      child: Wrap(
        children: userWidgetList,
      ),
    ));

    return Container(
      margin: const EdgeInsets.only(top: Base.basePaddingHalf),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
    );
  }
}

class EventReplyingComponent extends StatefulWidget {
  final String pubkey;

  const EventReplyingComponent({super.key, required this.pubkey});

  @override
  State<StatefulWidget> createState() {
    return _EventReplyingComponent();
  }
}

class _EventReplyingComponent extends State<EventReplyingComponent> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        RouterUtil.router(context, RouterPath.USER, widget.pubkey);
      },
      child: Selector<MetadataProvider, Metadata?>(
        builder: (context, metadata, child) {
          final themeData = Theme.of(context);
          var hintColor = themeData.hintColor;
          var smallTextSize = themeData.textTheme.bodySmall!.fontSize;
          var displayName =
              SimpleNameWidget.getSimpleName(widget.pubkey, metadata);

          return Text(
            displayName,
            style: TextStyle(
              color: hintColor,
              fontSize: smallTextSize,
            ),
          );
        },
        selector: (_, provider) {
          return provider.getMetadata(widget.pubkey);
        },
      ),
    );
  }
}
