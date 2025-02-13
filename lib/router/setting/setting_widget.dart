import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_font_picker/flutter_font_picker.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/color_pick_dialog.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/consts/thread_mode.dart';
import 'package:nostrmo/router/index/account_manager_widget.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/store_util.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../component/colors_selector_widget.dart';
import '../../component/confirm_dialog.dart';
import '../../component/editor/text_input_dialog.dart';
import '../../component/enum_multi_selector_widget.dart';
import '../../component/enum_selector_widget.dart';
import '../../component/translate/translate_model_manager.dart';
import '../../consts/base_consts.dart';
import '../../consts/image_services.dart';
import '../../consts/theme_style.dart';
import '../../data/metadata.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/setting_provider.dart';
import '../../provider/uploader.dart';
import '../../util/auth_util.dart';
import '../../util/locale_util.dart';
import 'setting_group_item_widget.dart';
import 'setting_group_title_widget.dart';

class SettingWidget extends StatefulWidget {
  Function indexReload;

  SettingWidget({
    super.key,
    required this.indexReload,
  });

  @override
  State<StatefulWidget> createState() {
    return _SettingWidgetState();
  }
}

class _SettingWidgetState extends State<SettingWidget> with WhenStopFunction {
  void resetTheme() {
    widget.indexReload();
  }

  late S localization;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
    var settingProvider = Provider.of<SettingProvider>(context);
    var valueFontSize = themeData.textTheme.bodyMedium!.fontSize;

    var mainColor = themeData.primaryColor;
    var hintColor = themeData.hintColor;
    var cardColor = themeData.cardColor;

    localization = S.of(context);

    initOpenList(localization);
    initI18nList(localization);
    initCompressList(localization);
    initDefaultList(localization);
    initDefaultTabListTimeline(localization);
    initDefaultTabListGlobal(localization);
    initColorStyleEnumList(localization);

    initThemeStyleList(localization);
    initFontEnumList(localization);
    initImageServiceList();
    initTranslateLanguages();
    initThreadModes();

    List<Widget> list = [];

    list.add(
      SettingGroupItemWidget(
        name: localization.Language,
        value: getI18nList(settingProvider.i18n, settingProvider.i18nCC).name,
        onTap: pickI18N,
      ),
    );
    list.add(SettingGroupItemWidget(
      name: localization.Image_Compress,
      value: getCompressList(settingProvider.imgCompress).name,
      onTap: pickImageCompressList,
    ));
    if (!PlatformUtil.isPC()) {
      list.add(SettingGroupItemWidget(
        name: localization.Privacy_Lock,
        value: getLockOpenList(settingProvider.lockOpen).name,
        onTap: pickLockOpenList,
      ));
    }

    String nwcValue = getOpenList(OpenStatus.OPEN).name;
    if (StringUtil.isBlank(settingProvider.nwcUrl)) {
      nwcValue = getOpenList(OpenStatus.CLOSE).name;
    }
    list.add(SettingGroupItemWidget(
      name: "NWC ${localization.Settings}",
      value: nwcValue,
      onTap: () {
        RouterUtil.router(context, RouterPath.NWC_SETTING);
      },
    ));
    list.add(SettingGroupItemWidget(
      name: "Wot ${localization.Filter}",
      value: getOpenListDefault(settingProvider.wotFilter).name,
      onTap: pickWotFilter,
    ));

    list.add(SettingGroupTitleWidget(iconData: Icons.article, title: localization.Notes));
    list.add(SettingGroupItemWidget(
      name: localization.Link_preview,
      value: getOpenList(settingProvider.linkPreview).name,
      onTap: pickLinkPreview,
    ));
    list.add(SettingGroupItemWidget(
      name: localization.Video_preview_in_list,
      value: getOpenList(settingProvider.videoPreviewInList).name,
      onTap: pickVideoPreviewInList,
    ));
    list.add(SettingGroupItemWidget(
      name: localization.Image_service,
      value: getImageService(settingProvider.imageService).name,
      onTap: _pickImageService,
    ));
    if ((settingProvider.imageService == ImageServices.NIP_96 ||
            settingProvider.imageService == ImageServices.BLOSSOM) &&
        StringUtil.isNotBlank(settingProvider.imageServiceAddr)) {
      list.add(SettingGroupItemWidget(
        name: localization.Image_service_path,
        value: settingProvider.imageServiceAddr,
      ));
    }

