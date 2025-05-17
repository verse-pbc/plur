import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/consts/thread_mode.dart';
import 'package:nostrmo/router/index/account_manager_widget.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/store_util.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../component/confirm_dialog.dart';
import '../../component/editor/text_input_dialog.dart';
import '../../component/enum_multi_selector_widget.dart';
import '../../component/enum_selector_widget.dart';
import '../../component/translate/translate_model_manager.dart';
import '../../consts/base_consts.dart';
import '../../consts/image_services.dart';
import '../../data/user.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/settings_provider.dart';
import '../../provider/uploader.dart';
import '../../util/auth_util.dart';
import '../../util/locale_util.dart';
import 'settings_group_item_widget.dart';
import 'settings_group_title_widget.dart';

class SettingsWidget extends StatefulWidget {
  final Function indexReload;

  const SettingsWidget({
    super.key,
    required this.indexReload,
  });

  @override
  State<StatefulWidget> createState() {
    return _SettingsWidgetState();
  }
}

class _SettingsWidgetState extends State<SettingsWidget> with WhenStopFunction {
  void resetTheme() {
    widget.indexReload();
  }

  late S localization;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
    var settingsProvider = Provider.of<SettingsProvider>(context);
    var hintColor = themeData.hintColor;
    var cardColor = themeData.cardColor;

    localization = S.of(context);

    initOpenList(localization);
    initI18nList(localization);
    initCompressList(localization);
    initDefaultList(localization);
    initDefaultTabListTimeline(localization);
    initDefaultTabListGlobal(localization);

    initImageServiceList();
    initTranslateLanguages();
    initThreadModes();

    List<Widget> list = [];

    list.add(
      SettingsGroupItemWidget(
        name: localization.language,
        value: getI18nList(settingsProvider.i18n, settingsProvider.i18nCC).name,
        onTap: pickI18N,
      ),
    );
    list.add(SettingsGroupItemWidget(
      name: localization.imageCompress,
      value: getCompressList(settingsProvider.imgCompress).name,
      onTap: pickImageCompressList,
    ));
    if (!PlatformUtil.isPC()) {
      list.add(SettingsGroupItemWidget(
        name: localization.privacyLock,
        value: getLockOpenList(settingsProvider.lockOpen).name,
        onTap: pickLockOpenList,
      ));
    }

    String nwcValue = getOpenList(OpenStatus.open).name;
    if (StringUtil.isBlank(settingsProvider.nwcUrl)) {
      nwcValue = getOpenList(OpenStatus.close).name;
    }
    list.add(SettingsGroupItemWidget(
      name: "NWC ${localization.settings}",
      value: nwcValue,
      onTap: () {
        RouterUtil.router(context, RouterPath.nwcSetting);
      },
    ));
    list.add(SettingsGroupItemWidget(
      name: "Wot ${localization.filter}",
      value: getOpenListDefault(settingsProvider.wotFilter).name,
      onTap: pickWotFilter,
    ));

    list.add(SettingsGroupTitleWidget(
        iconData: Icons.article, title: localization.notes));
    list.add(SettingsGroupItemWidget(
      name: localization.linkPreview,
      value: getOpenList(settingsProvider.linkPreview).name,
      onTap: pickLinkPreview,
    ));
    list.add(SettingsGroupItemWidget(
      name: localization.videoPreviewInList,
      value: getOpenList(settingsProvider.videoPreviewInList).name,
      onTap: pickVideoPreviewInList,
    ));
    list.add(SettingsGroupItemWidget(
      name: localization.imageService,
      value: getImageService(settingsProvider.imageService).name,
      onTap: _pickImageService,
    ));
    if ((settingsProvider.imageService == ImageServices.nip96 ||
            settingsProvider.imageService == ImageServices.blossom) &&
        StringUtil.isNotBlank(settingsProvider.imageServiceAddr)) {
      list.add(SettingsGroupItemWidget(
        name: localization.imageServicePath,
        value: settingsProvider.imageServiceAddr,
      ));
    }

