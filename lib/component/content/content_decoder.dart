import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/content/content_event_tag_infos.dart';

import '../../consts/base.dart';
import '../event/event_quote_widget.dart';
import '../translate/line_translate_widget.dart';
import 'content_custom_emoji_widget.dart';
import 'content_image_widget.dart';
import 'content_link_widget.dart';
import 'content_link_pre_widget.dart';
import 'content_lnbc_widget.dart';
import 'content_mention_user_widget.dart';
import 'content_relay_widget.dart';
import 'content_tag_widget.dart';
import 'content_video_widget.dart';

class ContentDecoder {
  static const otherLightning = "lightning=";

  static const lightning = "lightning:";

  static const lnbc = "lnbc";

  static const noteReferences = "nostr:";

  static const noteReferencesAt = "@nostr:";

  static const mentionUser = "@npub";

  static const mentionNote = "@note";

  static const lnbcNumEnd = "1p";

  static const int npubLength = 63;

  static const int noteidLength = 63;

  static String _addToHandledStr(String handledStr, String subStr) {
    if (StringUtil.isBlank(handledStr)) {
      return subStr;
    } else {
      return "$handledStr $subStr";
    }
  }

  static String _closeHandledStr(String handledStr, List<dynamic> inlines) {
    if (StringUtil.isNotBlank(handledStr)) {
      // inlines.add(Text(handledStr));
      inlines.add(handledStr);
    }
    return "";
  }

  static void _closeInlines(List<dynamic> inlines, List<Widget> list,
      {Function? textOnTap}) {
    if (inlines.isNotEmpty) {
      if (inlines.length == 1) {
        if (inlines[0] is String) {
          list.add(LineTranslateWidget(
            [inlines[0]],
            textOnTap: textOnTap,
          ));
        } else {
          list.add(inlines[0]);
        }
      } else {
        list.add(LineTranslateWidget(
          [...inlines],
          textOnTap: textOnTap,
        ));
      }
      inlines.clear();
    }
  }

