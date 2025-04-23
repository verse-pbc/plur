import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/data/user.dart';
import 'package:nostrmo/util/router_util.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../component/cust_state.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/uploader.dart';

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

  User? user;

  String _getText(String? str) {
    return str ?? "";
  }

  @override
  Widget doBuild(BuildContext context) {
    final localization = S.of(context);
    if (user == null) {
      var arg = RouterUtil.routerArgs(context);
      if (arg != null && arg is User) {
        user = arg;
      }
      user ??= User();

      displayNameController.text = _getText(user!.displayName);
      nameController.text = _getText(user!.name);
      aboutController.text = _getText(user!.about);
      pictureController.text = _getText(user!.picture);
      bannerController.text = _getText(user!.banner);
      websiteController.text = _getText(user!.website);
      nip05Controller.text = _getText(user!.nip05);
      lud16Controller.text = _getText(user!.lud16);
      lud06Controller.text = _getText(user!.lud06);
    }

    final themeData = Theme.of(context);
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

    var margin = const EdgeInsets.only(bottom: Base.basePadding);
    var padding = const EdgeInsets.only(left: 20, right: 20);

    List<Widget> list = [];

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
            left: Base.basePaddingHalf,
            right: Base.basePaddingHalf,
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
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        actions: [
          submitBtn,
        ],
      ),
      body: Stack(
        children: [
          SizedBox(
            height: mediaDataCache.size.height - mediaDataCache.padding.top,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: list,
              ),
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
      // still need to ban image update at web temp
      return null;
    }

    var filepath = await Uploader.pick(context);
    if (StringUtil.isNotBlank(filepath)) {
      return await Uploader.upload(
        filepath!,
        imageService: settingsProvider.imageService,
      );
    }
    return null;
  }

  void profileSave() {
    Map<String, dynamic>? metadataMap;
    if (profileEvent != null) {
      try {
        metadataMap = jsonDecode(profileEvent!.content);
      } catch (e) {
        log("profileSave jsonDecode error: $e");
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
        nostr!.publicKey, EventKind.metadata, tags, jsonEncode(metadataMap));
    nostr!.sendEvent(updateEvent);

    RouterUtil.back(context);
  }

  Event? profileEvent;

  @override
  Future<void> onReady(BuildContext context) async {
    var filter = Filter(
        kinds: [EventKind.metadata], authors: [nostr!.publicKey], limit: 1);
    nostr!.query([filter.toJson()], (event) {
      if (profileEvent == null) {
        profileEvent = event;
      } else if (event.createdAt > profileEvent!.createdAt) {
        profileEvent = event;
      }
    });
  }
}