    list.add(SettingsGroupItemWidget(
      name: localization.limitNoteHeight,
      value: getOpenList(settingsProvider.limitNoteHeight).name,
      onTap: pickLimitNoteHeight,
    ));
    list.add(SettingsGroupItemWidget(
      name: localization.forbidProfilePicture,
      value: getOpenList(settingsProvider.profilePicturePreview).name,
      onTap: pickProfilePicturePreview,
    ));
    list.add(SettingsGroupItemWidget(
      name: localization.forbidImage,
      value: getOpenList(settingsProvider.imagePreview).name,
      onTap: pickImagePreview,
    ));
    list.add(SettingsGroupItemWidget(
      name: localization.forbidVideo,
      value: getOpenList(settingsProvider.videoPreview).name,
      onTap: pickVideoPreview,
    ));
    if (!PlatformUtil.isWeb()) {
      list.add(SettingsGroupItemWidget(
        name: "Blurhash ${localization.image}",
        value: getOpenList(settingsProvider.openBlurhashImage).name,
        onTap: pickOpenBlurhashImage,
      ));
    }
    if (!PlatformUtil.isPC()) {
      list.add(SettingsGroupItemWidget(
        name: localization.translate,
        value: getOpenTranslate(settingsProvider.openTranslate).name,
        onTap: pickOpenTranslate,
      ));
      if (settingsProvider.openTranslate == OpenStatus.open) {
        list.add(SettingsGroupItemWidget(
          name: localization.translateSourceLanguage,
          value: settingsProvider.translateSourceArgs,
          onTap: pickTranslateSource,
        ));
        list.add(SettingsGroupItemWidget(
          name: localization.translateTargetLanguage,
          value: settingsProvider.translateTarget,
          onTap: pickTranslateTarget,
        ));
      }
    }
    list.add(SettingsGroupItemWidget(
      name: localization.broadcastWhenBoost,
      value: getOpenList(settingsProvider.broadcaseWhenBoost).name,
      onTap: pickBroadcaseWhenBoost,
    ));
    list.add(SettingsGroupItemWidget(
      name: localization.autoOpenSensitiveContent,
      value: getOpenListDefault(settingsProvider.autoOpenSensitive).name,
      onTap: pickAutoOpenSensitive,
    ));
    list.add(SettingsGroupItemWidget(
      name: localization.threadMode,
      value: getThreadMode(settingsProvider.threadMode).name,
      onTap: pickThreadMode,
    ));
    list.add(SettingsGroupItemWidget(
      name: localization.maxSubNotes,
      value: "${settingsProvider.maxSubEventLevel ?? ""}",
      onTap: inputMaxSubNotesNumber,
    ));

