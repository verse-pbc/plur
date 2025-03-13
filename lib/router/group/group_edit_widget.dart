import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../../component/appbar4stack.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../main.dart';

import '../../provider/uploader.dart';
import '../../util/table_mode_util.dart';
import '../../util/theme_util.dart';

class GroupEditWidget extends StatefulWidget {
  const GroupEditWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _GroupEditWidgetState();
  }
}

class _GroupEditWidgetState extends State<GroupEditWidget> {
  TextEditingController hostController = TextEditingController();
  TextEditingController groupIdController = TextEditingController();

  TextEditingController nameController = TextEditingController();
  TextEditingController pictureController = TextEditingController();
  TextEditingController aboutController = TextEditingController();

  GroupIdentifier? groupIdentifier;

  bool publicValue = false;

  bool openValue = false;

  GroupMetadata? oldGroupMetadata;

  late S localization;

  TextStyle _bodyStyle(ThemeData theme) => TextStyle(
        color: theme.textTheme.bodyMedium!.color,
      );

  @override
  Widget build(BuildContext context) {
    var arg = RouterUtil.routerArgs(context);
    if (arg == null || arg is! GroupIdentifier) {
      RouterUtil.back(context);
      return Container();
    }
    groupIdentifier = arg;
    var margin = const EdgeInsets.only(bottom: Base.basePadding);
    var padding = const EdgeInsets.only(left: 20, right: 20);

    GroupProvider groupProvider = Provider.of<GroupProvider>(context);
    localization = S.of(context);

    var groupMetadata = groupProvider.getMetadata(groupIdentifier!);

    if (groupMetadata != null) {
      if (oldGroupMetadata == null ||
          groupMetadata.groupId != oldGroupMetadata!.groupId) {
        nameController.text = getText(groupMetadata.name);
        pictureController.text = getText(groupMetadata.picture);
        aboutController.text = getText(groupMetadata.about);
        if (groupMetadata.public != null) {
          publicValue = groupMetadata.public!;
        }
        if (groupMetadata.open != null) {
          openValue = groupMetadata.open!;
        }
      }
    }
    oldGroupMetadata = groupMetadata;

    hostController.text = groupIdentifier!.host;
    groupIdController.text = groupIdentifier!.groupId;

    final themeData = Theme.of(context);
    final textColor = themeData.textTheme.bodyMedium!.color;

    var submitBtn = TextButton(
      onPressed: doSave,
      style: const ButtonStyle(),
      child: Text(
        localization.Submit,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
        ),
      ),
    );

    var appBar = Appbar4Stack(
      backgroundColor: themeData.customColors.navBgColor,
      action: Container(
        margin: const EdgeInsets.only(right: Base.basePadding),
        child: submitBtn,
      ),
    );

    List<Widget> list = [];

    if (TableModeUtil.isTableMode()) {
      list.add(Container(
        height: 30,
      ));
    }

    list.add(Container(
      margin: margin,
      padding: padding,
      child: TextField(
        controller: hostController,
        decoration: InputDecoration(labelText: localization.Relay),
        readOnly: true,
      ),
    ));

    list.add(Container(
      margin: margin,
      padding: padding,
      child: TextField(
        controller: groupIdController,
        decoration: InputDecoration(labelText: localization.GroupId),
        readOnly: true,
      ),
    ));

    list.add(Container(
      margin: margin,
      padding: padding,
      child: TextField(
        controller: nameController,
        decoration: InputDecoration(labelText: localization.Name),
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
        minLines: 2,
        maxLines: 10,
        controller: aboutController,
        decoration: InputDecoration(labelText: localization.About),
      ),
    ));

    list.add(Container(
      margin: margin,
      padding: padding,
      child: DropdownButton<bool>(
        isExpanded: true,
        items: [
          DropdownMenuItem(
            value: true,
            child: Text(
              localization.public,
              style: _bodyStyle(themeData),
            ),
          ),
          DropdownMenuItem(
            value: false,
            child: Text(
              localization.private,
              style: _bodyStyle(themeData),
            ),
          ),
        ],
        value: publicValue,
        onChanged: (bool? value) {
          if (value != null) {
            setState(() {
              publicValue = value;
            });
          }
        },
      ),
    ));

    list.add(Container(
      margin: margin,
      padding: padding,
      child: DropdownButton<bool>(
        isExpanded: true,
        items: [
          DropdownMenuItem(
            value: true,
            child: Text(
              localization.open,
              style: _bodyStyle(themeData),
            ),
          ),
          DropdownMenuItem(
            value: false,
            child: Text(
              localization.closed,
              style: _bodyStyle(themeData),
            ),
          ),
        ],
        value: openValue,
        onChanged: (bool? value) {
          if (value != null) {
            setState(() {
              openValue = value;
            });
          }
        },
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
              padding: EdgeInsets.only(
                  top: mediaDataCache.padding.top + Base.basePadding),
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
    return null;
  }

  Future<void> pickPicture() async {
    var filepath = await pickImageAndUpload();
    if (StringUtil.isNotBlank(filepath)) {
      pictureController.text = filepath!;
    }
  }

  String getText(String? str) {
    return str ?? "";
  }

  void doSave() {
    GroupMetadata groupMetadata = GroupMetadata(
      groupIdentifier!.groupId,
      0,
      name: nameController.text,
      picture: pictureController.text,
      about: aboutController.text,
    );
    groupProvider.udpateMetadata(groupIdentifier!, groupMetadata);

    if (oldGroupMetadata != null) {
      bool updateStatus = false;
      if (oldGroupMetadata!.public != publicValue) {
        updateStatus = true;
      }
      if (oldGroupMetadata!.open != openValue) {
        updateStatus = true;
      }

      if (updateStatus) {
        groupProvider.editStatus(groupIdentifier!, publicValue, openValue);
      }
    }

    RouterUtil.back(context);
  }
}
