import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/editor/editor_mixin.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/router/edit/editor_widget.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../../component/appbar_back_btn_widget.dart';
import '../../component/editor/custom_emoji_embed_builder.dart';
import '../../component/editor/lnbc_embed_builder.dart';
import '../../component/editor/mention_event_embed_builder.dart';
import '../../component/editor/mention_user_embed_builder.dart';
import '../../component/editor/pic_embed_builder.dart';
import '../../component/editor/tag_embed_builder.dart';
import '../../component/editor/video_embed_builder.dart';
import '../../component/user/name_widget.dart';
import '../../consts/base.dart';
import '../../data/metadata.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/dm_provider.dart';
import '../../provider/metadata_provider.dart';
import '../../util/router_util.dart';
import 'dm_detail_item_widget.dart';

class DMDetailWidget extends StatefulWidget {
  const DMDetailWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _DMDetailWidgetState();
  }
}

class _DMDetailWidgetState extends CustState<DMDetailWidget> with EditorMixin {
  DMSessionDetail? detail;

  @override
  void initState() {
    super.initState();
    handleFocusInit();
  }

  @override
  Widget doBuild(BuildContext context) {
    final themeData = Theme.of(context);
    var textColor = themeData.textTheme.bodyMedium!.color;
    var cardColor = themeData.cardColor;

    final localization = S.of(context);

    var arg = RouterUtil.routerArgs(context);
    if (arg == null) {
      RouterUtil.back(context);
      return Container();
    }
    detail = arg as DMSessionDetail;

    var dmProvider = Provider.of<DMProvider>(context);
    var newDetail = dmProvider.getSessionDetail(detail!.dmSession.pubkey);
    if (newDetail != null) {
      detail = newDetail;
    }

    var nameComponnet = Selector<MetadataProvider, Metadata?>(
      builder: (context, metadata, child) {
        return NameWidget(
          pubkey: detail!.dmSession.pubkey,
          metadata: metadata,
        );
      },
      selector: (_, provider) {
        return provider.getMetadata(detail!.dmSession.pubkey);
      },
    );

    var localPubkey = nostr!.publicKey;

    List<Widget> list = [];

    var newestEvent = detail!.dmSession.newestEvent;

    handleDefaultPrivateDMSetting(newestEvent);

    var listWidget = ListView.builder(
      itemBuilder: (context, index) {
        var event = detail!.dmSession.get(index);
        if (event == null) {
          return null;
        }

        return DMDetailItemWidget(
          sessionPubkey: detail!.dmSession.pubkey,
          event: event,
          isLocal: localPubkey == event.pubkey,
        );
      },
      reverse: true,
      itemCount: detail!.dmSession.length(),
      dragStartBehavior: DragStartBehavior.down,
    );

    list.add(Expanded(
      child: Container(
        margin: const EdgeInsets.only(
          bottom: Base.BASE_PADDING,
        ),
        child: listWidget,
      ),
    ));

    list.add(Container(
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, -5),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: quill.QuillEditor(
              configurations: quill.QuillEditorConfigurations(
                placeholder: localization.What_s_happening,
                embedBuilders: [
                  MentionUserEmbedBuilder(),
                  MentionEventEmbedBuilder(),
                  PicEmbedBuilder(),
                  VideoEmbedBuilder(),
                  LnbcEmbedBuilder(),
                  TagEmbedBuilder(),
                  CustomEmojiEmbedBuilder(),
                ],
                scrollable: true,
                autoFocus: false,
                expands: false,
                padding: const EdgeInsets.only(
                  left: Base.BASE_PADDING,
                  right: Base.BASE_PADDING,
                ),
                maxHeight: 300, controller: editorController,
              ),
              scrollController: ScrollController(),
              focusNode: focusNode,
            ),
          ),
          TextButton(
            onPressed: send,
            style: const ButtonStyle(),
            child: Text(
              localization.Send,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
              ),
            ),
          )
        ],
      ),
    ));

    list.add(buildEditorBtns(showShadow: false, height: null));
    if (emojiShow) {
      list.add(buildEmojiSelector());
    }
    if (customEmojiShow) {
      list.add(buildEmojiListsWidget());
    }

    Widget main = SizedBox(
      width: double.maxFinite,
      height: double.maxFinite,
      child: Column(children: list),
    );

    if (detail!.info == null && detail!.dmSession.newestEvent != null) {
      main = SizedBox(
        width: double.maxFinite,
        height: double.maxFinite,
        child: Stack(
          children: [
            Positioned.fill(child: main),
            Positioned(
              child: GestureDetector(
                onTap: addDmSessionToKnown,
                child: Container(
                  margin: const EdgeInsets.all(Base.BASE_PADDING),
                  height: 30,
                  width: double.maxFinite,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      localization.Add_to_known_list,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        title: nameComponnet,
      ),
      body: main,
    );
  }

  bool _handledDefaultPrivateDM = false;

  void handleDefaultPrivateDMSetting(Event? e) {
    if (!_handledDefaultPrivateDM &&
        e != null &&
        e.kind == EventKind.PRIVATE_DIRECT_MESSAGE) {
      openPrivateDM = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        updateUI();
      });
    }

    _handledDefaultPrivateDM = true;
  }

  Future<void> send() async {
    var cancelFunc = BotToast.showLoading();
    try {
      var event = await doDocumentSave();
      if (event == null) {
        BotToast.showText(text: S.of(context).Send_fail);
        return;
      }
      if (event.kind == EventKind.DIRECT_MESSAGE) {
        dmProvider.addEventAndUpdateReadedTime(detail!, event);
      } else if (event.kind == EventKind.GIFT_WRAP) {
        giftWrapProvider.onEvent(event);
      }

      editorController.clear();
      setState(() {});
    } finally {
      cancelFunc.call();
    }
  }
  Future<void> addDmSessionToKnown() async {
    var updatedDetail = await dmProvider.addDmSessionToKnown(detail!);
    setState(() {
      detail = updatedDetail;
    });
  }

  @override
  Future<void> onReady(BuildContext context) async {
    if (detail != null &&
        detail!.info != null &&
        detail!.dmSession.newestEvent != null) {
      dmProvider.updateReadedTime(detail);
    }
  }

  @override
  BuildContext getContext() {
    return context;
  }

  @override
  String? getPubkey() {
    return detail!.dmSession.pubkey;
  }

  @override
  List getTags() {
    var pubkey = detail!.dmSession.pubkey;
    List<dynamic> tags = [
      ["p", pubkey]
    ];
    return tags;
  }

  @override
  List getTagsAddedWhenSend() {
    return [];
  }

  @override
  void updateUI() {
    setState(() {});
  }

  @override
  bool isDM() {
    return true;
  }
}
