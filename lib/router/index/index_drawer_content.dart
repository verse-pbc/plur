import 'package:flutter/material.dart';
import 'package:nostrmo/component/user/metadata_top_widget.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/provider/index_provider.dart';
import 'package:nostrmo/router/index/index_pc_drawer_wrapper.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../../data/metadata.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/metadata_provider.dart';
import '../../util/table_mode_util.dart';
import 'account_manager_widget.dart';
import '../../util/theme_util.dart';

/// A drawer widget that displays user information and navigation options.
class IndexDrawerContent extends StatefulWidget {
  /// Determines if the drawer should be in compact mode.
  final bool smallMode;

  const IndexDrawerContent({super.key, required this.smallMode});

  @override
  State<StatefulWidget> createState() => _IndexDrawerContentState();
}

/// The state class for [IndexDrawerContent].
class _IndexDrawerContentState extends State<IndexDrawerContent> {
  /// Width of the profile edit button.
  ///
  /// Defaults to 40.
  final double _profileEditBtnWidth = 40;

  /// Determines if the drawer is in read-only mode.
  ///
  /// Defaults to false.
  bool _readOnly = false;

  @override
  Widget build(BuildContext context) {
    var indexProvider = Provider.of<IndexProvider>(context);

    final localization = S.of(context);
    var pubkey = nostr!.publicKey;
    var paddingTop = mediaDataCache.padding.top;
    final themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var cardColor = themeData.cardColor;
    var hintColor = themeData.hintColor;
    List<Widget> list = [];
    _readOnly = nostr!.isReadOnly();

    // Add user profile picture or metadata display based on smallMode
    if (widget.smallMode) {
      list.add(Container(
        margin: EdgeInsets.only(
          top: Base.BASE_PADDING + paddingTop,
          bottom: Base.BASE_PADDING_HALF,
        ),
        child: GestureDetector(
          onTap: () {
            RouterUtil.router(context, RouterPath.USER, pubkey);
          },
          child: UserPicWidget(pubkey: pubkey, width: 50),
        ),
      ));
    } else {
      list.add(Stack(children: [
        Selector<MetadataProvider, Metadata?>(
          builder: (context, metadata, child) {
            return MetadataTopWidget(
              pubkey: pubkey,
              metadata: metadata,
              isLocal: true,
              jumpable: true,
            );
          },
          selector: (_, provider) {
            return provider.getMetadata(pubkey);
          },
        ),
        Positioned(
          top: paddingTop + Base.BASE_PADDING_HALF,
          right: Base.BASE_PADDING,
          child: _readOnly
              ? Container()
              : Container(
                  height: _profileEditBtnWidth,
                  width: _profileEditBtnWidth,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(
                      _profileEditBtnWidth / 2,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit_square),
                    onPressed: _jumpToProfileEdit,
                  ),
                ),
        ),
      ]));
    }

    List<Widget> centerList = [];

    // Add the HOME option to the list of drawer items.
    if (TableModeUtil.isTableMode()) {
      centerList.add(IndexDrawerItemWidget(
        iconData: Icons.home_rounded,
        name: localization.Home,
        color: indexProvider.currentTap == 0 ? mainColor : null,
        onTap: () {
          indexProvider.setCurrentTap(0);
        },
        onDoubleTap: () {
          indexProvider.followScrollToTop();
        },
        smallMode: widget.smallMode,
      ));
    }

    // Add the SETTINGS option to the list of drawer items.
    centerList.add(IndexDrawerItemWidget(
      iconData: Icons.settings_rounded,
      name: localization.Settings,
      onTap: () {
        RouterUtil.router(context, RouterPath.SETTINGS);
      },
      smallMode: widget.smallMode,
    ));