  static ContentDecoderInfo _decodeTest(String content) {
    content = content.trim();
    content = content.replaceAll("\r\n", "\n");
    content = content.replaceAll("\n\n", "\n");
    var strs = content.split("\n");

    ContentDecoderInfo info = ContentDecoderInfo();
    for (var str in strs) {
      var subStrs = str.split(" ");
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

  @Deprecated(
      "This method had bean Deprecated, it should insteaded by ContentWidget")
  static List<Widget> decode(
    BuildContext context,
    String? content,
    Event? event, {
    Function? textOnTap,
    bool showImage = true,
    bool showVideo = false,
    bool showLinkPreview = true,
    bool imageListMode = false,
  }) {
    if (StringUtil.isBlank(content) && event != null) {
      content = event.content;
    }
    List<Widget> list = [];
    List<String> imageList = [];

    var decodeInfo = _decodeTest(content!);
    ContentEventTagInfos? tagInfos;
    if (event != null) {
      tagInfos = ContentEventTagInfos.fromEvent(event);
    }

    for (var subStrs in decodeInfo.strs) {
      List<dynamic> inlines = [];
      String handledStr = "";

      ///
      /// 1、str: add to handledStr
      /// 2、inline: put handledStr to inlines, put currentInline to inlines, new a new handledStr
      /// 3、block: put handledStr to inlines, put inlines to list as a line, put block to list as a line, new a new handledStr
      /// 4、if handledStr not empty, put to inlines, put inlines to list as a line
      ///
      for (var subStr in subStrs) {
        if (subStr.indexOf("http") == 0) {
          // link, image, video etc
          var pathType = PathTypeUtil.getPathType(subStr);
          if (pathType == "image") {
            if (showImage) {
              imageList.add(subStr);
              if (imageListMode && decodeInfo.imageNum > 1) {
                // inline
                handledStr = handledStr.trim();
                var imagePlaceholder = Container(
                  margin: const EdgeInsets.only(left: 4),
                  child: const Icon(
                    Icons.image,
                    size: 15,
                  ),
                );
                if (StringUtil.isBlank(handledStr) && inlines.isEmpty) {
                  // add to pre line
                  var listLength = list.length;
                  if (listLength > 0) {
                    var lastListWidget = list[listLength - 1];
                    List<InlineSpan> spans = [];
                    if (lastListWidget is SelectableText) {
                      if (lastListWidget.data != null) {
                        spans.add(TextSpan(text: lastListWidget.data!));
                      } else if (lastListWidget.textSpan != null) {
                        spans.addAll(lastListWidget.textSpan!.children!);
                      }
                    } else {
                      spans.add(WidgetSpan(child: lastListWidget));
                    }
                    spans.add(WidgetSpan(child: imagePlaceholder));

                    list[listLength - 1] = SelectableText.rich(
                      TextSpan(children: spans),
                      onTap: () {
                        if (textOnTap != null) {
                          textOnTap();
                        }
                      },
                    );
                  }
                } else {
                  if (StringUtil.isNotBlank(handledStr)) {
                    handledStr = _closeHandledStr(handledStr, inlines);
                  }
                  inlines.add(imagePlaceholder);
                }
              } else {
                // block
                handledStr = _closeHandledStr(handledStr, inlines);
                _closeInlines(inlines, list, textOnTap: textOnTap);
                var imageIndex = imageList.length - 1;
                var imageWidget = ContentImageWidget(
                  imageUrl: subStr,
                  imageList: imageList,
                  imageIndex: imageIndex,
                );
                list.add(imageWidget);
              }
            } else {
              // inline
              handledStr = _closeHandledStr(handledStr, inlines);
              inlines.add(ContentLinkWidget(link: subStr));
            }
          } else if (pathType == "video") {
            if (showVideo && !PlatformUtil.isPC()) {
              // block
              handledStr = _closeHandledStr(handledStr, inlines);
              _closeInlines(inlines, list, textOnTap: textOnTap);
              var w = ContentVideoWidget(url: subStr);
              list.add(w);
            } else {
              // inline
              handledStr = _closeHandledStr(handledStr, inlines);
              inlines.add(ContentLinkWidget(link: subStr));
            }
            // need to handle, this is temp handle
            // handledStr = _addToHandledStr(handledStr, subStr);
          } else if (pathType == "link") {
            if (!showLinkPreview) {
              // inline
              handledStr = _closeHandledStr(handledStr, inlines);
              inlines.add(ContentLinkWidget(link: subStr));
            } else {
              // block
              handledStr = _closeHandledStr(handledStr, inlines);
              _closeInlines(inlines, list, textOnTap: textOnTap);
              var w = ContentLinkPreWidget(
                link: subStr,
              );
              list.add(w);
            }
          }
        } else if (subStr.indexOf(noteReferences) == 0 ||
            subStr.indexOf(noteReferencesAt) == 0) {
          var key = subStr.replaceFirst(noteReferencesAt, "");
          key = key.replaceFirst(noteReferences, "");

          String? otherStr;

          if (Nip19.isPubkey(key)) {
            // inline
            // mention user
            if (key.length > npubLength) {
              otherStr = key.substring(npubLength);
              key = key.substring(0, npubLength);
            }
            key = Nip19.decode(key);
            handledStr = _closeHandledStr(handledStr, inlines);
            inlines.add(ContentMentionUserWidget(pubkey: key));
          } else if (Nip19.isNoteId(key)) {
            // block
            if (key.length > noteidLength) {
              otherStr = key.substring(noteidLength);
              key = key.substring(0, noteidLength);
            }
            key = Nip19.decode(key);
            handledStr = _closeHandledStr(handledStr, inlines);
            _closeInlines(inlines, list, textOnTap: textOnTap);
            var widget = EventQuoteWidget(
              id: key,
              showVideo: showVideo,
            );
            list.add(widget);
          } else if (NIP19Tlv.isNprofile(key)) {
            var nprofile = NIP19Tlv.decodeNprofile(key);
            if (nprofile != null) {
              // inline
              // mention user
              handledStr = _closeHandledStr(handledStr, inlines);
              inlines.add(ContentMentionUserWidget(pubkey: nprofile.pubkey));
            } else {
              handledStr = _addToHandledStr(handledStr, subStr);
            }
          } else if (NIP19Tlv.isNrelay(key)) {
            var nrelay = NIP19Tlv.decodeNrelay(key);
            if (nrelay != null) {
              // inline
              handledStr = _closeHandledStr(handledStr, inlines);
              inlines.add(ContentRelayWidget(nrelay.addr));
            } else {
              handledStr = _addToHandledStr(handledStr, subStr);
            }
          } else if (NIP19Tlv.isNevent(key)) {
            var nevent = NIP19Tlv.decodeNevent(key);
            if (nevent != null) {
              // block
              handledStr = _closeHandledStr(handledStr, inlines);
              _closeInlines(inlines, list, textOnTap: textOnTap);
              var widget = EventQuoteWidget(
                id: nevent.id,
                eventRelayAddr:
                    nevent.relays != null && nevent.relays!.isNotEmpty
                        ? nevent.relays![0]
                        : null,
                showVideo: showVideo,
              );
              list.add(widget);
            } else {
              handledStr = _addToHandledStr(handledStr, subStr);
            }
          } else if (NIP19Tlv.isNaddr(key)) {
            var naddr = NIP19Tlv.decodeNaddr(key);
            if (naddr != null) {
              if (StringUtil.isNotBlank(naddr.id) &&
                  naddr.kind == EventKind.textNote) {
                // block
                handledStr = _closeHandledStr(handledStr, inlines);
                _closeInlines(inlines, list, textOnTap: textOnTap);
                var widget = EventQuoteWidget(
                  id: naddr.id,
                  eventRelayAddr:
                      naddr.relays != null && naddr.relays!.isNotEmpty
                          ? naddr.relays![0]
                          : null,
                  showVideo: showVideo,
                );
                list.add(widget);
              } else if (StringUtil.isNotBlank(naddr.author) &&
                  naddr.kind == EventKind.metadata) {
                // inline
                handledStr = _closeHandledStr(handledStr, inlines);
                inlines.add(ContentMentionUserWidget(pubkey: naddr.author));
              } else {
                handledStr = _addToHandledStr(handledStr, subStr);
              }
            } else {
              handledStr = _addToHandledStr(handledStr, subStr);
            }
          } else {
            handledStr = _addToHandledStr(handledStr, subStr);
          }

          if (StringUtil.isNotBlank(otherStr)) {
            handledStr = _addToHandledStr(handledStr, otherStr!);
          }
        } else if (subStr.indexOf(mentionUser) == 0) {
          var key = subStr.replaceFirst("@", "");
          // inline
          // mention user
          key = Nip19.decode(key);
          handledStr = _closeHandledStr(handledStr, inlines);
          inlines.add(ContentMentionUserWidget(pubkey: key));
        } else if (subStr.indexOf(mentionNote) == 0) {
          var key = subStr.replaceFirst("@", "");
          // block
          key = Nip19.decode(key);
          handledStr = _closeHandledStr(handledStr, inlines);
          _closeInlines(inlines, list, textOnTap: textOnTap);
          var widget = EventQuoteWidget(
            id: key,
            showVideo: showVideo,
          );
          list.add(widget);
        } else if (subStr.indexOf(lnbc) == 0) {
          // block
          handledStr = _closeHandledStr(handledStr, inlines);
          _closeInlines(inlines, list, textOnTap: textOnTap);
          var w = ContentLnbcWidget(lnbc: subStr);
          list.add(w);
        } else if (subStr.indexOf(lightning) == 0) {
          // block
          handledStr = _closeHandledStr(handledStr, inlines);
          _closeInlines(inlines, list, textOnTap: textOnTap);
          var w = ContentLnbcWidget(lnbc: subStr);
          list.add(w);
        } else if (subStr.contains(otherLightning)) {
          // block
          handledStr = _closeHandledStr(handledStr, inlines);
          _closeInlines(inlines, list, textOnTap: textOnTap);
          var w = ContentLnbcWidget(lnbc: subStr);
          list.add(w);
        } else if (subStr.indexOf("#[") == 0 &&
            subStr.length > 3 &&
            event != null) {
          // mention
          var endIndex = subStr.indexOf("]");
          var indexStr = subStr.substring(2, endIndex);
          var index = int.tryParse(indexStr);
          if (index != null && event.tags.length > index) {
            var tag = event.tags[index];
            if (tag.length > 1) {
              var tagType = tag[0];
              String? relayAddr;
              if (tag.length > 2) {
                relayAddr = tag[2];
              }
              if (tagType == "e") {
                // block
                // mention event
                handledStr = _closeHandledStr(handledStr, inlines);
                _closeInlines(inlines, list, textOnTap: textOnTap);
                var widget = EventQuoteWidget(
                  id: tag[1],
                  eventRelayAddr: relayAddr,
                  showVideo: showVideo,
                );
                list.add(widget);
              } else if (tagType == "p") {
                // inline
                // mention user
                handledStr = _closeHandledStr(handledStr, inlines);
                inlines.add(ContentMentionUserWidget(pubkey: tag[1]));
              } else {
                handledStr = _addToHandledStr(handledStr, subStr);
              }
            }
          }
        } else if (subStr.indexOf("#") == 0 &&
            subStr.indexOf("[") != 1 &&
            subStr.length > 1 &&
            subStr.substring(1) != "#") {
          // inline
          // tag
          var extraStr = "";
          var length = subStr.length;
          if (tagInfos != null) {
            for (var hashtagInfo in tagInfos.tagEntryInfos) {
              var hashtag = hashtagInfo.key;
              var hashtagLength = hashtagInfo.value;
              if (subStr.indexOf(hashtag) == 1) {
                // dua to tagEntryInfos is sorted, so this is the match hashtag
                if (hashtagLength > 0 && length > hashtagLength) {
                  // this str's length is more then hastagLength, maybe there are some extraStr.
                  extraStr = subStr.substring(hashtagLength + 1);
                  subStr = "#$hashtag";
                }
                break;
              }
            }
          }

          handledStr = _closeHandledStr(handledStr, inlines);
          inlines.add(ContentTagWidget(tag: subStr));
          if (StringUtil.isNotBlank(extraStr)) {
            handledStr = _addToHandledStr(handledStr, extraStr);
          }
        } else {
          var length = subStr.length;
          if (length > 2) {
            if (subStr.substring(0, 1) == ":" &&
                subStr.substring(length - 1) == ":" &&
                tagInfos != null) {
              var emojiKey = subStr.substring(1, length - 1);
              var imagePath = tagInfos.emojiMap[emojiKey];
              // var imagePath = tagInfos.emojiMap[subStr];
              if (StringUtil.isNotBlank(imagePath)) {
                handledStr = _closeHandledStr(handledStr, inlines);
                inlines.add(ContentCustomEmojiWidget(imagePath: imagePath!));
                continue;
              }
            }
          }

          handledStr = _addToHandledStr(handledStr, subStr);
        }
      }

      handledStr = _closeHandledStr(handledStr, inlines);
      _closeInlines(inlines, list, textOnTap: textOnTap);
    }

    if (imageListMode && decodeInfo.imageNum > 1) {
      // showImageList in bottom
      List<Widget> imageWidgetList = [];
      var index = 0;
      for (var image in imageList) {
        imageWidgetList.add(SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.only(right: Base.basePaddingHalf),
            width: contentImageListHeight,
            height: contentImageListHeight,
            child: ContentImageWidget(
              imageUrl: image,
              imageList: imageList,
              imageIndex: index,
              height: contentImageListHeight,
              width: contentImageListHeight,
              // imageBoxFix: BoxFit.fitWidth,
            ),
          ),
        ));
        index++;
      }

      list.add(SizedBox(
        height: contentImageListHeight,
        width: double.infinity,
        child: CustomScrollView(
          slivers: imageWidgetList,
          scrollDirection: Axis.horizontal,
        ),
      ));
    }

    return list;
  }

  static const double contentImageListHeight = 90;
}

class ContentDecoderInfo {
  int imageNum = 0;
  List<List<String>> strs = [];
}
