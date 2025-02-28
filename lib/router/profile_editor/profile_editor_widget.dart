import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/data/metadata.dart';
import 'package:nostrmo/util/router_util.dart';

import '../../component/appbar4stack.dart';
import '../../component/cust_state.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/uploader.dart';
import '../../util/table_mode_util.dart';
import '../index/index_app_bar.dart';

class ProfileEditorWidget extends StatefulWidget {
  const ProfileEditorWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _ProfileEditorWidgetState();
  }
}

class _ProfileEditorWidgetState extends CustState<ProfileEditorWidget> {
  TextEditingController displayNameController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController aboutController = TextEditingController();
  TextEditingController pictureController = TextEditingController();
  TextEditingController bannerController = TextEditingController();
  TextEditingController websiteController = TextEditingController();
  TextEditingController nip05Controller = TextEditingController();
  TextEditingController lud16Controller = TextEditingController();
  TextEditingController lud06Controller = TextEditingController();

  Metadata? metadata;

  String _getText(String? str) {
    return str ?? "";
  }

  @override
  Widget doBuild(BuildContext context) {
    final localization = S.of(context);
    if (metadata == null) {
      var arg = RouterUtil.routerArgs(context);
      if (arg != null && arg is Metadata) {
        metadata = arg;
      }
      metadata ??= Metadata();

      displayNameController.text = _getText(metadata!.displayName);
      nameController.text = _getText(metadata!.name);
      aboutController.text = _getText(metadata!.about);
      pictureController.text = _getText(metadata!.picture);
      bannerController.text = _getText(metadata!.banner);
      websiteController.text = _getText(metadata!.website);
      nip05Controller.text = _getText(metadata!.nip05);
      lud16Controller.text = _getText(metadata!.lud16);
      lud06Controller.text = _getText(metadata!.lud06);
    }

    final themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var textColor = themeData.textTheme.bodyMedium!.color;

    var submitBtn = TextButton(
      onPressed: profileSave,
      style: const ButtonStyle(),
      child: Text(
        localization.Submit,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
        ),
      ),
    );

    Color? appbarBackgroundColor = Colors.transparent;
    var appBar = Appbar4Stack(
      backgroundColor: appbarBackgroundColor,
      // title: appbarTitle,
      action: Container(
        margin: const EdgeInsets.only(right: Base.BASE_PADDING),
        child: submitBtn,
      ),
    );

    var margin = const EdgeInsets.only(bottom: Base.BASE_PADDING);
    var padding = const EdgeInsets.only(left: 20, right: 20);

    List<Widget> list = [];

    if (TableModeUtil.isTableMode()) {
      list.add(Container(
        height: 30,
      ));
    }

    list.add(Container(
      margin: margin,
      padding: padding,
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: displayNameController,
            decoration: InputDecoration(labelText: localization.Display_Name),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(
            left: Base.BASE_PADDING_HALF,
            right: Base.BASE_PADDING_HALF,
          ),
          child: const Text(" @ "),
        ),
        Expanded(
          child: TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: localization.Name),
          ),
        ),
      ]),
    ));

    list.add(Container(
      margin: margin,
      padding: padding,
      child: TextField(
        minLines: 2,
        maxLines: 10,
        controller: aboutController,
        decoration: InputDecoration(labelText: localization.About),
      ),
    ));

    list.add(Container(
      margin: margin,
      padding: padding,
      child: TextField(
        controller: pictureController,
        decoration: InputDecoration(
          prefixIcon: GestureDetector(
            onTap: pickPicture,
            child: const Icon(Icons.image),
          ),
          labelText: localization.Picture,
        ),
      ),
    ));

    list.add(Container(
      margin: margin,
      padding: padding,
      child: TextField(
        controller: bannerController,
        decoration: InputDecoration(
          prefixIcon: GestureDetector(
            onTap: pickBanner,
            child: const Icon(Icons.image),
          ),
          labelText: localization.Banner,
        ),
      ),
    ));

    list.add(Container(
      margin: margin,
      padding: padding,
      child: TextField(
        controller: websiteController,
        decoration: InputDecoration(labelText: localization.Website),
      ),
    ));

    list.add(Container(
      margin: margin,
      padding: padding,
      child: TextField(
        controller: nip05Controller,
        decoration: InputDecoration(labelText: "Nostr ${localization.Address}"),
      ),
    ));

    list.add(Container(
      margin: margin,
      padding: padding,
      child: TextField(
        controller: lud16Controller,
        decoration: InputDecoration(
            labelText: localization.Lightning_Address,
            hintText: "walletname@walletservice.com"),
      ),
    ));

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: mediaDataCache.size.width,
            height: mediaDataCache.size.height - mediaDataCache.padding.top,
            margin: EdgeInsets.only(top: mediaDataCache.padding.top),
            child: Container(
              color: cardColor,
              padding: EdgeInsets.only(
                  top: mediaDataCache.padding.top + Base.BASE_PADDING),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: list,
                ),
              ),
            ),
          ),
          Positioned(
            top: mediaDataCache.padding.top,
            left: 0,
            right: 0,
            child: Container(
              child: appBar,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> pickPicture() async {
    var filepath = await pickImageAndUpload();
    if (StringUtil.isNotBlank(filepath)) {
      pictureController.text = filepath!;
    }
  }

  Future<void> pickBanner() async {
    var filepath = await pickImageAndUpload();
    if (StringUtil.isNotBlank(filepath)) {
      bannerController.text = filepath!;
    }
  }

  Future<String?> pickImageAndUpload() async {
    if (PlatformUtil.isWeb()) {
      // TODO ban image update at web temp
      return null;
    }

    var filepath = await Uploader.pick(context);
    if (StringUtil.isNotBlank(filepath)) {
      return await Uploader.upload(
        filepath!,
        imageService: settingsProvider.imageService,
      );
    }
  }

  void profileSave() {
    Map<String, dynamic>? metadataMap;
    if (profileEvent != null) {
      try {
        metadataMap = jsonDecode(profileEvent!.content);
      } catch (e) {
        log("profileSave jsonDecode error");
        print(e);
      }
    } else {
      metadataMap = {};
    }

    metadataMap!["display_name"] = displayNameController.text;
    metadataMap["name"] = nameController.text;
    metadataMap["about"] = aboutController.text;
    metadataMap["picture"] = pictureController.text;
    metadataMap["banner"] = bannerController.text;
    metadataMap["website"] = websiteController.text;
    metadataMap["nip05"] = nip05Controller.text;
    metadataMap["lud16"] = lud16Controller.text;
    metadataMap["lud06"] = lud06Controller.text;

    List<dynamic> tags = [];
    if (profileEvent != null) {
      tags = profileEvent!.tags;
    }

    var updateEvent = Event(
        nostr!.publicKey, EventKind.METADATA, tags, jsonEncode(metadataMap));
    nostr!.sendEvent(updateEvent);

    RouterUtil.back(context);
  }

  Event? profileEvent;

  @override
  Future<void> onReady(BuildContext context) async {
    var filter = Filter(
        kinds: [EventKind.METADATA], authors: [nostr!.publicKey], limit: 1);
    nostr!.query([filter.toJson()], (event) {
      if (profileEvent == null) {
        profileEvent = event;
      } else if (event.createdAt > profileEvent!.createdAt) {
        profileEvent = event;
      }
    });
  }
}
