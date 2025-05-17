import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostrmo/component/user/user_top_widget.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/features/asks_offers/screens/listings_screen.dart';
import 'package:nostrmo/provider/index_provider.dart';
import 'package:nostrmo/router/index/index_pc_drawer_wrapper.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/service/report_service.dart';

import '../../data/user.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/user_provider.dart';
import '../../util/table_mode_util.dart';
import 'account_manager_widget.dart';
import '../../util/theme_util.dart';

/// A drawer widget that displays user information and navigation options.
class IndexDrawerContent extends ConsumerStatefulWidget {
  /// Determines if the drawer should be in compact mode.
  final bool smallMode;

  const IndexDrawerContent({super.key, required this.smallMode});

  @override
  ConsumerState<IndexDrawerContent> createState() => _IndexDrawerContentState();
}

/// The state class for [IndexDrawerContent].
class _IndexDrawerContentState extends ConsumerState<IndexDrawerContent> {
  /// Width of the profile edit button.
  ///
  /// Defaults to 40.
  final double _profileEditBtnWidth = 40;

  /// Determines if the drawer is in read-only mode.
  ///
  /// Defaults to false.
  bool _readOnly = false;

  PackageInfo _packageInfo = PackageInfo(
    appName: '',
    packageName: '',
    version: '',
    buildNumber: '',
    buildSignature: '',
    installerStore: '',
  );

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final scaffoldBackgroundColor = themeData.scaffoldBackgroundColor;
    final userProvider = legacy_provider.Provider.of<UserProvider>(context);
    final indexProvider = legacy_provider.Provider.of<IndexProvider>(context);
    final localization = S.of(context);
    final hintColor = themeData.hintColor;
    final mainColor = themeData.primaryColor;
    final groupProvider = legacy_provider.Provider.of<GroupProvider>(context);
    final reportService = legacy_provider.Provider.of<ReportService>(context);
    var pubkey = nostr!.publicKey;
    var paddingTop = mediaDataCache.padding.top;
    var cardColor = themeData.cardColor;
    
    // List to hold drawer items
    List<Widget> list = [];

    _readOnly = nostr!.isReadOnly();

