import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/content/content_decoder.dart';
import 'package:nostrmo/component/content/content_music_widget.dart';
import 'package:nostrmo/component/content/trie_text_matcher/target_text_type.dart';
import 'package:nostrmo/component/content/trie_text_matcher/trie_text_matcher.dart';
import 'package:nostrmo/component/content/trie_text_matcher/trie_text_matcher_builder.dart';
import 'package:nostrmo/component/music/wavlake/wavlake_track_music_info_builder.dart';
import 'package:nostrmo/consts/base64.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/provider/settings_provider.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../event/event_quote_widget.dart';
import '../link_router_util.dart';
import '../music/blank_link_music_info_builder.dart';
import '../music/wavlake/wavlake_album_music_info_builder.dart';
import 'content_cashu_widget.dart';
import 'content_custom_emoji_widget.dart';
import 'content_event_tag_infos.dart';
import 'content_image_widget.dart';
import 'content_link_pre_widget.dart';
import 'content_lnbc_widget.dart';
import 'content_mention_user_widget.dart';
import 'content_relay_widget.dart';
import 'content_tag_widget.dart';
import 'content_video_widget.dart';

const int npubLength = 63;

const int noteIdLength = 63;

/// This is the new ContentWidget.
/// 1. Support image, video, link. These can config showable or replace by a str_line_component.
/// 2. Support imageListMode, true - use placeholder replaced in content and show imageList in last, false - show image in content.
/// 3. Support link, use a link preview to replace it.
/// 4. Support NIP-19, (npub, note, nprofile, nevent, nrelay, naddr). pre: (nostr:, @nostr:, @npub, @note...).
/// 5. Support Tag decode.
/// 6. Language check and auto translate.
/// 7. All inlineSpan must in the same SelectableText (Select all content one time).
/// 8. LNBC info decode (Lightning).
/// 9. Support Emoji (NIP-30)
/// 10.Show more, hide extra when the content is too long.
/// 11.Simple Markdown support. (LineStr with pre # - FontWeight blod and bigger fontSize, with pre ## - FontWeight blod and normal fontSize).
class ContentWidget extends StatefulWidget {
  final String? content;
  final Event? event;

  final Function? textOnTap;
  final bool showImage;
  final bool showVideo;
  final bool showLinkPreview;
  final bool imageListMode;

  final bool smallest;

  final EventRelation? eventRelation;

  const ContentWidget({
    super.key,
    this.content,
    this.event,
    this.textOnTap,
    this.showImage = true,
    this.showVideo = false,
    this.showLinkPreview = true,
    this.imageListMode = false,
    this.smallest = false,
    this.eventRelation,
  });

  @override
  State<StatefulWidget> createState() {
    return _ContentWidgetState();
  }
}

class _ContentWidgetState extends State<ContentWidget> {
  // new line
  static const String nl = "\n";

  // space
  static const String sp = " ";

  // markdown h1
  static const String mdH1 = "#";

  // markdown h2
  static const String mdH2 = "##";

  // markdown h3
  static const String mdH3 = "###";

  // markdown h4
  static const String mdH4 = "####";

  // markdown h5
  static const String mdH5 = "#####";

  // markdown h6
  static const String mdH6 = "######";

  // markdown quoting
  static const String mdQuoting = ">";

  // http pre
  static const String httpPre = "http://";

  // https pre
  static const String httpsPre = "https://";

  static const String preNostrBase = "nostr:";

  static const String preNostrAt = "@nostr:";

  static const String preAtUser = "@npub";

  static const String preAtNote = "@note";

  static const String preUser = "npub1";

  static const String preNote = "note1";

  static const otherLightning = "lightning=";

  static const lightning = "lightning:";

  static const lnbc = "lnbc";

  static const preCashuLink = "cashu:";

  static const preCashu = "cashu";

  static const maxShowLineNum = 19;

  static const maxShowLineNumReach = 23;

  TextStyle? mdh1Style;

  TextStyle? mdh2Style;

  TextStyle? mdh3Style;

  TextStyle? mdh4Style;

  TextStyle boldStyle = const TextStyle(
    fontWeight: FontWeight.w600,
  );

  TextStyle italicStyle = const TextStyle(
    fontStyle: FontStyle.italic,
  );

  TextStyle deleteStyle = const TextStyle(
    decoration: TextDecoration.lineThrough,
  );

  TextStyle? highlightStyle;

  TextStyle boldAndItalicStyle = const TextStyle(
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
  );

  TextStyle? tappableStyle;

  late StringBuffer counter;

  /// this list use to hold the real text, exclude the the text had bean decoded to embed.
  List<String> textList = [];

  double largeFontSize = 16;

  double fontSize = 14;

  double smallFontSize = 13;

  double iconWidgetWidth = 14;

  Color? hintColor;

  Color? codeBackgroundColor;

