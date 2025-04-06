import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/confirm_dialog.dart';
import 'package:nostrmo/component/datetime_picker_widget.dart';
import 'package:nostrmo/component/editor/zap_goal_input_widget.dart';
import 'package:nostrmo/component/webview_widget.dart';
import 'package:nostrmo/consts/base64.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/sendbox/sendbox.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;

import '../../consts/base.dart';
import '../../data/custom_emoji.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/uploader.dart';
import '../../router/index/index_app_bar.dart';
import '../emoji_picker_widget.dart';
import '../image_widget.dart';
import '../zap/zap_split_icon_widget.dart';
import 'cust_embed_types.dart';
import 'custom_emoji_add_dialog.dart';
import 'gen_lnbc_widget.dart';
import 'poll_input_widget.dart';
import 'search_mention_event_widget.dart';
import 'search_mention_user_widget.dart';
import 'text_input_and_search_dialog.dart';
import 'text_input_dialog.dart';

mixin EditorMixin {
  quill.QuillController editorController = quill.QuillController.basic();

  PollInputController pollInputController = PollInputController();

  ZapGoalInputController zapGoalInputController = ZapGoalInputController();

  ScrollController btnScrollController = ScrollController();

  var focusNode = FocusNode();

  bool inputPoll = false;

  bool inputZapGoal = false;

  bool openPrivateDM = false;

  bool openZapSplit = false;

  bool isLongForm() {
    return false;
  }

  // is dm
  bool isDM();

  // dm arg
  String? getPubkey();

  // group arg
  GroupIdentifier? getGroupIdentifier() {
    return null;
  }

  // group event kind
  int? getGroupEventKind() {
    return null;
  }

  BuildContext getContext();

  void updateUI();

  List<dynamic> getTags();

  List<dynamic> getTagsAddedWhenSend();

  void handleFocusInit() {
    focusNode.addListener(() {
      if (focusNode.hasFocus && (emojiShow || customEmojiShow)) {
        emojiShow = false;
        customEmojiShow = false;
        updateUI();
      }
    });
  }

  Widget buildEditorBtns({
    bool showShadow = true,
    double? height = IndexAppBar.height,
  }) {
    final localization = S.of(getContext());
    var themeData = Theme.of(getContext());
    var cardColor = themeData.cardColor;
    var mainColor = themeData.primaryColor;
    var secondaryColor = themeData.colorScheme.secondary;
    var groupIdentifier = getGroupIdentifier();

    // Primary actions that should be most visible/accessible
    List<Widget> primaryBtns = [];
    
    // Add media buttons (image, camera, video)
    primaryBtns.add(
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: themeData.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: IconButton(
          onPressed: pickImage,
          icon: const Icon(Icons.photo_library_outlined, size: 24),
          tooltip: localization.Image_or_Video,
          color: mainColor,
        ),
      )
    );
    
    if (!PlatformUtil.isPC() && !PlatformUtil.isWeb()) {
      primaryBtns.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: themeData.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            onPressed: takeAPhoto,
            icon: const Icon(Icons.camera_alt_outlined, size: 24),
            tooltip: localization.Take_photo,
            color: mainColor,
          ),
        )
      );
      
      primaryBtns.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: themeData.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            onPressed: tackAVideo,
            icon: const Icon(Icons.videocam_outlined, size: 24),
            tooltip: localization.Take_video,
            color: mainColor,
          ),
        )
      );
    }
    
    // Add emoji buttons
    if (!isLongForm()) {
      primaryBtns.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: themeData.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            onPressed: emojiBeginToSelect,
            icon: Icon(
              Icons.emoji_emotions_outlined,
              size: 24,
              color: emojiShow ? secondaryColor : mainColor,
            ),
            tooltip: localization.Emoji,
          ),
        )
      );
      
      primaryBtns.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: themeData.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            onPressed: customEmojiSelect,
            icon: Icon(
              Icons.add_reaction_outlined,
              size: 24,
              color: customEmojiShow ? secondaryColor : mainColor,
            ),
            tooltip: localization.Custom_Emoji,
          ),
        )
      );
    }
    
    // Add mention and tag buttons
    primaryBtns.add(
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: themeData.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: IconButton(
          onPressed: _inputMentionUser,
          icon: const Icon(Icons.alternate_email, size: 24),
          tooltip: localization.Mention_User,
          color: mainColor,
        ),
      )
    );
    
    primaryBtns.add(
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: themeData.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: IconButton(
          onPressed: _inputTag,
          icon: const Icon(Icons.tag, size: 24),
          tooltip: localization.Hashtag,
          color: mainColor,
        ),
      )
    );
    
    // Secondary options menu button
    Widget moreOptionsButton = PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz, color: mainColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (String value) {
        switch (value) {
          case 'quote':
            _inputMentionEvent();
            break;
          case 'lightning':
            _inputLnbc();
            break;
          case 'zap_split':
            openZapSplitTap();
            break;
          case 'warning':
            _addWarning();
            break;
          case 'title':
            _addTitle();
            break;
          case 'schedule':
            selectedTime();
            break;
          case 'poll':
            _inputPoll();
            break;
          case 'goal':
            _inputGoal();
            break;
          case 'private_dm':
            changePrivateDM();
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        List<PopupMenuEntry<String>> items = [];
        
        // Quote and Lightning options for everyone
        items.add(
          PopupMenuItem<String>(
            value: 'quote',
            child: Row(
              children: [
                Icon(Icons.format_quote, color: mainColor),
                const SizedBox(width: 10),
                Text(localization.Quote),
              ],
            ),
          )
        );
        
        items.add(
          PopupMenuItem<String>(
            value: 'lightning',
            child: Row(
              children: [
                Icon(Icons.bolt, color: mainColor),
                const SizedBox(width: 10),
                Text(localization.Lightning_Invoice),
              ],
            ),
          )
        );
        
        // Private DM option only for DMs
        if (isDM() && groupIdentifier == null) {
          items.add(
            PopupMenuItem<String>(
              value: 'private_dm',
              child: Row(
                children: [
                  Icon(Icons.enhanced_encryption, 
                    color: openPrivateDM ? secondaryColor : mainColor),
                  const SizedBox(width: 10),
                  Text(openPrivateDM ? localization.Close_Private_DM : localization.Open_Private_DM),
                ],
              ),
            )
          );
        }
        
        // Options for non-DM posts
        if (!isDM()) {
          items.add(
            PopupMenuItem<String>(
              value: 'zap_split',
              child: Row(
                children: [
                  ZapSplitIconWidget(
                    themeData.textTheme.bodyLarge!.fontSize!,
                    color: openZapSplit ? secondaryColor : mainColor,
                  ),
                  const SizedBox(width: 10),
                  Text(localization.Split_and_Transfer_Zap),
                ],
              ),
            )
          );
          
          items.add(
            PopupMenuItem<String>(
              value: 'warning',
              child: Row(
                children: [
                  Icon(Icons.warning, color: showWarning ? Colors.red : mainColor),
                  const SizedBox(width: 10),
                  Text(localization.Sensitive_Content),
                ],
              ),
            )
          );
          
          if (!isLongForm()) {
            items.add(
              PopupMenuItem<String>(
                value: 'title',
                child: Row(
                  children: [
                    Icon(Icons.title, color: showTitle ? secondaryColor : mainColor),
                    const SizedBox(width: 10),
                    Text(localization.Subject),
                  ],
                ),
              )
            );
          }
          
          if (groupIdentifier == null && !isLongForm()) {
            items.add(
              PopupMenuItem<String>(
                value: 'schedule',
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, color: publishAt != null ? secondaryColor : mainColor),
                    const SizedBox(width: 10),
                    Text(localization.Delay_Send),
                  ],
                ),
              )
            );
          }
        }
        
        // Poll and Goal options for regular posts
        if (!isDM() &&
            getTags().isEmpty &&
            getTagsAddedWhenSend().isEmpty &&
            groupIdentifier == null &&
            !isLongForm()) {
          items.add(
            PopupMenuItem<String>(
              value: 'poll',
              child: Row(
                children: [
                  Icon(Icons.poll, color: inputPoll ? secondaryColor : mainColor),
                  const SizedBox(width: 10),
                  Text(localization.Poll),
                ],
              ),
            )
          );
          
          items.add(
            PopupMenuItem<String>(
              value: 'goal',
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: inputZapGoal ? secondaryColor : mainColor),
                  const SizedBox(width: 10),
                  Text(localization.Zap_Goals),
                ],
              ),
            )
          );
        }
        
        return items;
      },
    );
    
    primaryBtns.add(
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: themeData.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: moreOptionsButton,
      )
    );

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(0, -5),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: btnScrollController,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: primaryBtns,
          ),
        ),
      ),
    );
  }

  Widget buildEmojiSelector() {
    return EmojiPickerWidget(emojiInsert);
  }

  bool emojiShow = false;

  void emojiBeginToSelect() {
    FocusScope.of(getContext()).unfocus();
    if (emojiShow) {
      emojiShow = false;
    } else {
      emojiShow = true;
      customEmojiShow = false;
    }
    updateUI();
  }

  void emojiInsert(String emoji) {
    final index = editorController.selection.baseOffset;
    final length = editorController.selection.extentOffset - index;
    editorController.replaceText(
        index, length, emoji, TextSelection.collapsed(offset: index + 2),
        ignoreFocus: true);
    updateUI();
  }

  Future<void> changePrivateDM() async {
    if (!openPrivateDM) {
      var context = getContext();
      var result = await ConfirmDialog.show(
          getContext(), S.of(context).Private_DM_Notice);
      if (result == false || result == null) {
        return;
      }
    }

    openPrivateDM = !openPrivateDM;
    updateUI();
  }

  Future<void> pickImage() async {
    var files = await Uploader.pickFiles(getContext());
    for (var file in files) {
      _imageSubmitted(file);
    }
  }

  void _imageSubmitted(String? value) {
    if (value != null && value.isNotEmpty) {
      final index = editorController.selection.baseOffset;
      final length = editorController.selection.extentOffset - index;

      var fileType = PathTypeUtil.getPathType(value);
      if (fileType == "image") {
        editorController.replaceText(
            index, length, quill.BlockEmbed.image(value), null);

        editorController.moveCursorToPosition(index + 1);
      } else if (fileType == "video") {
        editorController.replaceText(
            index, length, quill.BlockEmbed.video(value), null);

        editorController.moveCursorToPosition(index + 1);
      }
    }
  }

  Future<void> takeAPhoto() async {
    ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      _imageSubmitted(photo.path);
    }
  }

  Future<void> tackAVideo() async {
    ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickVideo(source: ImageSource.camera);
    if (photo != null) {
      _imageSubmitted(photo.path);
    }
  }

  Future<void> _inputMentionEvent() async {
    var context = getContext();
    final localization = S.of(context);
    var value = await TextInputAndSearchDialog.show(
      context,
      localization.Search,
      localization.Please_input_event_id,
      const SearchMentionEventWidget(),
      hintText: localization.Note_Id,
    );
    if (StringUtil.isNotBlank(value)) {
      // check nip19 value
      if (Nip19.isNoteId(value!)) {
        value = Nip19.decode(value);
      }
      _submitMentionEvent(value);
    }
  }

  void _submitMentionEvent(String? value) {
    if (value != null && value.isNotEmpty) {
      final index = editorController.selection.baseOffset;
      final length = editorController.selection.extentOffset - index;

      editorController.replaceText(index, length,
          quill.CustomBlockEmbed(CustEmbedTypes.mention_event, value), null);

      editorController.moveCursorToPosition(index + 1);
    }
  }

  Future<void> _inputMentionUser() async {
    var context = getContext();
    final localization = S.of(context);
    var value = await TextInputAndSearchDialog.show(
      context,
      localization.Search,
      localization.Please_input_user_pubkey,
      SearchMentionUserWidget(
        groupIdentifier: getGroupIdentifier(),
      ),
      hintText: localization.User_Pubkey,
    );
    if (StringUtil.isNotBlank(value)) {
      // check nip19 value
      if (Nip19.isPubkey(value!)) {
        value = Nip19.decode(value);
      }
      _submitMentionUser(value);
    }
  }

  void _submitMentionUser(String? value) {
    if (value != null && value.isNotEmpty) {
      final index = editorController.selection.baseOffset;
      final length = editorController.selection.extentOffset - index;

      editorController.replaceText(index, length,
          quill.CustomBlockEmbed(CustEmbedTypes.mention_user, value), null);

      editorController.moveCursorToPosition(index + 1);
    }
  }

  Future<void> _inputLnbc() async {
    var context = getContext();
    var value = await TextInputAndSearchDialog.show(
      context,
      S.of(context).Input_Sats_num,
      S.of(context).Please_input_lnbc_text,
      const GenLnbcWidget(),
      hintText: "lnbc...",
    );
    if (StringUtil.isNotBlank(value)) {
      _lnbcSubmitted(value);
    }
  }

  void _lnbcSubmitted(String? value) {
    if (value != null && value.isNotEmpty) {
      final index = editorController.selection.baseOffset;
      final length = editorController.selection.extentOffset - index;

      editorController.replaceText(index, length,
          quill.CustomBlockEmbed(CustEmbedTypes.lnbc, value), null);

      editorController.moveCursorToPosition(index + 1);
    }
  }

  Future<void> _inputTag() async {
    var context = getContext();
    var value = await TextInputDialog.show(
        context, S.of(context).Please_input_Topic_text,
        valueCheck: baseInputCheck, hintText: S.of(context).Topic);
    if (StringUtil.isNotBlank(value)) {
      _submitTag(value);
    }
  }

  bool baseInputCheck(BuildContext context, String value) {
    if (value.contains(" ")) {
      BotToast.showText(text: S.of(context).Text_can_t_contain_blank_space);
      return false;
    }
    if (value.contains("\n")) {
      BotToast.showText(text: S.of(context).Text_can_t_contain_new_line);
      return false;
    }
    return true;
  }

  void _submitTag(String? value) {
    if (value != null && value.isNotEmpty) {
      final index = editorController.selection.baseOffset;
      final length = editorController.selection.extentOffset - index;

      editorController.replaceText(index, length,
          quill.CustomBlockEmbed(CustEmbedTypes.tag, value), null);

      editorController.moveCursorToPosition(index + 1);
    }
  }

  Future<Event?> doDocumentSave() async {
    var context = getContext();
    // dm pubkey
    var pubkey = getPubkey();
    var groupIdentifier = getGroupIdentifier();

    // customEmoji map
    Map<String, int> customEmojiMap = {};
    var tags = [...getTags()];
    var tagsAddedWhenSend = [...getTagsAddedWhenSend()];

    List<String> extralRelays = [];

    if (inputPoll) {
      var checkResult = pollInputController.checkInput(context);
      if (!checkResult) {
        return null;
      }
    }
    if (inputZapGoal) {
      var checkResult = zapGoalInputController.checkInput(context);
      if (!checkResult) {
        return null;
      }
    }

    var delta = editorController.document.toDelta();
    var operations = delta.toList();
    String result = "";
    for (var operation in operations) {
      if (operation.key == "insert") {
        if (operation.data is Map) {
          var m = operation.data as Map;
          var value = m["image"];
          if (StringUtil.isBlank(value)) {
            value = m["video"];
          }
          if (StringUtil.isNotBlank(value) && value is String) {
            if (value.indexOf("http") != 0) {
              // this is a local image, update it first
              var imagePath = await Uploader.upload(
                value,
                imageService: settingsProvider.imageService,
              );
              if (StringUtil.isNotBlank(imagePath)) {
                if (StringUtil.isNotBlank(m["image"])) {
                  // upload success! try to gen Blurhash, (NIP-92)
                  try {
                    Uint8List? fileBytes;
                    if (BASE64.check(value)) {
                      // is base64
                      fileBytes = BASE64.toData(value);
                    } else {
                      fileBytes = File(value).readAsBytesSync();
                    }

                    log("begin to gen blurhash");
                    final image = img.decodeImage(fileBytes);
                    final blurHash =
                        BlurHash.encode(image!, numCompX: 4, numCompY: 3);
                    log("blurhash $blurHash");

                    tagsAddedWhenSend.add([
                      "imeta",
                      "url $imagePath",
                      "blurhash ${blurHash.hash}",
                      "dim ${image.width}x${image.height}"
                    ]);
                  } catch (e) {
                    log('handle upload file NIP-92 info error: ${e.toString()}');
                  }
                }

                value = imagePath;
              } else {
                BotToast.showText(text: S.of(context).Upload_fail);
                return null;
              }
            }

            if (isLongForm()) {
              // transfer url to markdown
              value = "![]($value)";
            }

            result = handleBlockValue(result, value);
            continue;
          }

          value = m["lnbc"];
          if (StringUtil.isNotBlank(value)) {
            result = handleBlockValue(result, value);
            continue;
          }

          value = m["tag"];
          if (StringUtil.isNotBlank(value)) {
            result = handleInlineValue(result, "#" + value);
            tags.add(["t", value]);
            continue;
          }

          value = m["mentionUser"];
          if (StringUtil.isNotBlank(value)) {
            if (!_lastIsSpace(result) && !_lastIsLineEnd(result)) {
              result += " ";
            }
            result += "nostr:${Nip19.encodePubKey(value)} ";

            // add user's read relays
            extralRelays.addAll(userProvider.getExtralRelays(value, false));
            continue;
          }

          value = m["mentionEvent"];
          if (StringUtil.isNotBlank(value)) {
            if (!_lastIsLineEnd(result)) {
              result += " ";
            }
            // if (agreement == null) {
            //   var relayAddr = "";
            //   var mentionEvent = singleEventProvider.getEvent(value);
            //   if (mentionEvent != null && mentionEvent.sources.isNotEmpty) {
            //     relayAddr = mentionEvent.sources[0];
            //   }
            //   tags.add(["e", value, relayAddr, "mention"]);
            //   var index = tags.length - 1;
            //   result += "#[$index] ";
            // } else {
            //   result += "nostr:${Nip19.encodeNoteId(value)} ";
            // }
            var mentionEvent = singleEventProvider.getEvent(value);
            if (mentionEvent != null && mentionEvent.sources.isNotEmpty) {
              List<String> relays = [];
              if (mentionEvent.sources.length > 3) {
                relays.add(mentionEvent.sources[0]);
                relays.add(mentionEvent.sources[1]);
                relays.add(mentionEvent.sources[2]);
              } else {
                relays.addAll(mentionEvent.sources);
              }
              var nevent = Nevent(
                  id: value, relays: relays, author: mentionEvent.pubkey);
              result += "${NIP19Tlv.encodeNevent(nevent)} ";
            } else {
              result += "nostr:${Nip19.encodeNoteId(value)} ";
            }
            continue;
          }

          value = m["customEmoji"];
          if (value != null && value is CustomEmoji) {
            result += ":${value.name}: ";

            if (customEmojiMap[value.name] == null) {
              customEmojiMap[value.name!] = 1;
              tags.add(["emoji", value.name, value.filepath]);
            }
            continue;
          }
        } else {
          result += operation.data.toString();
        }
      }
    }
    result = result.trim();
    if (StringUtil.isBlank(result)) {
      return null;
    }

    List<dynamic> allTags = [];
    allTags.addAll(tags);
    allTags.addAll(tagsAddedWhenSend);

    var subject = subjectController.text;
    if (StringUtil.isNotBlank(subject)) {
      if (isLongForm()) {
        allTags.add(["title", subject]);
      } else {
        allTags.add(["subject", subject]);
      }
    }

    if (showWarning) {
      allTags.add(["content-warning", ""]);
    }

    if (eventZapInfos.isNotEmpty) {
      for (var zapInfo in eventZapInfos) {
        allTags.add([
          "zap",
          zapInfo.pubkey,
          zapInfo.relayAddr,
          zapInfo.weight.toStringAsFixed(2),
        ]);
      }
    }

    Event? event;
    List<Event> extralEvents = [];
    if (isDM() && StringUtil.isNotBlank(pubkey)) {
      if (openPrivateDM) {
        // Private dm message
        var rumorEvent = Event(
            nostr!.publicKey, EventKind.PRIVATE_DIRECT_MESSAGE, allTags, result,
            createdAt: getCreatedAt());
        // this is the event send to sender, should return after send and set into giftWrapProvider and dmProvider
        event = await GiftWrapUtil.getGiftWrapEvent(
            nostr!, rumorEvent, nostr!, nostr!.publicKey);

        // private dm need to send message to all receiver. (sender and other receivers)
        for (var tags in allTags) {
          if (tags is List && tags.length > 1) {
            if (tags[0] == "p") {
              var extralEvent = await GiftWrapUtil.getGiftWrapEvent(
                  nostr!, rumorEvent, nostr!, tags[1]);
              if (extralEvent != null) {
                extralEvents.add(extralEvent);
              }
            }
          }
        }
      } else {
        // dm message
        var encryptedResult = await nostr!.nostrSigner.encrypt(pubkey, result);
        if (encryptedResult == null) {
          return null;
        }
        result = encryptedResult;
        event = Event(
            nostr!.publicKey, EventKind.DIRECT_MESSAGE, allTags, result,
            createdAt: getCreatedAt());
      }
    } else if (groupIdentifier != null) {
      final eventKind = getGroupEventKind() ?? EventKind.GROUP_NOTE;
      // group event
      event = Event(
          nostr!.publicKey,
          eventKind,
          [
            ["h", groupIdentifier.groupId],
            ...allTags
          ],
          result,
          createdAt: getCreatedAt());
    } else if (inputPoll) {
      // poll event
      // get poll tag from PollInputComponent
      var pollTags = pollInputController.getTags();
      allTags.addAll(pollTags);
      event = Event(nostr!.publicKey, EventKind.POLL, allTags, result,
          createdAt: getCreatedAt());
    } else if (inputZapGoal) {
      // zap goal event
      var extralTags = zapGoalInputController.getTags();
      allTags.addAll(extralTags);
      event = Event(nostr!.publicKey, EventKind.ZAP_GOALS, allTags, result,
          createdAt: getCreatedAt());
    } else if (isLongForm()) {
      // long form

      // handle other long form info
      if (StringUtil.isNotBlank(longFormImage)) {
        allTags.add(["image", longFormImage]);
      }
      var summary = summaryController.text;
      if (StringUtil.isNotBlank(summary)) {
        if (StringUtil.isNotBlank(longFormImage)) {
          allTags.add(["summary", summary]);
        }
      }

      var id = DateTime.now().millisecondsSinceEpoch.toString();
      var writableRelays = relayProvider.getWritableRelays();
      String oneWriteRelay =
          writableRelays.isNotEmpty ? writableRelays.first : "";

      allTags.add(["d", id]);
      allTags.add([
        "a",
        "${EventKind.LONG_FORM}:${nostr!.publicKey}:$id",
        oneWriteRelay
      ]);

      event = Event(nostr!.publicKey, EventKind.LONG_FORM, allTags, result,
          createdAt: getCreatedAt());
    } else {
      // text note
      event = Event(nostr!.publicKey, EventKind.TEXT_NOTE, allTags, result,
          createdAt: getCreatedAt());
    }

    if (event == null) {
      return null;
    }

    log(jsonEncode(event.toJson()));
    if (groupIdentifier != null) {
      var groupRelays = [groupIdentifier.host];
      log("send group event to $groupRelays");
      event.sources.addAll(groupRelays);
      return nostr!
          .sendEvent(event, targetRelays: groupRelays, tempRelays: groupRelays);
    } else if (publishAt != null) {
      for (var extralEvent in extralEvents) {
        _handleSendingSendBoxEvent(extralEvent, extralRelays);
      }

      return _handleSendingSendBoxEvent(event, extralRelays);
    } else {
      for (var extralEvent in extralEvents) {
        _handleSendingEvent(extralEvent, extralRelays);
      }

      return _handleSendingEvent(event, extralRelays);
    }
  }

  Future<Event?> _handleSendingSendBoxEvent(
      Event e, List<String> extralRelays) async {
    if (StringUtil.isBlank(e.sig)) {
      nostr!.signEvent(e);
    }

    List<String> list = [...relayProvider.relayAddrs, ...extralRelays];
    for (var tag in e.tags) {
      if (tag is List && tag.length > 1) {
        var k = tag[0];
        var p = tag[1];
        if (k == "p") {
          list.addAll(userProvider.getExtralRelays(p, false));
        }
      }
    }
    list = list.toSet().toList();

    await SendBox.submit(e, list);

    return e;
  }

  Future<Event?> _handleSendingEvent(Event e, List<String> extralRelays) async {
    List<String> list = [...extralRelays];
    for (var tag in e.tags) {
      if (tag is List && tag.length > 1) {
        var k = tag[0];
        var p = tag[1];
        if (k == "p") {
          list.addAll(userProvider.getExtralRelays(p, false));
        }
      }
    }
    list = list.toSet().toList();

    if (StringUtil.isNotBlank(e.sig)) {
      return nostr!.broadcase(e, tempRelays: list);
    } else {
      return await nostr!.sendEvent(e, tempRelays: list);
    }
  }

  String handleInlineValue(String result, String value) {
    if (!_lastIsSpace(result) && !_lastIsLineEnd(result)) {
      result += " ";
    }
    result += "$value ";
    return result;
  }

  String handleBlockValue(String result, String value) {
    if (!_lastIsLineEnd(result)) {
      result += "\n";
    }
    result += "$value\n";
    return result;
  }

  bool _lastIsSpace(String str) {
    if (StringUtil.isBlank(str)) {
      return true;
    }

    var length = str.length;
    if (str[length - 1] == " ") {
      return true;
    }
    return false;
  }

  bool _lastIsLineEnd(String str) {
    if (StringUtil.isBlank(str)) {
      return true;
    }

    var length = str.length;
    if (str[length - 1] == "\n") {
      return true;
    }
    return false;
  }

  void _inputPoll() {
    var targetValue = !inputPoll;
    _resetOthersInput();
    inputPoll = targetValue;
    updateUI();
  }

  void _inputGoal() {
    var targetValue = !inputZapGoal;
    _resetOthersInput();
    inputZapGoal = targetValue;
    updateUI();
  }

  void _resetOthersInput() {
    pollInputController.clear();
    zapGoalInputController.clear();

    inputPoll = false;
    inputZapGoal = false;
  }

  bool customEmojiShow = false;

  void customEmojiSelect() {
    FocusScope.of(getContext()).unfocus();
    if (customEmojiShow) {
      customEmojiShow = false;
    } else {
      customEmojiShow = true;
      emojiShow = false;
    }
    updateUI();
  }

  Future<void> addCustomEmoji() async {
    var emoji = await CustomEmojiAddDialog.show(getContext());
    if (emoji != null) {
      listProvider.addCustomEmoji(emoji);
    }
  }

  void addEmojiToEditor(CustomEmoji emoji) {
    final index = editorController.selection.baseOffset;
    final length = editorController.selection.extentOffset - index;

    editorController.replaceText(
        index,
        length,
        quill.Embeddable(CustEmbedTypes.custom_emoji, emoji),
        TextSelection.collapsed(offset: index + 2),
        ignoreFocus: true);
    updateUI();
  }

  double emojiBtnWidth = 60;

  Widget buildEmojiListsWidget() {
    var context = getContext();
    final localization = S.of(context);
    final themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var labelUnSelectColor = themeData.hintColor;

    return Container(
      height: 260,
      padding: const EdgeInsets.only(left: Base.basePaddingHalf),
      width: double.infinity,
      child: Selector<ListProvider, Event?>(
        builder: (context, emojiEvent, child) {
          var emojiLists = listProvider.emojis(localization, emojiEvent);

          List<Widget> tabBarList = [];
          List<Widget> tabBarViewList = [];

          var length = emojiLists.length;
          for (var index = 0; index < length; index++) {
            var emojiList = emojiLists[index];
            var isCustomEmoji = index == 0;

            tabBarList.add(Text(
              emojiList.key,
              overflow: TextOverflow.ellipsis,
            ));
            tabBarViewList.add(buildEmojiListWidget(
              emojiList.value,
              isCustomEmoji: isCustomEmoji,
            ));
          }

          var findMoreBtn = GestureDetector(
            onTap: () {
              WebViewWidget.open(context, "https://emojis-iota.vercel.app/");
            },
            child: const SizedBox(
              width: 40,
              child: Icon(Icons.search),
            ),
          );

          return DefaultTabController(
              length: tabBarList.length,
              child: Column(
                children: [
                  SizedBox(
                    height: Base.tabBarHeight,
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: Base.tabBarHeight,
                            child: TabBar(
                              tabs: tabBarList,
                              indicatorColor: mainColor,
                              labelColor: mainColor,
                              unselectedLabelColor: labelUnSelectColor,
                              isScrollable: true,
                            ),
                          ),
                        ),
                        findMoreBtn,
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(children: tabBarViewList),
                  ),
                ],
              ));
        },
        selector: (_, provider) {
          return provider.getEmojiEvent();
        },
      ),
    );
  }

  Widget buildEmojiListWidget(List<CustomEmoji> emojis,
      {bool isCustomEmoji = false}) {
    List<Widget> list = [];

    if (isCustomEmoji) {
      list.add(GestureDetector(
        onTap: () {
          addCustomEmoji();
        },
        child: SizedBox(
          width: emojiBtnWidth,
          height: emojiBtnWidth,
          child: const Icon(
            Icons.add,
            size: 50,
          ),
        ),
      ));
    }

    for (var emoji in emojis) {
      list.add(GestureDetector(
        onTap: () {
          addEmojiToEditor(emoji);
        },
        child: Container(
          width: emojiBtnWidth,
          height: emojiBtnWidth,
          alignment: Alignment.center,
          child: ImageWidget(
            imageUrl: emoji.filepath!,
          ),
        ),
      ));
    }

    var main = SingleChildScrollView(
      child: Wrap(
        runSpacing: Base.basePaddingHalf,
        spacing: Base.basePaddingHalf,
        children: list,
      ),
    );

    return Container(
      height: 260,
      padding: const EdgeInsets.only(left: Base.basePaddingHalf),
      width: double.infinity,
      child: main,
    );
  }

  bool showWarning = false;

  void _addWarning() {
    showWarning = !showWarning;
    updateUI();
  }

  bool showTitle = false;

  TextEditingController subjectController = TextEditingController();

  void _addTitle() {
    subjectController.clear();
    showTitle = !showTitle;
    updateUI();
  }

  Widget buildTitleWidget() {
    var themeData = Theme.of(getContext());
    var fontSize = themeData.textTheme.bodyLarge!.fontSize;
    var hintColor = themeData.hintColor;
    final localization = S.of(getContext());

    return Container(
      // color: Colors.red,
      padding: const EdgeInsets.only(
        left: Base.basePadding,
        right: Base.basePadding,
      ),
      child: AutoSizeTextField(
        maxLength: 80,
        controller: subjectController,
        textInputAction: TextInputAction.next,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          hintText: localization.Please_input_title,
          border: InputBorder.none,
          hintStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.normal,
            color: hintColor.withOpacity(0.8),
          ),
          counterText: "",
        ),
      ),
    );
  }

  String? longFormImage;

  Future<void> pickAndUploadLongFormImage() async {
    longFormImage = null;
    var filepath = await Uploader.pick(getContext());
    if (StringUtil.isNotBlank(filepath)) {
      var cancelFunc = BotToast.showLoading();
      try {
        var fileUrl = await Uploader.upload(
          filepath!,
          imageService: settingsProvider.imageService,
        );
        longFormImage = fileUrl;
      } catch (e) {
        log('image upload fail $e');
      } finally {
        cancelFunc();
      }
    }
    updateUI();
  }

  Widget buildLongFormImageWidget() {
    Widget main = const Icon(Icons.image);

    if (StringUtil.isBlank(longFormImage)) {
      main = GestureDetector(
        onTap: pickAndUploadLongFormImage,
        child: main,
      );
    } else {
      main = GestureDetector(
        onTap: pickAndUploadLongFormImage,
        child: ImageWidget(imageUrl: longFormImage!),
      );
    }

    return Container(
      padding: const EdgeInsets.only(
        left: Base.basePadding,
        right: Base.basePadding,
      ),
      alignment: Alignment.centerLeft,
      child: main,
    );
  }

  TextEditingController summaryController = TextEditingController();

  Widget buildSummaryWidget() {
    var themeData = Theme.of(getContext());
    var fontSize = themeData.textTheme.bodyLarge!.fontSize;
    var hintColor = themeData.hintColor;
    final localization = S.of(getContext());

    return Container(
      // margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      padding: const EdgeInsets.only(
        left: Base.basePadding,
        right: Base.basePadding,
      ),
      child: TextField(
        maxLines: 5,
        minLines: 1,
        controller: summaryController,
        textInputAction: TextInputAction.next,
        style: TextStyle(
          fontSize: fontSize,
          // fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          hintText: localization.Please_input_summary,
          border: InputBorder.none,
          hintStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.normal,
            color: hintColor.withOpacity(0.8),
          ),
          counterText: "",
        ),
      ),
    );
  }

  DateTime? publishAt;

  int? getCreatedAt() {
    if (publishAt != null) {
      return publishAt!.millisecondsSinceEpoch ~/ 1000;
    }

    return null;
  }

  Future<void> selectedTime() async {
    var dt = await DatetimePickerWidget.show(getContext(),
        dateTime: publishAt ?? DateTime.now());
    publishAt = dt;
    updateUI();
  }

  List<EventZapInfo> eventZapInfos = [];

  void openZapSplitTap() {
    openZapSplit = !openZapSplit;
    if (!openZapSplit) {
      // close zap and clean infos
      eventZapInfos.clear();
    }
    updateUI();
  }
}