    // Add user profile picture or metadata display based on smallMode
    if (widget.smallMode) {
      list.add(Container(
        margin: EdgeInsets.only(
          top: Base.basePadding + paddingTop,
          bottom: Base.basePaddingHalf,
        ),
        child: GestureDetector(
          onTap: () {
            RouterUtil.router(context, RouterPath.user, pubkey);
          },
          child: UserPicWidget(pubkey: pubkey, width: 50),
        ),
      ));
    } else {
      list.add(Stack(children: [
        legacy_provider.Selector<UserProvider, User?>(
          builder: (context, user, child) {
            return UserTopWidget(
              pubkey: pubkey,
              user: user,
              isLocal: true,
              jumpable: true,
            );
          },
          selector: (_, provider) {
            return provider.getUser(pubkey);
          },
        ),
        Positioned(
          top: paddingTop + Base.basePaddingHalf,
          right: Base.basePadding,
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
        name: localization.home,
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
    
    // Add the DMs option to the list of drawer items.
    centerList.add(IndexDrawerItemWidget(
      iconData: Icons.chat_rounded,
      name: localization.dms,
      color: indexProvider.currentTap == 1 ? mainColor : null,
      onTap: () {
        indexProvider.setCurrentTap(1);
      },
      smallMode: widget.smallMode,
    ));
    
    // Add the SEARCH option to the list of drawer items.
    centerList.add(IndexDrawerItemWidget(
      iconData: Icons.search_rounded,
      name: localization.search,
      color: indexProvider.currentTap == 2 ? mainColor : null,
      onTap: () {
        indexProvider.setCurrentTap(2);
      },
      smallMode: widget.smallMode,
    ));
    
    // Add the COMMUNITIES option to the list of drawer items.
    centerList.add(IndexDrawerItemWidget(
      iconData: Icons.groups_rounded,
      name: localization.communities,
      color: indexProvider.currentTap == 0 ? mainColor : null,
      onTap: () {
        indexProvider.setCurrentTap(0);
      },
      smallMode: widget.smallMode,
    ));

    // Add Reports Management option only if user is an admin of any group
    if (nostr != null && groupProvider.isAdminOfAnyGroup(nostr!.publicKey)) {
      final reportCount = reportService.getActiveReportCount();
      
      centerList.add(IndexDrawerItemWidget(
        iconData: Icons.admin_panel_settings_rounded,
        name: "Moderation Reports",  // Using string literal until translation is available
        badge: reportCount > 0 ? "$reportCount" : null,
        onTap: () {
          RouterUtil.router(context, RouterPath.reportManagement);
        },
        smallMode: widget.smallMode,
      ));
    }

    // Add the Asks & Offers option to the list of drawer items.
    centerList.add(IndexDrawerItemWidget(
      iconData: Icons.store_mall_directory_rounded,
      name: "Asks & Offers",  // Using string literal until translation is available
      color: indexProvider.currentTap == 3 ? mainColor : null,
      onTap: () {
        // Use a WidgetsBinding.instance.addPostFrameCallback to ensure the widget tree is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Use push directly to ensure we can pass the showAllGroups parameter
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ListingsScreen(
                showAllGroups: true, // Show listings from all groups
              ),
            ),
          );
        });
        
        if (!TableModeUtil.isTableMode()) {
          Navigator.pop(context);
        }
      },
      smallMode: widget.smallMode,
    ));

    // Add the SETTINGS option to the list of drawer items.
    centerList.add(IndexDrawerItemWidget(
      iconData: Icons.settings_rounded,
      name: localization.settings,
      onTap: () {
        RouterUtil.router(context, RouterPath.settings);
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
      name: localization.accountManager,
      onTap: () {
        _showBasicModalBottomSheet(context);
      },
      smallMode: widget.smallMode,
    ));

    if (widget.smallMode) {
      // Add a button to exit small mode.
      list.add(Container(
        margin: const EdgeInsets.only(bottom: Base.basePaddingHalf),
        child: IndexDrawerItemWidget(
          iconData: Icons.last_page_rounded,
          name: "",
          onTap: _toggleSmallMode,
          smallMode: widget.smallMode,
        ),
      ));
    } else {
      // Add the app version.
      final version = _packageInfo.version;
      final versionText = switch (_packageInfo.buildNumber) {
        "" => version,
        var buildNumber => "$version ($buildNumber)",
      };
      Widget versionWidget = Text("${localization.version}: $versionText");
      if (TableModeUtil.isTableMode()) {
        // Add a button to enter small mode.
        List<Widget> subList = [];
        subList.add(GestureDetector(
          onTap: _toggleSmallMode,
          behavior: HitTestBehavior.translucent,
          child: Container(
            margin: const EdgeInsets.only(right: Base.basePadding),
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
        margin: const EdgeInsets.only(top: Base.basePaddingHalf),
        padding: const EdgeInsets.only(
          left: Base.basePadding * 2,
          bottom: Base.basePadding,
          top: Base.basePadding,
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

  /// Fetches package information from the current platform.
  void _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  /// Navigates to the profile edit screen.
  void _jumpToProfileEdit() {
    final user = userProvider.getUser(nostr!.publicKey);
    RouterUtil.router(context, RouterPath.profileEditor, user);
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

  /// Optional badge text for the item.
  final String? badge;

  /// Creates an instance of [IndexDrawerItemWidget].
  ///
  /// The [iconData], [name], and [onTap] parameters are required.
  /// The [smallMode] parameter defaults to `false`.
  const IndexDrawerItemWidget({
    super.key,
    required this.iconData,
    required this.name,
    required this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.color,
    this.smallMode = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final primaryFontColor = themeData.customColors.primaryForegroundColor;
    
    Widget child;
    if (smallMode) {
      child = Container(
        padding: const EdgeInsets.all(Base.basePadding),
        child: Column(
          children: [
            Icon(
              iconData,
              color: color ?? primaryFontColor,
            ),
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: themeData.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      );
    } else {
      child = Container(
        padding: const EdgeInsets.all(Base.basePadding),
        child: Row(
          children: [
            Icon(
              iconData,
              color: color ?? primaryFontColor,
            ),
            const SizedBox(width: Base.basePadding),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: color ?? primaryFontColor,
                  fontSize: 16,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: themeData.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
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
      child: child,
    );
  }
}
