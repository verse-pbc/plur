import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../consts/base.dart';
import '../generated/l10n.dart';

class EmojiPickerWidget extends StatefulWidget {
  final Function(String) onEmojiPick;

  const EmojiPickerWidget(this.onEmojiPick, {super.key});

  @override
  State<StatefulWidget> createState() {
    return _EmojiPickerWidgetState();
  }
}

class _EmojiPickerWidgetState extends State<EmojiPickerWidget> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final localization = S.of(context);
    var mainColor = themeData.primaryColor;
    var bgColor = themeData.scaffoldBackgroundColor;

    return SizedBox(
      height: 260,
      child: EmojiPicker(
        onEmojiSelected: (Category? category, Emoji emoji) {
          widget.onEmojiPick(emoji.emoji);
        },
        onBackspacePressed: null,
        // textEditingController:
        //     textEditionController, // pass here the same [TextEditingController] that is connected to your input field, usually a [TextFormField]
        config: Config(
          emojiViewConfig: EmojiViewConfig(
            columns: 10,
            emojiSizeMax: 20 * (PlatformUtil.isIOS() ? 1.30 : 1.0),
            backgroundColor: bgColor,
          ),
          categoryViewConfig: CategoryViewConfig(
            tabBarHeight: 40.0,
            tabIndicatorAnimDuration: kTabScrollDuration,
            initCategory: Category.RECENT,
            recentTabBehavior: RecentTabBehavior.RECENT,
            backgroundColor: bgColor,
            indicatorColor: mainColor,
            iconColor: themeData.hintColor,
            iconColorSelected: mainColor,
            backspaceColor: mainColor,
          ),
          bottomActionBarConfig: BottomActionBarConfig(
            enabled: true,
            showBackspaceButton: true,
            showSearchViewButton: true,
            backgroundColor: mainColor,
            buttonColor: mainColor,
            buttonIconColor: Colors.white,
            customBottomActionBar: (Config config, EmojiViewState state,
                VoidCallback showSearchView) {
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                child: Container(
                  color: config.bottomActionBarConfig.backgroundColor,
                  child: Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(left: Base.basePadding),
                        height: 40,
                        child: Icon(
                          Icons.search,
                          color: config.bottomActionBarConfig.buttonIconColor,
                        ),
                      ),
                      Expanded(child: Container()),
                    ],
                  ),
                ),
                onTap: () {
                  showSearchView();
                },
              );
            },
          ),
          searchViewConfig: SearchViewConfig(
            backgroundColor: bgColor,
            hintText: localization.Search,
          ),
        ),
      ),
    );
  }
}
