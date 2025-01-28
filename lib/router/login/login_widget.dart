import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/android_plugin/android_plugin.dart';
import 'package:nostr_sdk/client_utils/keys.dart';
import 'package:nostr_sdk/nip05/nip05_validor.dart';
import 'package:nostr_sdk/nip07/nip07_signer.dart';
import 'package:nostr_sdk/nip19/nip19.dart';
import 'package:nostr_sdk/nip46/nostr_remote_signer_info.dart';
import 'package:nostr_sdk/nip55/android_nostr_signer.dart';
import 'package:nostr_sdk/signer/pubkey_only_nostr_signer.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostrmo/component/webview_widget.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:styled_text/styled_text.dart';

import '../../consts/base.dart';
import '../../consts/colors.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import 'package:nostr_sdk/utils/string_util.dart';

import '../../util/table_mode_util.dart';
import '../index/account_manager_widget.dart';

class LoginSignupWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _LoginSignupState();
  }
}

class _LoginSignupState extends State<LoginSignupWidget>
    with SingleTickerProviderStateMixin {
  bool obscureText = true;

  TextEditingController controller = TextEditingController();

  bool existAndroidNostrSigner = false;

  bool existWebNostrSigner = false;

  @override
  void initState() {
    super.initState();
    if (PlatformUtil.isAndroid()) {
      AndroidPlugin.existAndroidNostrSigner().then((exist) {
        if (exist == true) {
          setState(() {
            existAndroidNostrSigner = true;
          });
        }
      });
    } else if (PlatformUtil.isWeb()) {
      if (NIP07Signer.support()) {
        setState(() {
          existWebNostrSigner = true;
        });
      }
    }
  }

  bool backAfterLogin = false;

  late S localization;

  @override
  Widget build(BuildContext context) {
    localization = S.of(context);
    final themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var maxWidth = mediaDataCache.size.width;
    var mainWidth = maxWidth * 0.8;
    if (TableModeUtil.isTableMode()) {
      if (mainWidth > 550) {
        mainWidth = 550;
      }
    }

    var logoWiget = Image.asset(
      "assets/imgs/logo/logo512.png",
      width: 100,
      height: 100
    );

    var arg = RouterUtil.routerArgs(context);
    if (arg != null && arg is bool) {
      backAfterLogin = arg;
    }

    List<Widget> mainList = [];

    mainList.add(Expanded(child: Container()));
    
    mainList.add(Container(child: logoWiget));
    
    mainList.add(Container(
      margin: const EdgeInsets.only(
        top: Base.BASE_PADDING,
        bottom: 40,
      ),
      child: const Text(
        "Communities",
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));

    mainList.add(Container(
      margin: const EdgeInsets.symmetric(horizontal: Base.BASE_PADDING * 2),
      child: InkWell(
        onTap: generatePK,
        child: Container(
          height: 36,
          color: ColorList.accent,
          alignment: Alignment.center,
          child: Text(
            localization.Signup,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ));

    mainList.add(Expanded(child: Container()));

    var suffixIcon = GestureDetector(
      onTap: () {
        setState(() {
          obscureText = !obscureText;
        });
      },
      child: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
    );
    mainList.add(Container(
        margin: const EdgeInsets.symmetric(horizontal: Base.BASE_PADDING * 2),
        child: TextField(
            controller: controller,
            decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: localization.Your_private_key,
                fillColor: Colors.white,
                suffixIcon: suffixIcon,
            ),
            obscureText: obscureText,
    )));

    mainList.add(Container(
      margin: const EdgeInsets.all(Base.BASE_PADDING * 2),
      child: InkWell(
        onTap: doLogin,
        child: Container(
          height: 36,
          color: mainColor,
          alignment: Alignment.center,
          child: Text(
            localization.Login,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ));

    if (PlatformUtil.isAndroid() && existAndroidNostrSigner) {
      mainList.add(Text(localization.or));

      mainList.add(Container(
        margin: const EdgeInsets.all(Base.BASE_PADDING * 2),
        child: InkWell(
          onTap: loginByAndroidSigner,
          child: Container(
            height: 36,
            color: mainColor,
            alignment: Alignment.center,
            child: Text(
              localization.Login_With_Android_Signer,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ));
    } else if (PlatformUtil.isWeb() && existWebNostrSigner) {
      mainList.add(Text(localization.or));

      mainList.add(Container(
        margin: const EdgeInsets.all(Base.BASE_PADDING * 2),
        child: InkWell(
          onTap: loginWithWebSigner,
          child: Container(
            height: 36,
            color: mainColor,
            alignment: Alignment.center,
            child: Text(
              localization.Login_With_NIP07_Extension,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ));
    }
    mainList.add(Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [GestureDetector(
          onTap: () {
            WebViewWidget.open(context, Base.PRIVACY_LINK);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: Base.BASE_PADDING * 2),
            child: StyledText(
              text: localization.Accept_terms_of_service,
              textAlign: TextAlign.center,
              tags: {
                'accent': StyledTextTag(
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.red,
                    color: Colors.red
                  )
                )
              }
            ),
          )
        )]
      )
    ));

    return Scaffold(
      body: SizedBox(
        width: double.maxFinite,
        height: double.maxFinite,
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            SizedBox(
              width: mainWidth,
              // color: Colors.red,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: mainList,
              ),
            )
          ],
        ),
      ),
    );
  }

  void generatePK() {
    var pk = generatePrivateKey();
    controller.text = pk;

    // mark newUser and will show follow suggest after login.
    newUser = true;
    BotToast.showText(text: "A new private key has been generated for your account.");
  }

  Future<void> doLogin() async {
    var pk = controller.text;
    if (StringUtil.isBlank(pk)) {
      BotToast.showText(text: S.of(context).Input_can_not_be_null);
      return;
    }

    if (Nip19.isPubkey(pk) || pk.indexOf("@") > 0) {
      String? pubkey;
      if (Nip19.isPubkey(pk)) {
        pubkey = Nip19.decode(pk);
      } else if (pk.indexOf("@") > 0) {
        // try to find pubkey first.
        var cancelFunc = BotToast.showLoading();
        try {
          pubkey = await Nip05Validor.getPubkey(pk);
        } catch (e) {
          print("doLogin error ${e.toString()}");
        } finally {
          cancelFunc.call();
        }
      }

      if (StringUtil.isBlank(pubkey)) {
        BotToast.showText(text: "${localization.Pubkey} ${localization.not_found}");
        return;
      }

      doPreLogin();

      var npubKey = Nip19.encodePubKey(pubkey!);
      settingProvider.addAndChangePrivateKey(npubKey, updateUI: false);

      var pubkeyOnlySigner = PubkeyOnlyNostrSigner(pubkey);
      nostr = await relayProvider.genNostr(pubkeyOnlySigner);
      BotToast.showText(text: localization.Readonly_login_tip);
    } else if (NostrRemoteSignerInfo.isBunkerUrl(pk)) {
      var cancel = BotToast.showLoading();
      try {
        var info = NostrRemoteSignerInfo.parseBunkerUrl(pk);
        if (info == null) {
          return;
        }

        var bunkerLink = info.toString();
        settingProvider.addAndChangePrivateKey(bunkerLink, updateUI: false);

        nostr = await relayProvider.genNostrWithKey(bunkerLink);
      } finally {
        cancel.call();
      }
    } else {
      if (Nip19.isPrivateKey(pk)) {
        pk = Nip19.decode(pk);
      }

      try {
        getPublicKey(pk);
      } catch (e) {
        // is not a private key
        BotToast.showText(text: S.of(context).Wrong_Private_Key_format);
        return;
      }

      doPreLogin();

      settingProvider.addAndChangePrivateKey(pk, updateUI: false);
      nostr = await relayProvider.genNostrWithKey(pk);
    }

    if (backAfterLogin) {
      RouterUtil.back(context);
    }

    settingProvider.notifyListeners();
    firstLogin = true;
    indexProvider.setCurrentTap(0);
  }

  Future<void> loginByAndroidSigner() async {
    var androidNostrSigner = AndroidNostrSigner();
    var pubkey = await androidNostrSigner.getPublicKey();
    if (StringUtil.isBlank(pubkey)) {
      BotToast.showText(text: localization.Login_fail);
      return;
    }

    doPreLogin();

    var key = "${AndroidNostrSigner.URI_PRE}:$pubkey";
    if (StringUtil.isNotBlank(androidNostrSigner.getPackage())) {
      key = "$key?package=${androidNostrSigner.getPackage()}";
    }
    settingProvider.addAndChangePrivateKey(key, updateUI: false);
    nostr = await relayProvider.genNostr(androidNostrSigner);

    if (backAfterLogin) {
      RouterUtil.back(context);
    }

    settingProvider.notifyListeners();
    firstLogin = true;
    indexProvider.setCurrentTap(0);
  }

  Future<void> loginWithWebSigner() async {
    var signer = NIP07Signer();
    var pubkey = await signer.getPublicKey();
    if (StringUtil.isBlank(pubkey)) {
      BotToast.showText(text: localization.Login_fail);
      return;
    }

    doPreLogin();

    var key = "${NIP07Signer.URI_PRE}:$pubkey";
    settingProvider.addAndChangePrivateKey(key, updateUI: false);
    nostr = await relayProvider.genNostr(signer);

    if (backAfterLogin) {
      RouterUtil.back(context);
    }

    settingProvider.notifyListeners();
    firstLogin = true;
    indexProvider.setCurrentTap(0);
  }

  void doPreLogin() {
    if (backAfterLogin) {
      AccountManagerWidgetState.clearCurrentMemInfo();
      nostr!.close();
      nostr = null;
    }
  }
}