    list.add(SettingGroupItemWidget(
      name: localization.Limit_Note_Height,
      value: getOpenList(settingProvider.limitNoteHeight).name,
      onTap: pickLimitNoteHeight,
    ));
    list.add(SettingGroupItemWidget(
      name: localization.Forbid_profile_picture,
      value: getOpenList(settingProvider.profilePicturePreview).name,
      onTap: pickProfilePicturePreview,
    ));
    list.add(SettingGroupItemWidget(
      name: localization.Forbid_image,
      value: getOpenList(settingProvider.imagePreview).name,
      onTap: pickImagePreview,
    ));
    list.add(SettingGroupItemWidget(
      name: localization.Forbid_video,
      value: getOpenList(settingProvider.videoPreview).name,
      onTap: pickVideoPreview,
    ));
    if (!PlatformUtil.isWeb()) {
      list.add(SettingGroupItemWidget(
        name: "Blurhash ${localization.Image}",
        value: getOpenList(settingProvider.openBlurhashImage).name,
        onTap: pickOpenBlurhashImage,
      ));
    }
    if (!PlatformUtil.isPC()) {
      list.add(SettingGroupItemWidget(
        name: localization.Translate,
        value: getOpenTranslate(settingProvider.openTranslate).name,
        onTap: pickOpenTranslate,
      ));
      if (settingProvider.openTranslate == OpenStatus.OPEN) {
        list.add(SettingGroupItemWidget(
          name: localization.Translate_Source_Language,
          value: settingProvider.translateSourceArgs,
          onTap: pickTranslateSource,
        ));
        list.add(SettingGroupItemWidget(
          name: localization.Translate_Target_Language,
          value: settingProvider.translateTarget,
          onTap: pickTranslateTarget,
        ));
      }
    }
    list.add(SettingGroupItemWidget(
      name: localization.Broadcast_When_Boost,
      value: getOpenList(settingProvider.broadcaseWhenBoost).name,
      onTap: pickBroadcaseWhenBoost,
    ));
    list.add(SettingGroupItemWidget(
      name: localization.Auto_Open_Sensitive_Content,
      value: getOpenListDefault(settingProvider.autoOpenSensitive).name,
      onTap: pickAutoOpenSensitive,
    ));
    list.add(SettingGroupItemWidget(
      name: localization.Thread_Mode,
      value: getThreadMode(settingProvider.threadMode).name,
      onTap: pickThreadMode,
    ));
    list.add(SettingGroupItemWidget(
      name: localization.Max_Sub_Notes,
      value: "${settingProvider.maxSubEventLevel ?? ""}",
      onTap: inputMaxSubNotesNumber,
    ));

