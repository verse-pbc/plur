import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/user/name_widget.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/data/user.dart';
import 'package:nostrmo/provider/user_provider.dart';
import 'package:nostrmo/provider/settings_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';
// Sentry has been removed

import '../../data/dm_session_info_db.dart';
import '../../data/event_db.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../theme/app_colors.dart';

class AccountManagerWidget extends StatefulWidget {
  const AccountManagerWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return AccountManagerWidgetState();
  }
}

class AccountManagerWidgetState extends State<AccountManagerWidget> {
  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    var privateKeyMap = settingsProvider.privateKeyMap;

    final themeData = Theme.of(context);
    final appColors = themeData.extension<AppColors>();
    var buttonTextColor = appColors?.buttonText ?? themeData.textTheme.bodyMedium!.color!;
    var secondaryTextColor = appColors?.secondaryText ?? themeData.hintColor;

    // Get screen width for responsive design
    var screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = screenWidth >= 900;

    // Wrapper function for responsive elements
    Widget wrapResponsive(Widget child) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 400 : 500),
          child: child,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close button
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: buttonTextColor.withAlpha((255 * 0.1).round()),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: buttonTextColor,
                  size: 20,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Account icon above title
          Center(
            child: Image.asset(
              'assets/imgs/profile.png',
              width: 80,
              height: 80,
              // No color tinting to show the original image
              errorBuilder: (context, error, stackTrace) {
                // Fallback icon if image fails to load
                return Icon(
                  Icons.account_circle,
                  size: 80,
                  color: buttonTextColor,
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Title
          wrapResponsive(
            Center(
              child: Text(
                localization.accountManager,
                style: TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  color: buttonTextColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Account list
          wrapResponsive(
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: privateKeyMap.length,
                itemBuilder: (context, i) {
                  var entries = privateKeyMap.entries.toList();
                  var entry = entries[i];
                  var index = int.tryParse(entry.key);
                  if (index == null) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AccountManagerItemWidget(
                      index: index,
                      accountKey: entry.value,
                      isCurrent: settingsProvider.privateKeyIndex == index,
                      onLoginTap: onLoginTap,
                      onLogoutTap: (index) {
                        onLogoutTap(index, context: context);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Add account button
          wrapResponsive(
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: addAccount,
                style: TextButton.styleFrom(
                  side: BorderSide(
                    width: 2,
                    color: secondaryTextColor.withAlpha((255 * 0.3).round()),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: Text(
                  localization.addAccount,
                  style: TextStyle(
                    fontFamily: 'SF Pro Rounded',
                    color: buttonTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
          
          // Logout button for current account
          if (settingsProvider.privateKeyIndex != null && privateKeyMap.isNotEmpty) ...[
            const SizedBox(height: 16),
            wrapResponsive(
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => onLogoutTap(settingsProvider.privateKeyIndex!, context: context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(width: 2, color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Text(
                    "Log Out",
                    style: TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> addAccount() async {
    RouterUtil.back(context);
    await RouterUtil.router(context, RouterPath.login, true);
    settingsProvider.notify();
  }

  bool addAccountCheck(BuildContext p1, String privateKey) {
    if (StringUtil.isNotBlank(privateKey)) {
      if (Nip19.isPubkey(privateKey) || privateKey.indexOf("@") > 0) {
      } else if (NostrRemoteSignerInfo.isBunkerUrl(privateKey)) {
      } else {
        if (Nip19.isPrivateKey(privateKey)) {
          privateKey = Nip19.decode(privateKey);
        }

        // try to gen publicKey check the formate
        try {
          getPublicKey(privateKey);
        } catch (e) {
          BotToast.showText(text: S.of(context).wrongPrivateKeyFormat);
          return false;
        }
      }
    }

    return true;
  }

  Future<void> doLogin() async {
    nostr = await relayProvider.genNostrWithKey(settingsProvider.privateKey!);
  }

  Future<void> onLoginTap(int index) async {
    if (settingsProvider.privateKeyIndex != index) {
      clearCurrentMemInfo();
      nostr!.close();
      nostr = null;

      settingsProvider.privateKeyIndex = index;

      // signOut complete
      if (settingsProvider.privateKey != null) {
        // use next privateKey to login
        var cancelFunc = BotToast.showLoading();
        try {
          await doLogin();
        } finally {
          cancelFunc.call();
        }
        settingsProvider.notify();

        if (!mounted) return;
        RouterUtil.back(context);
      }
    }
  }

  static Future<void> onLogoutTap(int index,
      {bool routerBack = true, BuildContext? context}) async {
    var oldIndex = settingsProvider.privateKeyIndex;
    clearLocalData(index);

    if (oldIndex == index) {
      clearCurrentMemInfo();
      nostr!.close();
      nostr = null;

      // signOut complete
      if (settingsProvider.privateKey != null) {
        // use next privateKey to login
        nostr =
            await relayProvider.genNostrWithKey(settingsProvider.privateKey!);
      }
    }

    settingsProvider.notify();
    if (routerBack && context != null && context.mounted) {
      RouterUtil.back(context);
    }
  }

  static void clearCurrentMemInfo() {
    mentionMeProvider.clear();
    mentionMeNewProvider.clear();
    followEventProvider.clear();
    followNewEventProvider.clear();
    dmProvider.clear();
    noticeProvider.clear();
    contactListProvider.clear();

    eventReactionsProvider.clear();
    linkPreviewDataProvider.clear();
    relayProvider.clear();
    listProvider.clear();
  }

  static void clearLocalData(int index) {
    // remove private key
    settingsProvider.removeKey(index);
    // clear local db
    DMSessionInfoDB.deleteAll(index);
    EventDB.deleteAll(index);
  }
}

class AccountManagerItemWidget extends StatefulWidget {
  final bool isCurrent;

  final int index;

  final String accountKey;

  final Function(int)? onLoginTap;

  final Function(int)? onLogoutTap;

  const AccountManagerItemWidget({
    super.key,
    required this.isCurrent,
    required this.index,
    required this.accountKey,
    this.onLoginTap,
    this.onLogoutTap,
  });

  @override
  State<StatefulWidget> createState() {
    return _AccountManagerItemWidgetState();
  }
}

class _AccountManagerItemWidgetState extends State<AccountManagerItemWidget> {

  String pubkey = "";

  String? loginTag;

  @override
  void initState() {
    super.initState();
    if (Nip19.isPubkey(widget.accountKey)) {
      pubkey = Nip19.decode(widget.accountKey);
      loginTag = "ReadOnly";
    } else if (AndroidNostrSigner.isAndroidNostrSignerKey(widget.accountKey)) {
      pubkey = AndroidNostrSigner.getPubkeyFromKey(widget.accountKey);
      loginTag = "NIP-55";
    } else if (NIP07Signer.isWebNostrSignerKey(widget.accountKey)) {
      pubkey = NIP07Signer.getPubkey(widget.accountKey);
      loginTag = "NIP-07";
    } else if (NostrRemoteSignerInfo.isBunkerUrl(widget.accountKey)) {
      var info = NostrRemoteSignerInfo.parseBunkerUrl(widget.accountKey);
      if (info != null) {
        if (StringUtil.isNotBlank(info.userPubkey)) {
          pubkey = info.userPubkey!;
        } else {
          pubkey = info.remoteSignerPubkey;
        }
      }
      loginTag = "NIP-46";
    } else {
      try {
        pubkey = getPublicKey(widget.accountKey);
      } catch (exception, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          log("Account manager exception: $exception\n$stackTrace");
        });
      }
      loginTag = "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final appColors = themeData.extension<AppColors>();
    var buttonTextColor = appColors?.buttonText ?? themeData.textTheme.bodyMedium!.color!;
    var secondaryTextColor = appColors?.secondaryText ?? themeData.hintColor;
    final localization = S.of(context);

    return Selector<UserProvider, User?>(
      builder: (context, user, child) {
        Color currentColor = Colors.green;
        Color badgeColor = secondaryTextColor.withAlpha((255 * 0.15).round());
        
        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.translucent,
          child: Container(
            decoration: BoxDecoration(
              color: widget.isCurrent 
                  ? appColors?.accent.withAlpha((255 * 0.1).round()) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isCurrent 
                    ? appColors?.accent ?? currentColor
                    : Colors.transparent,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // User avatar
                UserPicWidget(
                  pubkey: pubkey,
                  width: 40,
                  user: user,
                ),
                
                const SizedBox(width: 12),
                
                // Name
                Expanded(
                  child: NameWidget(
                    pubkey: pubkey,
                    user: user,
                  ),
                ),
                
                // Auth type badge
                if (StringUtil.isNotBlank(loginTag))
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      loginTag == "ReadOnly" ? localization.readOnly : loginTag!,
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                
                // Current indicator
                if (widget.isCurrent)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.check_circle,
                      color: appColors?.accent ?? currentColor,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      selector: (_, provider) {
        return provider.getUser(pubkey);
      },
    );
  }

  void onLogout() {
    if (widget.onLogoutTap != null) {
      widget.onLogoutTap!(widget.index);
    }
  }

  void onTap() {
    if (widget.onLoginTap != null) {
      widget.onLoginTap!(widget.index);
    }
  }
}