  TextSpan? translateTips;

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    final themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    smallFontSize = themeData.textTheme.bodySmall!.fontSize!;
    fontSize = themeData.textTheme.bodyMedium!.fontSize!;
    largeFontSize = themeData.textTheme.bodyLarge!.fontSize!;
    iconWidgetWidth = largeFontSize + 4;
    hintColor = themeData.hintColor;
    codeBackgroundColor = hintColor!.withOpacity(0.25);
    var settingsProvider = Provider.of<SettingsProvider>(context);
    mdh1Style = TextStyle(
      fontSize: largeFontSize + 1,
      fontWeight: FontWeight.bold,
    );
    mdh2Style = TextStyle(
      fontSize: largeFontSize,
      fontWeight: FontWeight.bold,
    );
    mdh3Style = TextStyle(
      fontSize: largeFontSize,
      fontWeight: FontWeight.w600,
    );
    mdh3Style = TextStyle(
      fontSize: largeFontSize,
      fontWeight: FontWeight.w600,
    );
    mdh4Style = TextStyle(
      fontSize: largeFontSize - 1,
      fontWeight: FontWeight.w600,
    );
    highlightStyle = TextStyle(
      backgroundColor: mainColor,
    );
    tappableStyle = TextStyle(
      color: themeData.primaryColor,
      decoration: TextDecoration.none,
    );

    if (StringUtil.isBlank(widget.content)) {
      return Container();
    }

    counter = StringBuffer();
    textList.clear();

    if (targetTextMap.isNotEmpty) {
      translateTips = TextSpan(
        text: " <- ${targetLanguage!.bcpCode} | ${sourceLanguage!.bcpCode} -> ",
        style: TextStyle(
          color: hintColor,
        ),
      );
    }

    var main = decodeContent();