    list.add(SettingGroupTitleWidget(iconData: Icons.cloud, title: localization.Network));
    String? networkHintText = settingProvider.network;
    if (StringUtil.isBlank(networkHintText)) {
      networkHintText = localization.Please_input + " " + localization.Network;
    }
    Widget networkWidget = Text(
      networkHintText!,
      style: TextStyle(
        color: hintColor,
        overflow: TextOverflow.ellipsis,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
    list.add(SettingGroupItemWidget(
      name: localization.Network,
      onTap: inputNetwork,
      child: networkWidget,
    ));
    if (!PlatformUtil.isWeb()) {
      list.add(SettingGroupItemWidget(
        name: localization.LocalRelay,
        value: getOpenList(settingProvider.relayLocal).name,
        onTap: pickRelayLocal,
      ));
      list.add(SettingGroupItemWidget(
        name: localization.Relay_Mode,
        value: getRelayMode(settingProvider.relayMode).name,
        onTap: pickRelayModes,
      ));
      if (settingProvider.relayMode != RelayMode.BASE_MODE) {
        list.add(SettingGroupItemWidget(
          name: localization.Event_Sign_Check,
          value: getOpenListDefault(settingProvider.eventSignCheck).name,
          onTap: pickEventSignCheck,
        ));
      }
    }
    list.add(SettingGroupItemWidget(
      name: localization.Hide_Relay_Notices,
      value: getOpenList(settingProvider.hideRelayNotices).name,
      onTap: pickHideRelayNotices,
    ));

    list.add(SettingGroupTitleWidget(iconData: Icons.source, title: localization.Data));
    list.add(SettingGroupItemWidget(
      name: localization.Delete_Account,
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
          localization.Settings,
          style: TextStyle(
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
      openList!.add(EnumObj(OpenStatus.OPEN, localization.open));
      openList!.add(EnumObj(OpenStatus.CLOSE, localization.close));
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
      for (var item in S.delegate.supportedLocales) {
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
        settingProvider.setI18n(null, null);
      } else {
        for (var item in S.delegate.supportedLocales) {
          var key = LocaleUtil.getLocaleKey(item);
          if (resultEnumObj.value == key) {
            settingProvider.setI18n(item.languageCode, item.countryCode);
          }
        }
      }
      resetTheme();
      Future.delayed(Duration(seconds: 1), () {
        setState(() {
          // TODO others setting enumObjList
          i18nList = null;
          themeStyleList = null;
        });
      });
    }
  }

  List<EnumObj>? compressList;

  void initCompressList(S s) {
    if (compressList == null) {
      compressList = [];
      compressList!.add(EnumObj(100, localization.Dont_Compress));
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
      settingProvider.imgCompress = resultEnumObj.value;
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
    if (lockOpen == OpenStatus.OPEN) {
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

    final localization = S.of(context);

    EnumObj? resultEnumObj =
        await EnumSelectorWidget.show(context, newLockOpenList);
    if (resultEnumObj != null) {
      if (resultEnumObj.value == OpenStatus.CLOSE) {
        bool didAuthenticate = await AuthUtil.authenticate(
            context, localization.Please_authenticate_to_turn_off_the_privacy_lock);
        if (didAuthenticate) {
          settingProvider.lockOpen = resultEnumObj.value;
        }
        settingProvider.lockOpen = resultEnumObj.value;
      } else if (resultEnumObj.value == OpenStatus.OPEN) {
        bool didAuthenticate = await AuthUtil.authenticate(
            context, localization.Please_authenticate_to_turn_on_the_privacy_lock);
        if (didAuthenticate) {
          settingProvider.lockOpen = resultEnumObj.value;
        }
      }
    }
  }

  List<EnumObj>? defaultIndexList;

  void initDefaultList(S s) {
    if (defaultIndexList == null) {
      defaultIndexList = [];
      defaultIndexList!.add(EnumObj(0, localization.Timeline));
      defaultIndexList!.add(EnumObj(1, localization.Global));
    }
  }

  Future<void> pickDefaultIndex() async {
    EnumObj? resultEnumObj =
        await EnumSelectorWidget.show(context, defaultIndexList!);
    if (resultEnumObj != null) {
      settingProvider.defaultIndex = resultEnumObj.value;
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
      defaultTabListTimeline!.add(EnumObj(0, localization.Posts));
      defaultTabListTimeline!.add(EnumObj(1, localization.Posts_and_replies));
      defaultTabListTimeline!.add(EnumObj(2, localization.Mentions));
    }
  }

  List<EnumObj>? defaultTabListGlobal;

  void initDefaultTabListGlobal(S s) {
    if (defaultTabListGlobal == null) {
      defaultTabListGlobal = [];
      defaultTabListGlobal!.add(EnumObj(0, localization.Notes));
      defaultTabListGlobal!.add(EnumObj(1, localization.Users));
      defaultTabListGlobal!.add(EnumObj(2, localization.Topics));
    }
  }

  Future<void> pickDefaultTab(List<EnumObj> list) async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, list);
    if (resultEnumObj != null) {
      settingProvider.defaultTab = resultEnumObj.value;
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

  List<EnumObj>? themeStyleList;

  void initThemeStyleList(S s) {
    if (themeStyleList == null) {
      themeStyleList = [];
      themeStyleList?.add(EnumObj(ThemeStyle.AUTO, localization.Follow_System));
      themeStyleList?.add(EnumObj(ThemeStyle.LIGHT, localization.Light));
      themeStyleList?.add(EnumObj(ThemeStyle.DARK, localization.Dark));
    }
  }

  Future<void> pickThemeStyle() async {
    EnumObj? resultEnumObj =
        await EnumSelectorWidget.show(context, themeStyleList!);
    if (resultEnumObj != null) {
      settingProvider.themeStyle = resultEnumObj.value;
      resetTheme();
    }
  }

  EnumObj getThemeStyle(int themeStyle) {
    for (var eo in themeStyleList!) {
      if (eo.value == themeStyle) {
        return eo;
      }
    }
    return themeStyleList![0];
  }

  Future<void> pickColor() async {
    Color? color = await ColorSelectorWidget.show(context);
    if (color != null) {
      settingProvider.themeColor = color.value;
      resetTheme();
    }
  }

  List<EnumObj>? colorStyleEnumList;

  void initColorStyleEnumList(S s) {
    if (colorStyleEnumList == null) {
      colorStyleEnumList = [];
      colorStyleEnumList!.add(EnumObj(false, localization.Default_Color));
      colorStyleEnumList!.add(EnumObj(true, localization.Custom_Color));
    }
  }

  Widget getCustomColorWidget(int? colorValue, TextStyle textStyle) {
    if (colorValue == null) {
      return Text(
        localization.Default_Color,
        style: textStyle,
      );
    } else {
      return Container(
        height: 28,
        width: 28,
        color: Color(colorValue),
      );
    }
  }

  Future<int?> pickCustomColor({int? colorValue}) async {
    Color? oldColor;
    if (colorValue != null) {
      oldColor = Color(colorValue);
    }
    EnumObj? resultEnumObj =
        await EnumSelectorWidget.show(context, colorStyleEnumList!);
    if (resultEnumObj != null) {
      if (resultEnumObj.value == true) {
        // pick customm color
        Color? color = await ColorPickDialog.show(context, oldColor);
        if (color != null) {
          return color.value;
        }
      } else {
        return -1;
      }
    }

    return null;
  }

  Future<void> pickMainFontColor() async {
    var colorValue =
        await pickCustomColor(colorValue: settingProvider.mainFontColor);
    if (colorValue != null) {
      if (colorValue == -1) {
        settingProvider.mainFontColor = null;
      } else {
        settingProvider.mainFontColor = colorValue;
      }
      resetTheme();
    }
  }

  Future<void> pickHintFontColor() async {
    var colorValue =
        await pickCustomColor(colorValue: settingProvider.hintFontColor);
    if (colorValue != null) {
      if (colorValue == -1) {
        settingProvider.hintFontColor = null;
      } else {
        settingProvider.hintFontColor = colorValue;
      }
      resetTheme();
    }
  }

  Future<void> pickCardColor() async {
    var colorValue =
        await pickCustomColor(colorValue: settingProvider.cardColor);
    if (colorValue != null) {
      if (colorValue == -1) {
        settingProvider.cardColor = null;
      } else {
        settingProvider.cardColor = colorValue;
      }
      resetTheme();
    }
  }

  List<EnumObj>? fontEnumList;

  void initFontEnumList(S s) {
    if (fontEnumList == null) {
      fontEnumList = [];
      fontEnumList!.add(EnumObj(false, localization.Default_Font_Family));
      fontEnumList!.add(EnumObj(true, localization.Custom_Font_Family));
    }
  }

  String getFontEnumResult(String? fontFamily) {
    if (StringUtil.isNotBlank(fontFamily)) {
      return fontFamily!;
    }
    return fontEnumList![0].name;
  }

  Future pickFontEnum() async {
    EnumObj? resultEnumObj =
        await EnumSelectorWidget.show(context, fontEnumList!);
    if (resultEnumObj != null) {
      if (resultEnumObj.value == true) {
        pickFont();
      } else {
        settingProvider.fontFamily = null;
        resetTheme();
      }
    }
  }

  void pickFont() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FontPicker(
          onFontChanged: (PickerFont font) {
            settingProvider.fontFamily = font.fontFamily;
            resetTheme();
          },
        ),
      ),
    );
  }

  List<EnumObj> fontSizeList = [
    EnumObj(20.0, "20"),
    EnumObj(19.0, "19"),
    EnumObj(18.0, "18"),
    EnumObj(17.0, "17"),
    EnumObj(16.0, "16"),
    EnumObj(15.0, "15"),
    EnumObj(14.0, "14"),
    EnumObj(13.0, "13"),
    EnumObj(12.0, "12"),
  ];

  EnumObj getFontSize(double value) {
    for (var eo in fontSizeList) {
      if (eo.value == value) {
        return eo;
      }
    }
    return fontSizeList[1];
  }

  Future<void> pickFontSize() async {
    EnumObj? resultEnumObj =
        await EnumSelectorWidget.show(context, fontSizeList);
    if (resultEnumObj != null) {
      settingProvider.fontSize = resultEnumObj.value;
      resetTheme();
    }
  }

  Future<void> pickLinkPreview() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.linkPreview = resultEnumObj.value;
    }
  }