    list.add(SettingsGroupTitleWidget(
        iconData: Icons.cloud, title: localization.network));
    String? networkHintText = settingsProvider.network;
    if (StringUtil.isBlank(networkHintText)) {
      networkHintText = "${localization.pleaseInput} ${localization.network}";
    }
    Widget networkWidget = Text(
      networkHintText!,
      style: TextStyle(
        fontFamily: 'SF Pro Rounded',
        color: hintColor,
        overflow: TextOverflow.ellipsis,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
    list.add(SettingsGroupItemWidget(
      name: localization.network,
      onTap: inputNetwork,
      child: networkWidget,
    ));
    if (!PlatformUtil.isWeb()) {
      list.add(SettingsGroupItemWidget(
        name: localization.localRelay,
        value: getOpenList(settingsProvider.relayLocal).name,
        onTap: pickRelayLocal,
      ));
      list.add(SettingsGroupItemWidget(
        name: localization.relayMode,
        value: getRelayMode(settingsProvider.relayMode).name,
        onTap: pickRelayModes,
      ));
      if (settingsProvider.relayMode != RelayMode.baseMode) {
        list.add(SettingsGroupItemWidget(
          name: localization.eventSignCheck,
          value: getOpenListDefault(settingsProvider.eventSignCheck).name,
          onTap: pickEventSignCheck,
        ));
      }
    }
    list.add(SettingsGroupItemWidget(
      name: localization.hideRelayNotices,
      value: getOpenList(settingsProvider.hideRelayNotices).name,
      onTap: pickHideRelayNotices,
    ));

    list.add(SettingsGroupTitleWidget(
        iconData: Icons.code, title: localization.development));

    list.add(SettingsGroupItemWidget(
      name: "Test Push Notifications",
      onTap: () {
        RouterUtil.router(context, RouterPath.pushNotificationTest);
      },
    ));

    list.add(SettingsGroupItemWidget(
      name: "Component Library",
      onTap: () {
        RouterUtil.router(context, RouterPath.componentLibrary);
      },
    ));

    list.add(SettingsGroupTitleWidget(
        iconData: Icons.source, title: localization.data));
    list.add(SettingsGroupItemWidget(
      name: localization.deleteAccount,
      nameColor: Colors.red,
      onTap: askToDeleteAccount,
    ));

    list.add(SliverToBoxAdapter(
      child: Container(
        color: cardColor,
        height: 30,
      ),
    ));

    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        title: Text(
          localization.settings,
          style: TextStyle(
            fontFamily: 'SF Pro Rounded',
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: list,
      ),
    );
  }

  List<EnumObj>? openList;

  void initOpenList(S s) {
    if (openList == null) {
      openList = [];
      openList!.add(EnumObj(OpenStatus.open, localization.open));
      openList!.add(EnumObj(OpenStatus.close, localization.close));
    }
  }

  EnumObj getOpenList(int? value) {
    for (var o in openList!) {
      if (value == o.value) {
        return o;
      }
    }

    return openList![0];
  }

  EnumObj getOpenListDefault(int? value) {
    for (var o in openList!) {
      if (value == o.value) {
        return o;
      }
    }

    return openList![1];
  }

  List<EnumObj>? i18nList;

  void initI18nList(S s) {
    if (i18nList == null) {
      i18nList = [];
      i18nList!.add(EnumObj("", localization.auto));
      for (var item in S.supportedLocales) {
        var key = LocaleUtil.getLocaleKey(item);
        i18nList!.add(EnumObj(key, key));
      }
    }
  }

  EnumObj getI18nList(String? i18n, String? i18nCC) {
    var key = LocaleUtil.genLocaleKeyFromSring(i18n, i18nCC);
    for (var eo in i18nList!) {
      if (eo.value == key) {
        return eo;
      }
    }
    return EnumObj("", S.of(context).auto);
  }

  Future pickI18N() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, i18nList!);
    if (resultEnumObj != null) {
      if (resultEnumObj.value == "") {
        settingsProvider.setI18n(null, null);
      } else {
        for (var item in S.supportedLocales) {
          var key = LocaleUtil.getLocaleKey(item);
          if (resultEnumObj.value == key) {
            settingsProvider.setI18n(item.languageCode, item.countryCode);
          }
        }
      }
      resetTheme();
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          // TODO others setting enumObjList
          i18nList = null;
        });
      });
    }
  }

  List<EnumObj>? compressList;

  void initCompressList(S s) {
    if (compressList == null) {
      compressList = [];
      compressList!.add(EnumObj(100, localization.dontCompress));
      compressList!.add(EnumObj(90, "90%"));
      compressList!.add(EnumObj(80, "80%"));
      compressList!.add(EnumObj(70, "70%"));
      compressList!.add(EnumObj(60, "60%"));
      compressList!.add(EnumObj(50, "50%"));
      compressList!.add(EnumObj(40, "40%"));
    }
  }

  Future<void> pickImageCompressList() async {
    EnumObj? resultEnumObj =
        await EnumSelectorWidget.show(context, compressList!);
    if (resultEnumObj != null) {
      settingsProvider.imgCompress = resultEnumObj.value;
    }
  }

  EnumObj getCompressList(int compress) {
    for (var eo in compressList!) {
      if (eo.value == compress) {
        return eo;
      }
    }
    return compressList![0];
  }

  List<EnumObj>? lockOpenList;

  EnumObj getLockOpenList(int lockOpen) {
    if (lockOpen == OpenStatus.open) {
      return openList![0];
    }
    return openList![1];
  }

  Future<void> pickLockOpenList() async {
    List<EnumObj> newLockOpenList = [];
    newLockOpenList.add(openList![1]);

    var localAuth = LocalAuthentication();
    List<BiometricType> availableBiometrics =
        await localAuth.getAvailableBiometrics();
    if (availableBiometrics.isNotEmpty) {
      newLockOpenList.add(openList![0]);
    }

    if (!mounted) return;
    final localization = S.of(context);

    EnumObj? resultEnumObj =
        await EnumSelectorWidget.show(context, newLockOpenList);
    if (!mounted) return;
    if (resultEnumObj != null) {
      if (resultEnumObj.value == OpenStatus.close) {
        bool didAuthenticate = await AuthUtil.authenticate(context,
            localization.pleaseAuthenticateToTurnOffThePrivacyLock);
        if (didAuthenticate) {
          settingsProvider.lockOpen = resultEnumObj.value;
        }
        settingsProvider.lockOpen = resultEnumObj.value;
      } else if (resultEnumObj.value == OpenStatus.open) {
        bool didAuthenticate = await AuthUtil.authenticate(context,
            localization.pleaseAuthenticateToTurnOnThePrivacyLock);
        if (didAuthenticate) {
          settingsProvider.lockOpen = resultEnumObj.value;
        }
      }
    }
  }

  List<EnumObj>? defaultIndexList;

  void initDefaultList(S s) {
    if (defaultIndexList == null) {
      defaultIndexList = [];
      defaultIndexList!.add(EnumObj(0, localization.timeline));
      defaultIndexList!.add(EnumObj(1, localization.global));
    }
  }

  Future<void> pickDefaultIndex() async {
    EnumObj? resultEnumObj =
        await EnumSelectorWidget.show(context, defaultIndexList!);
    if (resultEnumObj != null) {
      settingsProvider.defaultIndex = resultEnumObj.value;
      resetTheme();
    }
  }

  EnumObj getDefaultIndex(int? value) {
    for (var eo in defaultIndexList!) {
      if (eo.value == value) {
        return eo;
      }
    }
    return defaultIndexList![0];
  }

  List<EnumObj>? defaultTabListTimeline;

  void initDefaultTabListTimeline(S s) {
    if (defaultTabListTimeline == null) {
      defaultTabListTimeline = [];
      defaultTabListTimeline!.add(EnumObj(0, localization.posts));
      defaultTabListTimeline!.add(EnumObj(1, localization.postsAndReplies));
      defaultTabListTimeline!.add(EnumObj(2, localization.mentions));
    }
  }

  List<EnumObj>? defaultTabListGlobal;

  void initDefaultTabListGlobal(S s) {
    if (defaultTabListGlobal == null) {
      defaultTabListGlobal = [];
      defaultTabListGlobal!.add(EnumObj(0, localization.notes));
      defaultTabListGlobal!.add(EnumObj(1, localization.users));
      defaultTabListGlobal!.add(EnumObj(2, localization.topics));
    }
  }

  Future<void> pickDefaultTab(List<EnumObj> list) async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, list);
    if (resultEnumObj != null) {
      settingsProvider.defaultTab = resultEnumObj.value;
      resetTheme();
    }
  }

  EnumObj getDefaultTab(List<EnumObj> list, int? value) {
    for (var eo in list) {
      if (eo.value == value) {
        return eo;
      }
    }
    return list[0];
  }

  Future<void> pickLinkPreview() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingsProvider.linkPreview = resultEnumObj.value;
    }
  }

  Future<void> pickVideoPreviewInList() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingsProvider.videoPreviewInList = resultEnumObj.value;
    }
  }

  inputNetwork() async {
    final localization = S.of(context);
    var text = await TextInputDialog.show(
      context,
      "${localization.pleaseInput} ${localization.network}\nSOCKS5/SOCKS4/PROXY username:password@host:port",
      value: settingsProvider.network,
    );
    settingsProvider.network = text;
    BotToast.showText(text: localization.networkTakeEffectTip);
  }

  List<EnumObj>? imageServiceList;

  void initImageServiceList() {
    if (imageServiceList == null) {
      imageServiceList = [];
      imageServiceList!
          .add(EnumObj(ImageServices.nostrBuild, ImageServices.nostrBuild));
      imageServiceList!.add(
          EnumObj(ImageServices.pomf2LainLa, ImageServices.pomf2LainLa));
      imageServiceList!
          .add(EnumObj(ImageServices.nostore, ImageServices.nostore));
      imageServiceList!
          .add(EnumObj(ImageServices.voidCat, ImageServices.voidCat));
      imageServiceList!
          .add(EnumObj(ImageServices.nip95, ImageServices.nip95));
      imageServiceList!
          .add(EnumObj(ImageServices.nip96, ImageServices.nip96));
      imageServiceList!
          .add(EnumObj(ImageServices.blossom, ImageServices.blossom));
    }
  }

  EnumObj getImageService(String? o) {
    for (var eo in imageServiceList!) {
      if (eo.value == o) {
        return eo;
      }
    }
    return imageServiceList![0];
  }

  Future<void> _pickImageService() async {
    EnumObj? resultEnumObj =
        await EnumSelectorWidget.show(context, imageServiceList!);
    if (resultEnumObj != null && mounted) {
      if (resultEnumObj.value == ImageServices.nip96) {
        var addr = await TextInputDialog.show(context,
            "${localization.pleaseInput} NIP-96 ${localization.imageServicePath}");
        if (StringUtil.isNotBlank(addr)) {
          settingsProvider.imageService = ImageServices.nip96;
          settingsProvider.imageServiceAddr = addr;
        }
        return;
      } else if (resultEnumObj.value == ImageServices.blossom) {
        var addr = await TextInputDialog.show(context,
            "${localization.pleaseInput} Blossom ${localization.imageServicePath}");
        if (StringUtil.isNotBlank(addr)) {
          settingsProvider.imageService = ImageServices.blossom;
          settingsProvider.imageServiceAddr = addr;
        }
        return;
      }
      settingsProvider.imageService = resultEnumObj.value;
    }
  }

  pickLimitNoteHeight() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingsProvider.limitNoteHeight = resultEnumObj.value;
    }
  }

  pickProfilePicturePreview() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingsProvider.profilePicturePreview = resultEnumObj.value;
    }
  }

  pickImagePreview() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingsProvider.imagePreview = resultEnumObj.value;
    }
  }

  pickVideoPreview() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingsProvider.videoPreview = resultEnumObj.value;
    }
  }

  EventMemBox waitingDeleteEventBox = EventMemBox(sortAfterAdd: false);

  CancelFunc? deleteAccountLoadingCancel;

  askToDeleteAccount() async {
    var result =
        await ConfirmDialog.show(context, S.of(context).deleteAccountTips);
    if (result == true) {
      deleteAccountLoadingCancel = BotToast.showLoading();
      try {
        whenStopMS = 2000;

        waitingDeleteEventBox.clear();

        // use a blank metadata to update it
        var blankMetadata = User();
        var updateEvent = Event(nostr!.publicKey, EventKind.metadata, [],
            jsonEncode(blankMetadata));
        nostr!.sendEvent(updateEvent);

        // use a blank contact list to update it
        var blankContactList = ContactList();
        nostr!.sendContactList(blankContactList, "");

        var filter = Filter(authors: [
          nostr!.publicKey
        ], kinds: [
          EventKind.textNote,
          EventKind.repost,
          EventKind.genericRepost,
        ]);
        nostr!.query([filter.toJson()], onDeletedEventReceive);
      } catch (e) {
        log("delete account error: $e");
      }
    }
  }

  onDeletedEventReceive(Event event) {
    log("onDeletedEventReceive ${event.toJson()}");
    waitingDeleteEventBox.add(event);
    whenStop(handleDeleteEvent);
  }

  void handleDeleteEvent() {
    try {
      List<Event> all = waitingDeleteEventBox.all();
      List<String> ids = [];
      for (var event in all) {
        ids.add(event.id);

        if (ids.length > 20) {
          nostr!.deleteEvents(ids);
          ids.clear();
        }
      }

      if (ids.isNotEmpty) {
        nostr!.deleteEvents(ids);
      }
    } finally {
      var index = settingsProvider.privateKeyIndex;
      if (index != null) {
        AccountManagerWidgetState.onLogoutTap(index,
            routerBack: true, context: context);
        userProvider.clear();
      } else {
        nostr = null;
      }
      if (deleteAccountLoadingCancel != null) {
        deleteAccountLoadingCancel!.call();
      }
    }
  }

  List<EnumObj>? translateLanguages;

  void initTranslateLanguages() {
    if (translateLanguages == null) {
      translateLanguages = [];
      for (var tl in TranslateLanguage.values) {
        translateLanguages!.add(EnumObj(tl.bcpCode, tl.bcpCode));
      }
    }
  }

  EnumObj getOpenTranslate(int? value) {
    for (var o in openList!) {
      if (value == o.value) {
        return o;
      }
    }

    return openList![1];
  }

  pickOpenTranslate() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      await handleTranslateModel(openTranslate: resultEnumObj.value);
      settingsProvider.openTranslate = resultEnumObj.value;
    }
  }

  pickTranslateSource() async {
    var translateSourceArgs = settingsProvider.translateSourceArgs;
    List<EnumObj> values = [];
    if (StringUtil.isNotBlank(translateSourceArgs)) {
      var strs = translateSourceArgs!.split(",");
      for (var str in strs) {
        values.add(EnumObj(str, str));
      }
    }
    List<EnumObj>? resultEnumObjs = await EnumMultiSelectorWidget.show(
        context, translateLanguages!, values);
    if (resultEnumObjs != null) {
      List<String> resultStrs = [];
      for (var value in resultEnumObjs) {
        resultStrs.add(value.value);
      }
      var text = resultStrs.join(",");
      await handleTranslateModel(translateSourceArgs: text);
      settingsProvider.translateSourceArgs = text;
    }
  }

  pickTranslateTarget() async {
    EnumObj? resultEnumObj =
        await EnumSelectorWidget.show(context, translateLanguages!);
    if (resultEnumObj != null) {
      await handleTranslateModel(translateTarget: resultEnumObj.value);
      settingsProvider.translateTarget = resultEnumObj.value;
    }
  }

  Future<void> handleTranslateModel(
      {int? openTranslate,
      String? translateTarget,
      String? translateSourceArgs}) async {
    openTranslate = openTranslate ?? settingsProvider.openTranslate;
    translateTarget = translateTarget ?? settingsProvider.translateTarget;
    translateSourceArgs =
        translateSourceArgs ?? settingsProvider.translateSourceArgs;

    if (openTranslate == OpenStatus.open &&
        StringUtil.isNotBlank(translateTarget) &&
        StringUtil.isNotBlank(translateSourceArgs)) {
      List<String> bcpCodes = translateSourceArgs!.split(",");
      bcpCodes.add(translateTarget!);

      var translateModelManager = TranslateModelManager.getInstance();
      BotToast.showText(text: S.of(context).beginToDownloadTranslateModel);
      var cancelFunc = BotToast.showLoading();
      try {
        await translateModelManager.checkAndDownloadTargetModel(bcpCodes);
      } finally {
        cancelFunc.call();
      }
    }
  }

  pickBroadcaseWhenBoost() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingsProvider.broadcaseWhenBoost = resultEnumObj.value;
    }
  }

  EnumObj getAutoOpenSensitive(int? value) {
    for (var o in openList!) {
      if (value == o.value) {
        return o;
      }
    }

    return openList![1];
  }

  pickAutoOpenSensitive() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingsProvider.autoOpenSensitive = resultEnumObj.value;
    }
  }

  List<EnumObj>? relayModes;

  List<EnumObj> getRelayModes() {
    final localization = S.of(context);
    if (relayModes == null) {
      relayModes = [];
      relayModes!.add(EnumObj(RelayMode.fastMode, localization.fastMode));
      relayModes!.add(EnumObj(RelayMode.baseMode, localization.baseMode));
    }
    return relayModes!;
  }

  EnumObj getRelayMode(int? o) {
    var list = getRelayModes();
    for (var item in list) {
      if (item.value == o) {
        return item;
      }
    }

    return list[0];
  }

  pickRelayLocal() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingsProvider.relayLocal = resultEnumObj.value;
      resetTheme();
    }
  }

  pickRelayModes() async {
    EnumObj? resultEnumObj =
        await EnumSelectorWidget.show(context, getRelayModes());
    if (resultEnumObj != null) {
      settingsProvider.relayMode = resultEnumObj.value;
    }
  }

  pickEventSignCheck() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingsProvider.eventSignCheck = resultEnumObj.value;
    }
  }

  List<EnumObj>? threadModes;

  List<EnumObj> initThreadModes() {
    if (threadModes == null) {
      final localization = S.of(context);
      threadModes = [];
      threadModes!.add(EnumObj(ThreadMode.fullMode, localization.fullMode));
      threadModes!.add(EnumObj(ThreadMode.traceMode, localization.traceMode));
    }

    return threadModes!;
  }

  getThreadMode(int? o) {
    for (var eo in threadModes!) {
      if (eo.value == o) {
        return eo;
      }
    }
    return threadModes![1];
  }

  pickThreadMode() async {
    EnumObj? resultEnumObj =
        await EnumSelectorWidget.show(context, initThreadModes());
    if (resultEnumObj != null) {
      settingsProvider.threadMode = resultEnumObj.value;
    }
  }

  inputMaxSubNotesNumber() async {
    var numText = await TextInputDialog.show(
        context, S.of(context).pleaseInputTheMaxSubNotesNumber);
    if (StringUtil.isNotBlank(numText)) {
      var num = int.tryParse(numText!);
      if (num != null && num <= 0) {
        num = null;
      }
      settingsProvider.maxSubEventLevel = num;
    }
  }

  pickHideRelayNotices() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingsProvider.hideRelayNotices = resultEnumObj.value;
    }
  }

  pickBackgroundImage() async {
    var filepath = await Uploader.pick(context);
    if (StringUtil.isBlank(filepath)) {
      settingsProvider.backgroundImage = null;
    } else {
      if (PlatformUtil.isWeb()) {
        var uploadedFilepath = await Uploader.upload(filepath!,
            imageService: settingsProvider.imageService);
        settingsProvider.backgroundImage = uploadedFilepath;
      } else {
        var targetFilePath = await StoreUtil.saveFileToDocument(filepath!,
            targetFileName:
                "nostrbg_${DateTime.now().millisecondsSinceEpoch}.jpg");
        if (StringUtil.isNotBlank(targetFilePath)) {
          if (StringUtil.isNotBlank(settingsProvider.backgroundImage)) {
            // try to remove old file.
            try {
              var targetFile = File(settingsProvider.backgroundImage!);
              if (targetFile.existsSync()) {
                targetFile.deleteSync();
              }
            } catch (e) {
              log("Error deleting old background image: $e");
            }
          }
          settingsProvider.backgroundImage = targetFilePath;
          settingsProvider.translateTarget = null;
        }
      }
    }

    resetTheme();
  }

  pickOpenBlurhashImage() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingsProvider.openBlurhashImage = resultEnumObj.value;
    }
  }

  pickWotFilter() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingsProvider.wotFilter = resultEnumObj.value;

      if (settingsProvider.wotFilter == OpenStatus.open) {
        var pubkey = nostr!.publicKey;
        wotProvider.init(pubkey);
      } else {
        wotProvider.clear();
      }
    }
  }
}
