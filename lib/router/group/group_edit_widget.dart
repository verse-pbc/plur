import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/appbar_back_btn_widget.dart';
import 'package:flutter/services.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';
import 'package:bot_toast/bot_toast.dart';

import '../../component/appbar_bottom_border.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../main.dart';

import '../../provider/uploader.dart';
import '../../util/theme_util.dart';

class GroupEditWidget extends StatefulWidget {
  const GroupEditWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _GroupEditWidgetState();
  }
}

class _GroupEditWidgetState extends State<GroupEditWidget> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController pictureController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();

  GroupIdentifier? groupIdentifier;
  bool publicValue = false;
  bool openValue = false;
  bool adminOnlyPostsValue = false;
  GroupMetadata? oldGroupMetadata;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    var arg = RouterUtil.routerArgs(context);
    if (arg == null || arg is! GroupIdentifier) {
      RouterUtil.back(context);
      return Container();
    }
    groupIdentifier = arg;
    
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final localization = S.of(context);
    final groupProvider = Provider.of<GroupProvider>(context);

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
        if (groupMetadata.adminOnlyPosts != null) {
          adminOnlyPostsValue = groupMetadata.adminOnlyPosts!;
        }
      }
    }
    oldGroupMetadata = groupMetadata;

    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        title: Text(
          localization.Edit_Group,
          style: TextStyle(
            color: customColors.primaryForegroundColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: const AppBarBottomBorder(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: Base.maxScreenWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Read-only information section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: customColors.feedBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localization.Group_Info,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: customColors.primaryForegroundColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          context: context,
                          label: localization.Relay,
                          value: groupIdentifier!.host,
                          isImportant: true,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context: context,
                          label: localization.GroupId,
                          value: groupIdentifier!.groupId,
                          isImportant: true,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Editable fields
                  Text(
                    localization.Edit_Details,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: customColors.primaryForegroundColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Community name field
                  _buildTextField(
                    context: context,
                    controller: nameController,
                    label: localization.Community_Name,
                    hint: localization.Enter_Community_Name,
                    maxLength: 50,
                  ),
                  const SizedBox(height: 16),
                  
                  // Picture field with image preview
                  _buildImageField(
                    context: context,
                    controller: pictureController,
                    label: localization.Picture,
                    onTap: pickPicture,
                  ),
                  const SizedBox(height: 16),
                  
                  // About field
                  _buildTextField(
                    context: context,
                    controller: aboutController,
                    label: localization.Description,
                    hint: localization.Enter_Community_Description,
                    maxLines: 5,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 24),
                  
                  // Group settings section
                  Text(
                    localization.Settings,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: customColors.primaryForegroundColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Privacy toggle
                  _buildSwitchTile(
                    context: context,
                    title: localization.public,
                    subtitle: publicValue 
                        ? localization.Group_Public_Description 
                        : localization.Group_Private_Description,
                    value: publicValue,
                    onChanged: (value) {
                      setState(() {
                        publicValue = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  
                  // Access toggle
                  _buildSwitchTile(
                    context: context,
                    title: localization.open,
                    subtitle: openValue 
                        ? localization.Group_Open_Description 
                        : localization.Group_Closed_Description,
                    value: openValue,
                    onChanged: (value) {
                      setState(() {
                        openValue = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Admin-only posts toggle
                  _buildSwitchTile(
                    context: context,
                    title: localization.admin_only_posts,
                    subtitle: adminOnlyPostsValue 
                        ? localization.Group_AdminOnly_Description 
                        : localization.Group_AllMembers_Description,
                    value: adminOnlyPostsValue,
                    onChanged: (value) {
                      setState(() {
                        adminOnlyPostsValue = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Save button
                  Center(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : doSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: customColors.accentColor,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        localization.Save,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: customColors.buttonTextColor,
                        ),
                      ),
                    ),
                  ),
                  
                  // Media notice
                  const SizedBox(height: 16),
                  Text(
                    localization.All_media_public,
                    style: TextStyle(
                      fontSize: 12,
                      color: customColors.secondaryForegroundColor,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow({
    required BuildContext context,
    required String label,
    required String value,
    bool isImportant = false,
  }) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: customColors.secondaryForegroundColor,
              ),
            ),
            if (isImportant) ...[
              const SizedBox(width: 4),
              Text(
                '(cannot be changed)',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: customColors.dimmedColor,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: customColors.primaryForegroundColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.copy,
                color: customColors.accentColor,
                size: 20,
              ),
              onPressed: () {
                _copyToClipboard(value);
              },
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    int? maxLength,
  }) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: customColors.secondaryForegroundColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: customColors.dimmedColor,
            ),
            filled: true,
            fillColor: customColors.feedBgColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            counterStyle: TextStyle(
              color: customColors.dimmedColor,
            ),
          ),
          style: TextStyle(
            color: customColors.primaryForegroundColor,
          ),
        ),
      ],
    );
  }
  
  Widget _buildImageField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final hasImage = controller.text.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: customColors.secondaryForegroundColor,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: customColors.feedBgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: customColors.separatorColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: hasImage
                ? _buildImagePreview(controller.text)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 32,
                        color: customColors.accentColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        S.of(context).Update_Image,
                        style: TextStyle(
                          color: customColors.accentColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (hasImage) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  controller.text,
                  style: TextStyle(
                    fontSize: 12,
                    color: customColors.dimmedColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    controller.clear();
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    S.of(context).Remove,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[300],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  Widget _buildImagePreview(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.grey[400],
              size: 32,
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: customColors.feedBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: customColors.primaryForegroundColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: customColors.secondaryForegroundColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: customColors.accentColor,
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
      setState(() {
        isLoading = true;
      });
      
      try {
        final uploadedFile = await Uploader.upload(
          filepath!,
          imageService: settingsProvider.imageService,
        );
        return uploadedFile;
      } catch (e) {
        BotToast.showText(text: S.of(context).Image_upload_failed);
        return null;
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
    return null;
  }

  Future<void> pickPicture() async {
    var filepath = await pickImageAndUpload();
    if (StringUtil.isNotBlank(filepath)) {
      setState(() {
        pictureController.text = filepath!;
      });
    }
  }

  String getText(String? str) {
    return str ?? "";
  }
  
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    BotToast.showText(text: S.of(context).Copy_success);
  }

  void doSave() {
    if (nameController.text.trim().isEmpty) {
      BotToast.showText(text: S.of(context).Community_Name_Required);
      return;
    }
    
    setState(() {
      isLoading = true;
    });

    try {
      GroupMetadata groupMetadata = GroupMetadata(
        groupIdentifier!.groupId,
        0,
        name: nameController.text.trim(),
        picture: pictureController.text.trim(),
        about: aboutController.text.trim(),
      );
      groupProvider.updateMetadata(groupIdentifier!, groupMetadata);

      if (oldGroupMetadata != null) {
        bool updateStatus = false;
        if (oldGroupMetadata!.public != publicValue) {
          updateStatus = true;
        }
        if (oldGroupMetadata!.open != openValue) {
          updateStatus = true;
        }
        if (oldGroupMetadata!.adminOnlyPosts != adminOnlyPostsValue) {
          updateStatus = true;
        }

        if (updateStatus) {
          groupProvider.editStatus(groupIdentifier!, publicValue, openValue, adminOnlyPostsValue);
        }
      }
      
      BotToast.showText(text: S.of(context).Changes_saved);
      RouterUtil.back(context);
    } catch (e) {
      BotToast.showText(text: S.of(context).Save_error);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}