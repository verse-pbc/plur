import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/component/image_widget.dart';
import 'package:nostrmo/component/qrcode_dialog.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/features/asks_offers/screens/listings_screen.dart';
import 'package:nostrmo/provider/index_provider.dart';
import 'package:nostrmo/router/index/index_pc_drawer_wrapper.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart' as legacy_provider;

import '../../data/user.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/user_provider.dart';
import '../../util/table_mode_util.dart';
import 'account_manager_widget.dart';
import '../../theme/app_colors.dart';

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
    var indexProvider = legacy_provider.Provider.of<IndexProvider>(context);

    final localization = S.of(context);
    var pubkey = nostr!.publicKey;
    var paddingTop = mediaDataCache.padding.top;
    final appColors = Theme.of(context).extension<AppColors>()!;
    final loginBackground = appColors.loginBackground;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Use white for text in dark mode, primary text in light mode
    final primaryTextColor = isDarkMode ? Colors.white : appColors.primaryText;
    var mainColor = primaryTextColor; // Using appropriate text color for the theme
    List<Widget> list = [];

    _readOnly = nostr!.isReadOnly();

    // Create sideMenuHeader container with gradient background
    Widget sideMenuHeader;
    
    if (widget.smallMode) {
      sideMenuHeader = Container(
        margin: EdgeInsets.only(
          top: 24 + paddingTop, // 24pt separation from top
          left: 24, // 24pt separation from left
          right: 24, // 24pt separation from right
          bottom: Base.basePaddingHalf,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF9ECCC3), // Light tealish color
              Color(0xFFB8D0CE), // Silver-ish color
            ],
          ),
          borderRadius: BorderRadius.circular(8), // 8pt rounded corners
        ),
        child: GestureDetector(
          onTap: () {
            RouterUtil.router(context, RouterPath.user, pubkey);
          },
          child: UserPicWidget(pubkey: pubkey, width: 50),
        ),
      );
    } else {
      sideMenuHeader = Container(
        margin: EdgeInsets.only(
          top: 24 + paddingTop,
          left: 24,
          right: 24,
          bottom: Base.basePaddingHalf,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF9ECCC3),
              Color(0xFFB8D0CE),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Cover photo with 16:9 aspect ratio and avatar
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  legacy_provider.Selector<UserProvider, User?>(
                    builder: (context, user, child) {
                      String? bannerUrl = user?.banner;
                      
                      return ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                              ),
                              child: bannerUrl != null && bannerUrl.isNotEmpty
                                ? ImageWidget(
                                    url: bannerUrl,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                                    child: Icon(
                                      Icons.landscape,
                                      size: 48,
                                      color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                                    ),
                                  ),
                            ),
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF29525e),
                                    Color(0xFF508e8d),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    selector: (_, provider) {
                      return provider.getUser(pubkey);
                    },
                  ),
                  // Avatar positioned at the bottom of the cover photo
                  legacy_provider.Selector<UserProvider, User?>(
                    builder: (context, user, child) {
                      const avatarSize = 80.0;
                      const avatarPadding = Base.basePadding;
                      
                      return Positioned(
                        left: avatarPadding,
                        bottom: avatarPadding,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF2B2B2B),
                              width: 5,
                            ),
                          ),
                          child: UserPicWidget(
                            pubkey: pubkey,
                            width: avatarSize,
                            user: user,
                          ),
                        ),
                      );
                    },
                    selector: (_, provider) {
                      return provider.getUser(pubkey);
                    },
                  ),
                ],
              ),
            ),
            // User info section
            Padding(
              padding: const EdgeInsets.only(
                left: Base.basePadding,
                right: Base.basePadding,
                bottom: Base.basePadding,
                top: Base.basePadding,
              ),
              child: legacy_provider.Selector<UserProvider, User?>(
                builder: (context, user, child) {
                  return _buildUserInfoWidget(context, user, pubkey);
                },
                selector: (_, provider) {
                  return provider.getUser(pubkey);
                },
              ),
            ),
          ],
        ),
      );
    }
    
    list.add(sideMenuHeader);

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
      Widget versionWidget = Text(
        "${localization.version}: $versionText",
        style: TextStyle(
          color: mainColor,
          fontSize: 14,
        ),
      );
      if (TableModeUtil.isTableMode()) {
        // Add a button to enter small mode.
        List<Widget> subList = [];
        subList.add(GestureDetector(
          onTap: _toggleSmallMode,
          behavior: HitTestBehavior.translucent,
          child: Container(
            margin: const EdgeInsets.only(right: Base.basePadding),
            child: Icon(
              Icons.first_page_rounded,
              color: mainColor,
            ),
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
          border: Border(
            top: BorderSide(
              width: 1,
              color: mainColor.withValues(alpha: 0.2),
            ),
          ),
        ),
        alignment: Alignment.centerLeft,
        child: versionWidget,
      ));
    }

    return Container(
      color: loginBackground,
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
  void _showBasicModalBottomSheet(BuildContext context) async {
    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withAlpha((255 * 0.5).round()),
        enableDrag: true,
        isDismissible: true,
        builder: (BuildContext context) {
          // Get responsive width values
          var screenWidth = MediaQuery.of(context).size.width;
          bool isTablet = screenWidth >= 600;
          bool isDesktop = screenWidth >= 900;
          double sheetMaxWidth = isDesktop ? 600 : (isTablet ? 600 : double.infinity);
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Container(
                  color: Colors.transparent,
                  height: 100,  // Touch area above sheet
                ),
              ),
              AnimatedPadding(
                padding: MediaQuery.of(context).viewInsets,
                duration: const Duration(milliseconds: 100),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: sheetMaxWidth),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).extension<AppColors>()?.loginBackground,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: const SafeArea(
                        top: false,
                        bottom: true,
                        child: AccountManagerWidget(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Handle the error gracefully
    }
  }

  /// Toggles between compact and expanded drawer modes.
  void _toggleSmallMode() {
    var callback = IndexPcDrawerWrapperCallback.of(context);
    if (callback != null) {
      callback.toggle();
    }
  }

  /// Builds a custom user info widget without the banner
  Widget _buildUserInfoWidget(BuildContext context, User? user, String pubkey) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    String displayName = "";
    
    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        displayName = user.displayName!;
      } else if (user.name != null && user.name!.isNotEmpty) {
        displayName = user.name!;
      }
    }
    
    if (displayName.isEmpty) {
      displayName = Nip19.encodeSimplePubKey(pubkey);
    }
    
    String nip19PubKey = Nip19.encodePubKey(pubkey);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Name section
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add small space at top
              const SizedBox(height: 8),
              Text(
                displayName,
                style: TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Base.basePadding),
              // Public key - full width
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF464646),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  nip19PubKey,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                    fontFamily: 'SF Pro Text',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: Base.basePadding),
              // Button row
              Row(
                children: [
                  // Edit profile button - expanded
                  if (!_readOnly)
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextButton(
                          onPressed: _jumpToProfileEdit,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          child: const Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (!_readOnly)
                    const SizedBox(width: 12),
                  // QR Scanner button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF464646),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        // TODO: Handle QR scanner navigation
                      },
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // QR Code button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF464646),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.qr_code_2,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        QrcodeDialog.show(context, pubkey);
                      },
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
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
    final appColors = Theme.of(context).extension<AppColors>()!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : appColors.primaryText;
    
    // Use color parameter if provided, otherwise use appropriate text color
    final itemColor = color ?? primaryTextColor;
    
    // The icon widget
    Widget iconWidget = Icon(
      iconData,
      color: itemColor,
    );

    Widget mainWidget;
    if (smallMode) {
      // Compact mode: Only the icon is displayed with minimal padding.
      mainWidget = Container(
        decoration: BoxDecoration(
          color: color != null ? Colors.white.withAlpha(26) : null,
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
                left: Base.basePadding * 2,
                right: Base.basePadding,
              ),
              child: iconWidget,
            ),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: itemColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
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
