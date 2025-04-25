import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/user/name_widget.dart';
import 'package:nostrmo/component/point_widget.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/data/group_identifier_repository.dart';
import 'package:nostrmo/data/user.dart';
import 'package:nostrmo/provider/user_provider.dart';
import 'package:nostrmo/provider/settings_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/notification_util.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../consts/base.dart';
import '../../data/dm_session_info_db.dart';
import '../../data/event_db.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import 'index_drawer_content.dart';

class AccountManagerWidget extends ConsumerStatefulWidget {
  const AccountManagerWidget({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return AccountManagerWidgetState();
  }
}

class AccountManagerWidgetState extends ConsumerState<AccountManagerWidget> {
  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    final settingsProvider =
        legacy_provider.Provider.of<SettingsProvider>(context);
    var privateKeyMap = settingsProvider.privateKeyMap;

    final themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var btnTextColor = themeData.textTheme.bodyMedium!.color;

    List<Widget> list = [];
    list.add(Container(
      padding: const EdgeInsets.only(
        top: Base.basePaddingHalf,
        bottom: Base.basePaddingHalf,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: hintColor,
          ),
        ),
      ),
      child: IndexDrawerItemWidget(
        iconData: Icons.account_box,
        name: localization.Account_Manager,
        onTap: () {},
      ),
    ));

    privateKeyMap.forEach((key, value) {
      var index = int.tryParse(key);
      if (index == null) {
        log("parse index key error");
        return;
      }
      list.add(AccountManagerItemWidget(
        index: index,
        accountKey: value,
        isCurrent: settingsProvider.privateKeyIndex == index,
        onLoginTap: onLoginTap,
        onLogoutTap: (index) {
          onLogoutTap(index, ref, context: context);
        },
      ));
    });

    list.add(Container(
      margin: const EdgeInsets.only(
        top: Base.basePaddingHalf,
        bottom: Base.basePaddingHalf,
      ),
      padding: const EdgeInsets.only(
        left: Base.basePadding * 2,
        right: Base.basePadding * 2,
      ),
      width: double.maxFinite,
      child: TextButton(
        onPressed: addAccount,
        style: TextButton.styleFrom(
          side: BorderSide(width: 1, color: hintColor.withOpacity(0.4)),
        ),
        child: Text(
          localization.Add_Account,
          style: TextStyle(color: btnTextColor),
        ),
      ),
    ));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: list,
    );
  }

  Future<void> addAccount() async {
    RouterUtil.back(context);
    await RouterUtil.router(context, RouterPath.welcome, true);
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
          BotToast.showText(text: S.of(context).Wrong_Private_Key_format);
          return false;
        }
      }
    }

    return true;
  }

  Future<void> doLogin() async {
    nostr = await relayProvider.genNostrWithKey(settingsProvider.privateKey!);
    ref.invalidate(groupIdentifierRepositoryProvider);
  }

  Future<void> onLoginTap(int index) async {
    if (settingsProvider.privateKeyIndex != index) {
      // Deregister push notifications for current account before switching
      if (nostr != null) {
        await NotificationUtil.deregisterUserFromPushNotifications(nostr!);
      }

      clearCurrentMemInfo(ref);
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

  static Future<void> onLogoutTap(int index, WidgetRef ref,
      {bool routerBack = true, BuildContext? context}) async {
    var oldIndex = settingsProvider.privateKeyIndex;

    // Deregister push notifications before clearing data
    if (oldIndex == index && nostr != null) {
      await NotificationUtil.deregisterUserFromPushNotifications(nostr!);
    }

    clearLocalData(index);

    if (oldIndex == index) {
      clearCurrentMemInfo(ref);
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

  static void clearCurrentMemInfo(WidgetRef ref) {
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

    if (nostr != null) {
      nostr!.close();
      nostr = null;
    }

    // Remove the current private key
    if (settingsProvider.privateKeyIndex != null) {
      settingsProvider.removeKey(settingsProvider.privateKeyIndex!);
    }
    ref.read(groupIdentifierRepositoryProvider).clear();

    // Navigate to welcome screen only if no accounts left
    if (settingsProvider.privateKeyMap.isEmpty) {
      final context = MyApp.navigatorKey.currentContext;
      if (context != null) {
        RouterUtil.router(context, RouterPath.welcome);
      }
    }
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
  static const double imageWidth = 26;

  static const double lineHeight = 44;

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
          Sentry.captureException(exception, stackTrace: stackTrace);
        });
      }
      loginTag = "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    Color? cardColor = themeData.cardColor;
    if (cardColor == Colors.white) {
      cardColor = Colors.grey[300];
    }
    final localization = S.of(context);

    return legacy_provider.Selector<UserProvider, User?>(
        builder: (context, user, child) {
      Color currentColor = Colors.green;
      List<Widget> list = [];

      var nip19PubKey = Nip19.encodePubKey(pubkey);

      list.add(Container(
        width: 24,
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 15,
          child: widget.isCurrent
              ? PointWidget(
                  width: 15,
                  color: currentColor,
                )
              : null,
        ),
      ));

      list.add(UserPicWidget(
        pubkey: pubkey,
        width: imageWidth,
        user: user,
      ));

      list.add(Container(
        margin: const EdgeInsets.only(left: 5, right: 5),
        width: 120,
        child: NameWidget(
          pubkey: pubkey,
          user: user,
          maxLines: 1,
          textOverflow: TextOverflow.ellipsis,
        ),
      ));

      if (StringUtil.isNotBlank(loginTag)) {
        list.add(Container(
          margin: const EdgeInsets.only(right: Base.basePaddingHalf),
          padding: const EdgeInsets.only(
            left: Base.basePaddingHalf,
            right: Base.basePaddingHalf,
            top: 4,
            bottom: 4,
          ),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            loginTag == "ReadOnly" ? localization.Read_Only : loginTag!,
          ),
        ));
      }

      list.add(Expanded(
          child: Container(
        padding: const EdgeInsets.only(
          left: Base.basePaddingHalf,
          right: Base.basePaddingHalf,
          top: 4,
          bottom: 4,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          nip19PubKey,
          overflow: TextOverflow.ellipsis,
        ),
      )));

      list.add(GestureDetector(
        onTap: onLogout,
        child: Container(
          padding: const EdgeInsets.only(left: 5),
          height: lineHeight,
          child: const Icon(Icons.logout),
        ),
      ));

      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent,
        child: Container(
          height: lineHeight,
          width: double.maxFinite,
          padding: const EdgeInsets.only(
            left: Base.basePadding * 2,
            right: Base.basePadding * 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: list,
          ),
        ),
      );
    }, selector: (_, provider) {
      return provider.getUser(pubkey);
    });
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