  Future<void> pickVideoPreviewInList() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.videoPreviewInList = resultEnumObj.value;
    }
  }

  inputNetwork() async {
    final localization = S.of(context);
    var text = await TextInputDialog.show(
      context,
      "${localization.Please_input} ${localization.Network}\nSOCKS5/SOCKS4/PROXY username:password@host:port",
      value: settingProvider.network,
    );
    settingProvider.network = text;
    BotToast.showText(text: localization.network_take_effect_tip);
  }

  List<EnumObj>? imageServiceList;

  void initImageServiceList() {
    if (imageServiceList == null) {
      imageServiceList = [];
      imageServiceList!
          .add(EnumObj(ImageServices.NOSTR_BUILD, ImageServices.NOSTR_BUILD));
      imageServiceList!.add(
          EnumObj(ImageServices.POMF2_LAIN_LA, ImageServices.POMF2_LAIN_LA));
      imageServiceList!
          .add(EnumObj(ImageServices.NOSTO_RE, ImageServices.NOSTO_RE));
      imageServiceList!
          .add(EnumObj(ImageServices.VOID_CAT, ImageServices.VOID_CAT));
      imageServiceList!
          .add(EnumObj(ImageServices.NIP_95, ImageServices.NIP_95));
      imageServiceList!
          .add(EnumObj(ImageServices.NIP_96, ImageServices.NIP_96));
      imageServiceList!
          .add(EnumObj(ImageServices.BLOSSOM, ImageServices.BLOSSOM));
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
    if (resultEnumObj != null) {
      if (resultEnumObj.value == ImageServices.NIP_96) {
        var addr = await TextInputDialog.show(
            context, "${localization.Please_input} NIP-96 ${localization.Image_service_path}");
        if (StringUtil.isNotBlank(addr)) {
          settingProvider.imageService = ImageServices.NIP_96;
          settingProvider.imageServiceAddr = addr;
        }
        return;
      } else if (resultEnumObj.value == ImageServices.BLOSSOM) {
        var addr = await TextInputDialog.show(
            context, "${localization.Please_input} Blossom ${localization.Image_service_path}");
        if (StringUtil.isNotBlank(addr)) {
          settingProvider.imageService = ImageServices.BLOSSOM;
          settingProvider.imageServiceAddr = addr;
        }
        return;
      }
      settingProvider.imageService = resultEnumObj.value;
    }
  }

  pickLimitNoteHeight() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.limitNoteHeight = resultEnumObj.value;
    }
  }

  pickProfilePicturePreview() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.profilePicturePreview = resultEnumObj.value;
    }
  }

  pickImagePreview() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.imagePreview = resultEnumObj.value;
    }
  }

  pickVideoPreview() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.videoPreview = resultEnumObj.value;
    }
  }

  EventMemBox waitingDeleteEventBox = EventMemBox(sortAfterAdd: false);

  CancelFunc? deleteAccountLoadingCancel;

  askToDeleteAccount() async {
    var result =
        await ConfirmDialog.show(context, S.of(context).Delete_Account_Tips);
    if (result == true) {
      deleteAccountLoadingCancel = BotToast.showLoading();
      try {
        whenStopMS = 2000;

        waitingDeleteEventBox.clear();

        // use a blank metadata to update it
        var blankMetadata = Metadata();
        var updateEvent = Event(nostr!.publicKey, EventKind.METADATA, [],
            jsonEncode(blankMetadata));
        nostr!.sendEvent(updateEvent);

        // use a blank contact list to update it
        var blankContactList = ContactList();
        nostr!.sendContactList(blankContactList, "");

        var filter = Filter(authors: [
          nostr!.publicKey
        ], kinds: [
          EventKind.TEXT_NOTE,
          EventKind.REPOST,
          EventKind.GENERIC_REPOST,
        ]);
        nostr!.query([filter.toJson()], onDeletedEventReceive);
      } catch (e) {
        log("delete account error ${e.toString()}");
      }
    }
  }

  onDeletedEventReceive(Event event) {
    print(event.toJson());
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
      var index = settingProvider.privateKeyIndex;
      if (index != null) {
        AccountManagerWidgetState.onLogoutTap(index,
            routerBack: true, context: context);
        metadataProvider.clear();
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
      settingProvider.openTranslate = resultEnumObj.value;
    }
  }

  pickTranslateSource() async {
    var translateSourceArgs = settingProvider.translateSourceArgs;
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
      settingProvider.translateSourceArgs = text;
    }
  }

  pickTranslateTarget() async {
    EnumObj? resultEnumObj =
        await EnumSelectorWidget.show(context, translateLanguages!);
    if (resultEnumObj != null) {
      await handleTranslateModel(translateTarget: resultEnumObj.value);
      settingProvider.translateTarget = resultEnumObj.value;
    }
  }

  Future<void> handleTranslateModel(
      {int? openTranslate,
      String? translateTarget,
      String? translateSourceArgs}) async {
    openTranslate = openTranslate ?? settingProvider.openTranslate;
    translateTarget = translateTarget ?? settingProvider.translateTarget;
    translateSourceArgs =
        translateSourceArgs ?? settingProvider.translateSourceArgs;

    if (openTranslate == OpenStatus.OPEN &&
        StringUtil.isNotBlank(translateTarget) &&
        StringUtil.isNotBlank(translateSourceArgs)) {
      List<String> bcpCodes = translateSourceArgs!.split(",");
      bcpCodes.add(translateTarget!);

      var translateModelManager = TranslateModelManager.getInstance();
      BotToast.showText(text: S.of(context).Begin_to_download_translate_model);
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
      settingProvider.broadcaseWhenBoost = resultEnumObj.value;
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
      settingProvider.autoOpenSensitive = resultEnumObj.value;
    }
  }

  pickWebviewAppbar() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.webviewAppbarOpen = resultEnumObj.value;
    }
  }

  getOpenMode(int? value) {
    for (var o in openList!) {
      if (value == o.value) {
        return o;
      }
    }

    if (PlatformUtil.isTableModeWithoutSetting()) {
      return openList![0];
    }
    return openList![1];
  }

  pickOpenMode() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.tableMode = resultEnumObj.value;
      resetTheme();
    }
  }

  List<EnumObj>? relayModes;

  List<EnumObj> getRelayModes() {
    final localization = S.of(context);
    if (relayModes == null) {
      relayModes = [];
      relayModes!.add(EnumObj(RelayMode.FAST_MODE, localization.Fast_Mode));
      relayModes!.add(EnumObj(RelayMode.BASE_MODE, localization.Base_Mode));
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
      settingProvider.relayLocal = resultEnumObj.value;
      resetTheme();
    }
  }

  pickRelayModes() async {
    EnumObj? resultEnumObj =
        await EnumSelectorWidget.show(context, getRelayModes());
    if (resultEnumObj != null) {
      settingProvider.relayMode = resultEnumObj.value;
    }
  }

  pickEventSignCheck() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.eventSignCheck = resultEnumObj.value;
    }
  }

  List<EnumObj>? threadModes;

  List<EnumObj> initThreadModes() {
    if (threadModes == null) {
      final localization = S.of(context);
      threadModes = [];
      threadModes!.add(EnumObj(ThreadMode.FULL_MODE, localization.Full_Mode));
      threadModes!.add(EnumObj(ThreadMode.TRACE_MODE, localization.Trace_Mode));
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
      settingProvider.threadMode = resultEnumObj.value;
    }
  }

  inputMaxSubNotesNumber() async {
    var numText = await TextInputDialog.show(
        context, S.of(context).Please_input_the_max_sub_notes_number);
    if (StringUtil.isNotBlank(numText)) {
      var num = int.tryParse(numText!);
      if (num != null && num <= 0) {
        num = null;
      }
      settingProvider.maxSubEventLevel = num;
    }
  }

  pickHideRelayNotices() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.hideRelayNotices = resultEnumObj.value;
    }
  }

  pickBackgroundImage() async {
    var filepath = await Uploader.pick(context);
    if (StringUtil.isBlank(filepath)) {
      settingProvider.backgroundImage = null;
    } else {
      if (PlatformUtil.isWeb()) {
        var uploadedFilepath = await Uploader.upload(filepath!,
            imageService: settingProvider.imageService);
        settingProvider.backgroundImage = uploadedFilepath;
      } else {
        var targetFilePath = await StoreUtil.saveFileToDocument(filepath!,
            targetFileName:
                "nostrbg_${DateTime.now().millisecondsSinceEpoch}.jpg");
        if (StringUtil.isNotBlank(targetFilePath)) {
          if (StringUtil.isNotBlank(settingProvider.backgroundImage)) {
            // try to remove old file.
            try {
              var targetFile = File(settingProvider.backgroundImage!);
              if (targetFile.existsSync()) {
                targetFile.deleteSync();
              }
            } catch (e) {}
          }
          settingProvider.backgroundImage = targetFilePath;
          settingProvider.translateTarget = null;
        }
      }
    }

    resetTheme();
  }

  pickOpenBlurhashImage() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.openBlurhashImage = resultEnumObj.value;
    }
  }

  pickPubkeyColor() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.pubkeyColor = resultEnumObj.value;
    }
  }

  pickWotFilter() async {
    EnumObj? resultEnumObj = await EnumSelectorWidget.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.wotFilter = resultEnumObj.value;

      if (settingProvider.wotFilter == OpenStatus.OPEN) {
        var pubkey = nostr!.publicKey;
        wotProvider.init(pubkey);
      } else {
        wotProvider.clear();
      }
    }
  }
}