    // decode complete, begin to checkAndTranslate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAndTranslate();
    });

    if (widget.imageListMode &&
        settingsProvider.limitNoteHeight != OpenStatus.close) {
      // imageListMode is true, means this content is in list, should limit height
      return LayoutBuilder(builder: (context, constraints) {
        TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
        textPainter.text = TextSpan(
            text: counter.toString(), style: TextStyle(fontSize: fontSize));
        textPainter.layout(maxWidth: constraints.maxWidth);
        var lineHeight = textPainter.preferredLineHeight;
        var lineNum = textPainter.height / lineHeight;

        if (lineNum > maxShowLineNumReach) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: const BoxDecoration(),
                clipBehavior: Clip.hardEdge,
                height: lineHeight * maxShowLineNum,
                child: Wrap(
                  children: [main],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: Base.basePadding),
                  height: 30,
                  color: themeData.cardColor.withOpacity(0.85),
                  child: Text(
                    localization.Show_more,
                    style: TextStyle(
                      color: themeData.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return main;
      });
    } else {
      return main;
    }
  }

  static const double contentImageListHeight = 90;

  TextStyle? currentTextStyle;

  ContentEventTagInfos? tagInfos;

  ContentDecoderInfo? contentDecoderInfo;

  /// decode the content to a SelectableText.
  /// 1. splite by \/n to lineStrs
  /// 2. handle lineStr
  ///     splite by `space` to strs
  /// 3. check and handle str
  ///   a. check first str and set lineTextStyle
  ///   b. check and handle str
  ///     `http://` styles: image, link, video
  ///     NIP-19 `nostr:, @nostr:, @npub, @note...` style
  ///     `#xxx` Tag style
  ///     LNBC `lnbc` `lightning:` `lightning=`
  ///     '#[number]' old style relate
  ///   c. flush buffer to string, handle emoji text, add to allSpans
  ///   d. allSpan set into simple SelectableText.rich
  Widget decodeContent() {
    if (StringUtil.isBlank(widget.content)) {
      return Container();
    }

    // decode event tag Info
    if (widget.event != null) {
      tagInfos = ContentEventTagInfos.fromEvent(widget.event!);
    } else {
      tagInfos = null;
    }
    List<InlineSpan> allList = [];
    List<InlineSpan> currentList = [];
    List<String> images = [];
    var buffer = StringBuffer();
    contentDecoderInfo = decodeTest(widget.content!);

    if (targetTextMap.isNotEmpty) {
      // has bean translate
      var iconBtn = WidgetSpan(
        child: GestureDetector(
          onTap: () {
            setState(() {
              showSource = !showSource;
              if (!showSource) {
                translateTips = null;
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(
              left: margin,
              right: margin,
            ),
            height: iconWidgetWidth,
            width: iconWidgetWidth,
            decoration: BoxDecoration(
              border: Border.all(width: 1, color: hintColor!),
              borderRadius: BorderRadius.circular(iconWidgetWidth / 2),
            ),
            child: Icon(
              Icons.translate,
              size: smallFontSize,
              color: hintColor,
            ),
          ),
        ),
      );
      allList.add(iconBtn);
    }

    var lineStrs = contentDecoderInfo!.strs;
    var lineLength = lineStrs.length;
    for (var i = 0; i < lineLength; i++) {
      // this line has text, begin to handle it.
      var strs = lineStrs[i];
      var strsLength = strs.length;
      bool lineBegin = true;
      for (var j = 0; j < strsLength; j++) {
        var str = strs[j];
        str = str.trim();

        if (lineBegin) {
          // the first str, check simple markdown support
          if (str == mdH1) {
            closeLine(buffer, currentList, allList, images);
            currentTextStyle = mdh1Style;
            continue;
          } else if (str == mdH2) {
            closeLine(buffer, currentList, allList, images);
            currentTextStyle = mdh2Style;
            continue;
          } else if (str == mdH3) {
            closeLine(buffer, currentList, allList, images);
            currentTextStyle = mdh3Style;
            continue;
          } else if (str == mdH4) {
            closeLine(buffer, currentList, allList, images);
            currentTextStyle = mdh4Style;
            continue;
          } else if (str == mdH5) {
            closeLine(buffer, currentList, allList, images);
            currentTextStyle = mdh4Style;
            continue;
          } else if (str == mdH6) {
            closeLine(buffer, currentList, allList, images);
            currentTextStyle = mdh4Style;
            continue;
          } else if (str == mdQuoting) {
            if (j == 0) {
              closeLine(buffer, currentList, allList, images);
              currentTextStyle = null;
            } else {
              bufferToList(buffer, currentList, images);
            }
            currentList.add(WidgetSpan(
                child: Container(
              width: 4,
              height: fontSize + 5.5,
              color: hintColor,
              margin: const EdgeInsets.only(right: Base.basePadding),
            )));
            continue;
          } else if (j == 0 && str.startsWith("```")) {
            // a new line start with ```, this is a block code
            // try to find the end ```
            int? endI;
            for (var tempI = i + 1; tempI < lineLength; tempI++) {
              var strs = lineStrs[tempI];
              if (strs.isNotEmpty && strs.first.startsWith("```")) {
                // find the end ``` !!!
                endI = tempI;
                break;
              }
            }
            if (endI != null) {
              List<String> codeLines = [];
              for (var tempI = i + 1; tempI < endI; tempI++) {
                var strs = lineStrs[tempI];
                codeLines.add(strs.join(sp));
              }

              var codeText = codeLines.join(nl);
              currentList.add(
                WidgetSpan(
                  child: Container(
                    padding: const EdgeInsets.all(Base.basePadding),
                    width: double.infinity,
                    decoration: BoxDecoration(color: codeBackgroundColor),
                    child: SelectableText(codeText),
                  ),
                ),
              );

              i = endI;
              break;
            }
          } else if (j == 0 &&
              (str.startsWith("---") ||
                  (str.startsWith("***") && strsLength == 1)) &&
              (str.replaceAll("-", "") == "" ||
                  str.replaceAll("*", "") == "")) {
            // is line start
            // str is start with --- or ***
            // str in only * or -
            bufferToList(buffer, currentList, images);
            currentList.add(const WidgetSpan(child: Divider()));
            if (j == strsLength - 1 && i + 1 < lineLength) {
              // current line is over and has next line, check if next line is NL only
              var nextStrs = lineStrs[i + 1];
              if (nextStrs.length == 1 && nextStrs[0] == "") {
                // next line is NL only, add this Widget span can help the display don't ignore the NLs after Divider
                currentList.add(const WidgetSpan(child: Text("")));
                // ignore the next NL
                i++;
              }
            }
            continue;
          } else if (j == 0) {
            if (currentTextStyle != null) {
              closeLine(buffer, currentList, allList, images);
            }
            currentTextStyle = null;
          }
        }

        if (str != "") {
          lineBegin = false;
        }

        var remain = checkAndHandleStr(str, buffer, currentList, images);
        if (remain != null) {
          buffer.write(remain);
        }

        if (j < strsLength - 1) {
          buffer.write(sp);
        }
      }

      if (i < lineLength - 1) {
        bufferToList(buffer, currentList, images);
        buffer.write(nl);
        bufferToList(buffer, currentList, images);
      }
    }
    closeLine(buffer, currentList, allList, images);

    var main = SizedBox(
      width: !widget.smallest ? double.infinity : null,
      // padding: EdgeInsets.only(bottom: 20),
      // color: Colors.red,
      child: SelectableText.rich(
        TextSpan(
          children: allList,
        ),
        onTap: () {
          if (widget.textOnTap != null) {
            widget.textOnTap!();
          }
        },
      ),
    );
    if (widget.showImage &&
        widget.imageListMode &&
        (contentDecoderInfo != null && contentDecoderInfo!.imageNum > 1)) {
      List<Widget> mainList = [main];
      // showImageList in bottom
      List<Widget> imageWidgetList = [];
      var index = 0;
      for (var image in images) {
        imageWidgetList.add(SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.only(right: Base.basePaddingHalf),
            width: contentImageListHeight,
            height: contentImageListHeight,
            child: ContentImageWidget(
              imageUrl: image,
              imageList: images,
              imageIndex: index,
              height: contentImageListHeight,
              width: contentImageListHeight,
              fileMetadata: getFileMetadata(image),
              // imageBoxFix: BoxFit.fitWidth,
            ),
          ),
        ));
        index++;
      }

      mainList.add(SizedBox(
        height: contentImageListHeight,
        width: double.infinity,
        child: CustomScrollView(
          slivers: imageWidgetList,
          scrollDirection: Axis.horizontal,
        ),
      ));

      return Column(
        children: mainList,
      );
    } else {
      return main;
    }
  }

  void closeLine(StringBuffer buffer, List<InlineSpan> currentList,
      List<InlineSpan> allList, List<String> images,
      {bool removeLastSpan = false}) {
    bufferToList(buffer, currentList, images, removeLastSpan: removeLastSpan);

    if (currentList.isNotEmpty) {
      allList.addAll(currentList);
    }

    currentList.clear();
  }

  String? checkAndHandleStr(String str, StringBuffer buffer,
      List<InlineSpan> currentList, List<String> images) {
    if (str.indexOf(httpsPre) == 0 ||
        str.indexOf(httpPre) == 0 ||
        str.indexOf(BASE64.prefix) == 0) {
      // http style, get path style
      var pathType = PathTypeUtil.getPathType(str);
      if (pathType == "image") {
        images.add(str);
        if (!widget.showImage) {
          currentList.add(buildLinkSpan(str));
        } else {
          if (widget.imageListMode &&
              (contentDecoderInfo != null &&
                  contentDecoderInfo!.imageNum > 1)) {
            // this content decode in list, use list mode
            var imagePlaceholder = const Icon(
              Icons.image,
              size: 15,
            );

            bufferToList(buffer, currentList, images, removeLastSpan: true);
            currentList.add(WidgetSpan(child: imagePlaceholder));
          } else {
            // show image in content
            var imageWidget = ContentImageWidget(
              imageUrl: str,
              imageList: images,
              imageIndex: images.length - 1,
              fileMetadata: getFileMetadata(str),
            );

            bufferToList(buffer, currentList, images, removeLastSpan: true);
            currentList.add(WidgetSpan(child: imageWidget));
            counterAddLines(fakeImageCounter);
          }
        }
        return null;
      } else if (pathType == "video") {
        if (widget.showVideo) {
          // block
          bufferToList(buffer, currentList, images, removeLastSpan: true);
          var vComponent = ContentVideoWidget(url: str);
          currentList.add(WidgetSpan(child: vComponent));
          counterAddLines(fakeVideoCounter);
        } else {
          // inline
          bufferToList(buffer, currentList, images);
          currentList.add(buildLinkSpan(str));
        }
        return null;
      } else if (pathType == "link") {
        // later: make a music builder list
        if (wavlakeTrackMusicInfoBuilder.check(str)) {
          // check if it is wavlake track link
          String? eventId;
          if (widget.event != null) {
            eventId = widget.event!.id;
          }
          bufferToList(buffer, currentList, images, removeLastSpan: true);
          var w =
              ContentMusicWidget(eventId, str, wavlakeTrackMusicInfoBuilder);
          currentList.add(WidgetSpan(child: w));
          counterAddLines(fakeMusicCounter);

          return null;
        }
        if (wavlakeAlbumMusicInfoBuilder.check(str)) {
          // check if it is wavlake track link
          String? eventId;
          if (widget.event != null) {
            eventId = widget.event!.id;
          }
          bufferToList(buffer, currentList, images, removeLastSpan: true);
          var w =
              ContentMusicWidget(eventId, str, wavlakeAlbumMusicInfoBuilder);
          currentList.add(WidgetSpan(child: w));
          counterAddLines(fakeMusicCounter);

          return null;
        }

        if (!widget.showLinkPreview) {
          // inline
          bufferToList(buffer, currentList, images);
          currentList.add(buildLinkSpan(str));
        } else {
          bufferToList(buffer, currentList, images, removeLastSpan: true);
          var w = ContentLinkPreWidget(
            link: str,
          );
          currentList.add(WidgetSpan(child: w));
          counterAddLines(fakeLinkPreCounter);
        }

        return null;
      } else if (pathType == "audio") {
        String? eventId;
        if (widget.event != null) {
          eventId = widget.event!.id;
        }
        bufferToList(buffer, currentList, images, removeLastSpan: true);
        var w = ContentMusicWidget(eventId, str, blankLinkMusicInfoBuilder);
        currentList.add(WidgetSpan(child: w));
        counterAddLines(fakeMusicCounter);

        return null;
      }
    } else if (str.indexOf(preNostrBase) == 0 ||
        str.indexOf(preNostrAt) == 0 ||
        str.indexOf(preAtUser) == 0 ||
        str.indexOf(preAtNote) == 0 ||
        str.indexOf(preUser) == 0 ||
        str.indexOf(preNote) == 0) {
      var key = str.replaceFirst("@", "");
      key = key.replaceFirst(preNostrBase, "");

      String? otherStr;

      if (Nip19.isPubkey(key)) {
        // inline
        // mention user
        if (key.length > npubLength) {
          otherStr = key.substring(npubLength);
          key = key.substring(0, npubLength);
        }
        key = Nip19.decode(key);
        bufferToList(buffer, currentList, images);
        currentList
            .add(WidgetSpan(child: ContentMentionUserWidget(pubkey: key)));

        return otherStr;
      } else if (Nip19.isNoteId(key)) {
        // block
        if (key.length > noteIdLength) {
          otherStr = key.substring(noteIdLength);
          key = key.substring(0, noteIdLength);
        }
        key = Nip19.decode(key);
        bufferToList(buffer, currentList, images, removeLastSpan: true);
        var w = EventQuoteWidget(
          id: key,
          showVideo: widget.showVideo,
        );
        currentList.add(WidgetSpan(child: w));
        counterAddLines(fakeEventCounter);

        return otherStr;
      } else if (NIP19Tlv.isNprofile(key)) {
        var index = Nip19.checkBech32End(key);
        if (index != null) {
          otherStr = key.substring(index);
          key = key.substring(0, index);
        }

        var nprofile = NIP19Tlv.decodeNprofile(key);
        if (nprofile != null) {
          // inline
          // mention user
          bufferToList(buffer, currentList, images);
          currentList.add(WidgetSpan(
              child: ContentMentionUserWidget(pubkey: nprofile.pubkey)));

          return otherStr;
        } else {
          return str;
        }
      } else if (NIP19Tlv.isNrelay(key)) {
        var index = Nip19.checkBech32End(key);
        if (index != null) {
          otherStr = key.substring(index);
          key = key.substring(0, index);
        }

        var nrelay = NIP19Tlv.decodeNrelay(key);
        if (nrelay != null) {
          // inline
          bufferToList(buffer, currentList, images);
          currentList.add(WidgetSpan(child: ContentRelayWidget(nrelay.addr)));

          return otherStr;
        } else {
          return str;
        }
      } else if (NIP19Tlv.isNevent(key)) {
        var index = Nip19.checkBech32End(key);
        if (index != null) {
          otherStr = key.substring(index);
          key = key.substring(0, index);
        }

        var nevent = NIP19Tlv.decodeNevent(key);
        if (nevent != null &&
            (nevent.kind == null ||
                EventKind.supportedEvents.contains(nevent.kind))) {
          // block
          bufferToList(buffer, currentList, images, removeLastSpan: true);
          var w = EventQuoteWidget(
            id: nevent.id,
            eventRelayAddr: nevent.relays != null && nevent.relays!.isNotEmpty
                ? nevent.relays![0]
                : null,
            showVideo: widget.showVideo,
          );
          currentList.add(WidgetSpan(child: w));
          counterAddLines(fakeEventCounter);

          return otherStr;
        } else {
          return str;
        }
      } else if (NIP19Tlv.isNaddr(key)) {
        var index = Nip19.checkBech32End(key);
        if (index != null) {
          otherStr = key.substring(index);
          key = key.substring(0, index);
        }

        var naddr = NIP19Tlv.decodeNaddr(key);
        if (naddr != null) {
          String? eventRelayAddr =
              naddr.relays != null && naddr.relays!.isNotEmpty
                  ? naddr.relays![0]
                  : null;
          if (StringUtil.isBlank(eventRelayAddr) && widget.event != null) {
            var ownerReadRelays =
                userProvider.getExtraRelays(widget.event!.pubkey, false);
            if (ownerReadRelays.isNotEmpty) {
              eventRelayAddr = ownerReadRelays.first;
            }
          }

          if (StringUtil.isNotBlank(naddr.author) &&
              naddr.kind == EventKind.metadata) {
            // inline
            bufferToList(buffer, currentList, images);
            currentList.add(WidgetSpan(
                child: ContentMentionUserWidget(pubkey: naddr.author)));

            return otherStr;
          } else if (StringUtil.isNotBlank(naddr.id) &&
              EventKind.supportedEvents.contains(naddr.kind)) {
            // block
            String? id = naddr.id;
            AId? aid;
            if (id.length > 64 && StringUtil.isNotBlank(naddr.author)) {
              aid =
                  AId(kind: naddr.kind, pubkey: naddr.author, title: naddr.id);
              id = null;
            }

            bufferToList(buffer, currentList, images, removeLastSpan: true);
            var w = EventQuoteWidget(
              id: id,
              aId: aid,
              eventRelayAddr: eventRelayAddr,
              showVideo: widget.showVideo,
            );
            currentList.add(WidgetSpan(child: w));
            counterAddLines(fakeEventCounter);

            return otherStr;
          } else if (naddr.kind == EventKind.liveEvent) {
            bufferToList(buffer, currentList, images, removeLastSpan: true);
            var w = ContentLinkPreWidget(
              link: "https://zap.stream/$key",
            );
            currentList.add(WidgetSpan(child: w));
            counterAddLines(fakeLinkPreCounter);

            return otherStr;
          }
        }
      }
    } else if (str.length > 1 &&
        str.substring(0, 1) == "#" &&
        !["[", "#"].contains(str.substring(1, 2))) {
      // first char is `#`, second isn't `[` and `#`
      // tag
      var extraStr = "";
      var length = str.length;
      if (tagInfos != null) {
        for (var hashtagInfo in tagInfos!.tagEntryInfos) {
          var hashtag = hashtagInfo.key;
          var hashtagLength = hashtagInfo.value;
          if (str.indexOf(hashtag) == 1) {
            // dua to tagEntryInfos is sorted, so this is the match hashtag
            if (hashtagLength > 0 && length > hashtagLength) {
              // this str's length is more then hashtagLength, maybe there are some extraStr.
              extraStr = str.substring(hashtagLength + 1);
              str = "#$hashtag";
            }
            break;
          }
        }
      }

      bufferToList(buffer, currentList, images);
      currentList.add(WidgetSpan(
        alignment: PlaceholderAlignment.bottom,
        child: ContentTagWidget(tag: str),
      ));
      if (StringUtil.isNotBlank(extraStr)) {
        return extraStr;
      }

      return null;
    } else if (str.indexOf(lnbc) == 0 ||
        str.indexOf(lightning) == 0 ||
        str.indexOf(otherLightning) == 0) {
      bufferToList(buffer, currentList, images, removeLastSpan: true);
      var w = ContentLnbcWidget(lnbc: str);
      currentList.add(WidgetSpan(child: w));
      counterAddLines(fakeZapCounter);

      return null;
    } else if (str.length > 20 && str.indexOf(preCashu) == 0) {
      var cashuStr = str.replaceFirst(preCashuLink, str);
      var cashuTokens = Tokens.load(cashuStr);
      if (cashuTokens != null) {
        // decode success
        bufferToList(buffer, currentList, images, removeLastSpan: true);
        var w = ContentCashuWidget(
          tokens: cashuTokens,
          cashuStr: cashuStr,
        );
        currentList.add(WidgetSpan(child: w));
        counterAddLines(fakeZapCounter);
        return null;
      }
    } else if (widget.event != null &&
        str.length > 3 &&
        str.indexOf("#[") == 0) {
      // mention
      var endIndex = str.indexOf("]");
      var indexStr = str.substring(2, endIndex);
      var index = int.tryParse(indexStr);
      if (index != null && widget.event!.tags.length > index) {
        var tag = widget.event!.tags[index];
        if (tag.length > 1) {
          var tagType = tag[0];
          String? relayAddr;
          if (tag.length > 2) {
            relayAddr = tag[2];
          }
          if (tagType == "e") {
            // block
            // mention event
            bufferToList(buffer, currentList, images, removeLastSpan: true);
            var w = EventQuoteWidget(
              id: tag[1],
              eventRelayAddr: relayAddr,
              showVideo: widget.showVideo,
            );
            currentList.add(WidgetSpan(child: w));
            counterAddLines(fakeEventCounter);

            return null;
          } else if (tagType == "p") {
            // inline
            // mention user
            bufferToList(buffer, currentList, images);
            currentList.add(
                WidgetSpan(child: ContentMentionUserWidget(pubkey: tag[1])));

            return null;
          }
        }
      }
    }
    return str;
  }

  void _removeEndBlank(List<InlineSpan> allList) {
    var length = allList.length;
    for (var i = length - 1; i >= 0; i--) {
      var span = allList[i];
      if (span is TextSpan) {
        var text = span.text;
        if (StringUtil.isNotBlank(text)) {
          text = text!.trimRight();
          if (StringUtil.isBlank(text)) {
            allList.removeLast();
          } else {
            allList[i] = TextSpan(text: text);
            return;
          }
        } else {
          allList.removeLast();
        }
      } else {
        return;
      }
    }
  }

  void bufferToList(
      StringBuffer buffer, List<InlineSpan> currentList, List<String> images,
      {bool removeLastSpan = false}) {
    var text = buffer.toString();
    if (removeLastSpan) {
      // sometimes if the pre text's last chat is NL, need to remove it.
      text = text.trimRight();
      if (StringUtil.isBlank(text)) {
        _removeEndBlank(currentList);
      }
    }
    buffer.clear();
    if (StringUtil.isBlank(text)) {
      return;
    }

    TrieTextMatcher matcher;
    if (tagInfos != null && tagInfos!.emojiMap.isNotEmpty) {
      matcher = TrieTextMatcherBuilder.build(emojiMap: tagInfos!.emojiMap);
    } else {
      matcher = defaultTrieTextMatcher;
    }

    var codeUnits = text.codeUnits;
    var result = matcher.check(codeUnits);

    for (var item in result.items) {
      if (item.textType == TargetTextType.pureText) {
        _addTextToList(
            codeUnitsToString(codeUnits, item.start, item.end), currentList);
      } else if (item.args.isNotEmpty) {
        var firstArg = item.args[0];

        // not pure text and args not empty
        if (item.textType == TargetTextType.mdLink) {
          if (item.args.length > 1) {
            var linkArg = item.args[1];
            if (linkArg.textType == TargetTextType.pureText) {
              var str =
                  codeUnitsToString(codeUnits, linkArg.start, linkArg.end);
              var pathType = PathTypeUtil.getPathType(str);

              if (pathType != "link" || !widget.showLinkPreview) {
                // inline
                currentList.add(buildLinkSpan(str));
              } else {
                var w = ContentLinkPreWidget(
                  link: str,
                );
                currentList.add(WidgetSpan(child: w));
                counterAddLines(fakeLinkPreCounter);
              }
            }
          }
        } else if (item.textType == TargetTextType.mdImage) {
          var linkArg = item.args.last;
          if (linkArg.textType == TargetTextType.pureText) {
            var str = codeUnitsToString(codeUnits, linkArg.start, linkArg.end);
            images.add(str);
            if (!widget.showImage) {
              currentList.add(buildLinkSpan(str));
            } else {
              if (widget.imageListMode &&
                  (contentDecoderInfo != null &&
                      contentDecoderInfo!.imageNum > 1)) {
                // this content decode in list, use list mode
                var imagePlaceholder = const Icon(
                  Icons.image,
                  size: 15,
                );

                currentList.add(WidgetSpan(child: imagePlaceholder));
              } else {
                // show image in content
                var imageWidget = ContentImageWidget(
                  imageUrl: str,
                  imageList: images,
                  imageIndex: images.length - 1,
                  fileMetadata: getFileMetadata(str),
                );

                currentList.add(WidgetSpan(child: imageWidget));
                counterAddLines(fakeImageCounter);
              }
            }
          }
        } else if (item.textType == TargetTextType.mdBold) {
          var str = codeUnitsToString(codeUnits, firstArg.start, firstArg.end);
          _addTextToList(str, currentList, textStyle: boldStyle);
        } else if (item.textType == TargetTextType.mdItalic) {
          var str = codeUnitsToString(codeUnits, firstArg.start, firstArg.end);
          _addTextToList(str, currentList, textStyle: italicStyle);
        } else if (item.textType == TargetTextType.mdDelete) {
          var str = codeUnitsToString(codeUnits, firstArg.start, firstArg.end);
          _addTextToList(str, currentList, textStyle: deleteStyle);
        } else if (item.textType == TargetTextType.mdHighlight) {
          var str = codeUnitsToString(codeUnits, firstArg.start, firstArg.end);
          _addTextToList(str, currentList, textStyle: highlightStyle);
        } else if (item.textType == TargetTextType.mdInlineCode) {
          var str = codeUnitsToString(codeUnits, firstArg.start, firstArg.end);
          currentList.add(TextSpan(
            text: str,
            style: TextStyle(
              backgroundColor: codeBackgroundColor,
            ),
          ));
        } else if (item.textType == TargetTextType.mdBoldAndItalic) {
          var str = codeUnitsToString(codeUnits, firstArg.start, firstArg.end);
          _addTextToList(str, currentList, textStyle: boldAndItalicStyle);
        }
      } else if (item.textType == TargetTextType.nostrCustomEmoji) {
        var emojiKey =
            codeUnitsToString(codeUnits, item.start + 1, item.end - 1);
        var emojiValue = tagInfos!.emojiMap[emojiKey];
        if (emojiValue != null) {
          currentList.add(WidgetSpan(
              child: ContentCustomEmojiWidget(
            imagePath: emojiValue,
          )));
        }
      }
    }

    return;
    // _addTextToList(text, currentList);
  }

  String codeUnitsToString(List<int> codeUnits, int start, int end) {
    var subList = codeUnits.sublist(start, end + 1);
    return String.fromCharCodes(subList);
  }

  void _addTextToList(String text, List<InlineSpan> allList,
      {TextStyle? textStyle}) {
    if (currentTextStyle != null) {
      if (textStyle == null) {
        textStyle = currentTextStyle;
      } else {
        textStyle = currentTextStyle!.merge(textStyle);
      }
    }

    counter.write(text);

    textList.add(text);
    var targetText = targetTextMap[text];
    if (targetText == null) {
      allList.add(TextSpan(text: text, style: textStyle));
    } else {
      allList.add(TextSpan(text: targetText, style: textStyle));
      if (showSource && translateTips != null) {
        allList.add(translateTips!);
        allList.add(TextSpan(text: text, style: textStyle));
      }
    }
  }

  TextSpan buildTappableSpan(String str, {GestureTapCallback? onTap}) {
    return TextSpan(
      text: str,
      style: tappableStyle,
      recognizer: TapGestureRecognizer()..onTap = onTap,
    );
  }

  TextSpan buildLinkSpan(String str) {
    return buildTappableSpan(str, onTap: () {
      LinkRouterUtil.router(context, str);
    });
  }

  static ContentDecoderInfo decodeTest(String content) {
    content = content.trim();
    var strs = content.split(nl);

    ContentDecoderInfo info = ContentDecoderInfo();
    for (var str in strs) {
      var subStrs = str.split(sp);
      info.strs.add(subStrs);
      for (var subStr in subStrs) {
        if (subStr.indexOf("http") == 0) {
          // link, image, video etc
          var pathType = PathTypeUtil.getPathType(subStr);
          if (pathType == "image") {
            info.imageNum++;
          }
        }
      }
    }

    return info;
  }

  int fakeEventCounter = 10;

  int fakeImageCounter = 11;

  int fakeVideoCounter = 11;

  int fakeLinkPreCounter = 7;

  int fakeMusicCounter = 3;

  int fakeZapCounter = 6;

  void counterAddLines(int lineNum) {
    for (var i = 0; i < lineNum; i++) {
      counter.write(nl);
    }
  }

  static const double margin = 4;

  Map<String, String> targetTextMap = {};

  String sourceText = "";

  TranslateLanguage? sourceLanguage;

  TranslateLanguage? targetLanguage;

  bool showSource = false;

  Future<void> checkAndTranslate() async {
    var newSourceText = "";
    newSourceText = textList.join();

    if (newSourceText.length > 1000) {
      return;
    }

    if (settingsProvider.openTranslate != OpenStatus.open) {
      // is close
      if (targetTextMap.isNotEmpty) {
        // set targetTextMap to null
        setState(() {
          targetTextMap.clear();
        });
      }
      return;
    } else {
      // is open
      // check targetTextMap
      if (targetTextMap.isNotEmpty) {
        // targetText had bean translated
        if (targetLanguage != null &&
            targetLanguage!.bcpCode == settingsProvider.translateTarget &&
            newSourceText == sourceText) {
          // and currentTargetLanguage = settingTranslate
          return;
        }
      }
    }

    var translateTarget = settingsProvider.translateTarget;
    if (StringUtil.isBlank(translateTarget)) {
      return;
    }
    targetLanguage = BCP47Code.fromRawValue(translateTarget!);
    if (targetLanguage == null) {
      return;
    }

    LanguageIdentifier? languageIdentifier;
    OnDeviceTranslator? onDeviceTranslator;

    sourceText = newSourceText;

    try {
      languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
      final List<IdentifiedLanguage> possibleLanguages =
          await languageIdentifier.identifyPossibleLanguages(newSourceText);

      if (possibleLanguages.isNotEmpty) {
        var pl = possibleLanguages[0];
        if (!settingsProvider.translateSourceArgsCheck(pl.languageTag)) {
          if (targetTextMap.isNotEmpty) {
            // set targetText to null
            setState(() {
              targetTextMap.clear();
            });
          }
          return;
        }

        sourceLanguage = BCP47Code.fromRawValue(pl.languageTag);
      }

      if (sourceLanguage != null) {
        onDeviceTranslator = OnDeviceTranslator(
            sourceLanguage: sourceLanguage!, targetLanguage: targetLanguage!);

        for (var text in textList) {
          if (text == nl || StringUtil.isBlank(text)) {
            continue;
          }
          var result = await onDeviceTranslator.translateText(text);
          if (StringUtil.isNotBlank(result)) {
            targetTextMap[text] = result;
          }
        }

        setState(() {});
      }
    } finally {
      if (languageIdentifier != null) {
        languageIdentifier.close();
      }
      if (onDeviceTranslator != null) {
        onDeviceTranslator.close();
      }
    }
  }

  getFileMetadata(String image) {
    if (widget.eventRelation != null) {
      return widget.eventRelation!.fileMetadatas[image];
    }
  }
}