    list.add(Expanded(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: centerList,
        ),
      ),
    ));

    // Add the Account Manager widget.
    list.add(IndexDrawerItemWidget(
      iconData: Icons.account_box_rounded,
      name: localization.Account_Manager,
      onTap: () {
        _showBasicModalBottomSheet(context);
      },
      smallMode: widget.smallMode,
    ));

    if (widget.smallMode) {
      // Add a button to exit small mode.
      list.add(Container(
        margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
        child: IndexDrawerItemWidget(
          iconData: Icons.last_page_rounded,
          name: "",
          onTap: _toggleSmallMode,
          smallMode: widget.smallMode,
        ),
      ));
    } else {
      // Add the app version.
      Widget versionWidget = Text("V ${Base.VERSION_NAME}");
      if (TableModeUtil.isTableMode()) {
        // Add a button to enter small mode.
        List<Widget> subList = [];
        subList.add(GestureDetector(
          onTap: _toggleSmallMode,
          behavior: HitTestBehavior.translucent,
          child: Container(
            margin: const EdgeInsets.only(right: Base.BASE_PADDING),
            child: const Icon(Icons.first_page_rounded),
          ),
        ));
        // Place the app version at the right side.
        subList.add(versionWidget);
        versionWidget = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: subList,
        );
      }
      list.add(Container(
        margin: const EdgeInsets.only(top: Base.BASE_PADDING_HALF),
        padding: const EdgeInsets.only(
          left: Base.BASE_PADDING * 2,
          bottom: Base.BASE_PADDING,
          top: Base.BASE_PADDING,
        ),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(width: 1, color: hintColor)),
        ),
        alignment: Alignment.centerLeft,
        child: versionWidget,
      ));
    }

    return Container(
      color: themeData.cardColor,
      margin:
          TableModeUtil.isTableMode() ? const EdgeInsets.only(right: 1) : null,
      child: Column(
        children: list,
      ),
    );
  }

  /// Navigates to the profile edit screen.
  void _jumpToProfileEdit() {
    var metadata = metadataProvider.getMetadata(nostr!.publicKey);
    RouterUtil.router(context, RouterPath.PROFILE_EDITOR, metadata);
  }

  /// Displays the account manager modal bottom sheet.
  void _showBasicModalBottomSheet(context) async {
    final theme = Theme.of(context);
    showModalBottomSheet(
      isScrollControlled: false,
      backgroundColor: theme.customColors.feedBgColor,
      context: context,
      builder: (BuildContext context) {
        return const AccountManagerWidget();
      },
    );
  }

  /// Toggles between compact and expanded drawer modes.
  void _toggleSmallMode() {
    var callback = IndexPcDrawerWrapperCallback.of(context);
    if (callback != null) {
      callback.toggle();
    }
  }
}

/// A widget representing an item inside the navigation drawer.
class IndexDrawerItemWidget extends StatelessWidget {
  /// The icon to be displayed in the item.
  final IconData iconData;

  /// The label text for the item.
  final String name;

  /// Callback function when the item is tapped.
  final Function onTap;

  /// Optional callback function when the item is double-tapped.
  final Function? onDoubleTap;

  /// Optional callback function when the item is long-pressed.
  final Function? onLongPress;

  /// Optional color for the icon and text.
  final Color? color;

  /// Indicates if the widget is being displayed in a compact mode.
  final bool smallMode;

  /// Creates an instance of [IndexDrawerItemWidget].
  ///
  /// The [iconData], [name], and [onTap] parameters are required.
  /// The [smallMode] parameter defaults to `false`.
  const IndexDrawerItemWidget({
    super.key,
    required this.iconData,
    required this.name,
    required this.onTap,
    this.color,
    this.onDoubleTap,
    this.onLongPress,
    this.smallMode = false,
  });

  @override
  Widget build(BuildContext context) {
    // The icon widget
    Widget iconWidget = Icon(
      iconData,
      color: color,
    );

    Widget mainWidget;
    if (smallMode) {
      // Compact mode: Only the icon is displayed with minimal padding.
      mainWidget = Container(
        decoration: BoxDecoration(
          color: color != null ? Colors.white.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(bottom: 2),
        child: iconWidget,
      );
    } else {
      // Normal mode: Display icon alongside text.
      mainWidget = SizedBox(
        height: 34,
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(
                left: Base.BASE_PADDING * 2,
                right: Base.BASE_PADDING,
              ),
              child: iconWidget,
            ),
            Expanded(
              child: Text(
                name,
                style: TextStyle(color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        onTap();
      },
      onDoubleTap: () {
        if (onDoubleTap != null) {
          onDoubleTap!();
        }
      },
      onLongPress: () {
        if (onLongPress != null) {
          onLongPress!();
        }
      },
      behavior: HitTestBehavior.translucent,
      child: mainWidget,
    );
  }
}
