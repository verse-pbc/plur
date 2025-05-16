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
import '../../theme/app_colors.dart';

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
      }
    }
    oldGroupMetadata = groupMetadata;

    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        title: Text(
          localization.editGroup,
          style: TextStyle(
            color: context.colors.primaryText,
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
                      color: context.colors.feedBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localization.groupInfo,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.colors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          context: context,
                          label: localization.relay,
                          value: groupIdentifier!.host,
                          isImportant: true,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context: context,
                          label: localization.groupId,
                          value: groupIdentifier!.groupId,
                          isImportant: true,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Editable fields
                  Text(
                    localization.editDetails,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.colors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Community name field
                  _buildTextField(
                    context: context,
                    controller: nameController,
                    label: localization.communityNameHeader,
                    hint: localization.enterCommunityName,
                    maxLength: 50,
                  ),
                  const SizedBox(height: 16),
                  
                  // Picture field with image preview
                  _buildImageField(
                    context: context,
                    controller: pictureController,
                    label: localization.picture,
                    onTap: pickPicture,
                  ),
                  const SizedBox(height: 16),
                  
                  // About field
                  _buildTextField(
                    context: context,
                    controller: aboutController,
                    label: localization.description,
                    hint: localization.enterCommunityDescription,
                    maxLines: 5,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 24),
                  
                  // Group settings section
                  Text(
                    localization.settings,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.colors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Privacy toggle
                  _buildSwitchTile(
                    context: context,
                    title: localization.publicType,
                    subtitle: publicValue 
                        ? localization.groupPublicDescription 
                        : localization.groupPrivateDescription,
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
                        ? localization.groupOpenDescription 
                        : localization.groupClosedDescription,
                    value: openValue,
                    onChanged: (value) {
                      setState(() {
                        openValue = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Save button
                  Center(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : doSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.accent,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        localization.save,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.colors.buttonText,
                        ),
                      ),
                    ),
                  ),
                  
                  // Media notice
                  const SizedBox(height: 16),
                  Text(
                    localization.allMediaPublic,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.secondaryText,
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
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: context.colors.secondaryText,
              ),
            ),
            if (isImportant) ...[
              const SizedBox(width: 4),
              Text(
                '(cannot be changed)',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: context.colors.dimmed,
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
                  color: context.colors.primaryText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.copy,
                color: context.colors.accent,
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
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: context.colors.secondaryText,
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
              color: context.colors.dimmed,
            ),
            filled: true,
            fillColor: context.colors.feedBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            counterStyle: TextStyle(
              color: context.colors.dimmed,
            ),
          ),
          style: TextStyle(
            color: context.colors.primaryText,
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
    final hasImage = controller.text.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: context.colors.secondaryText,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.colors.feedBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: context.colors.divider.withAlpha(77),
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
                        color: context.colors.accent,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        S.of(context).updateImage,
                        style: TextStyle(
                          color: context.colors.accent,
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
                    color: context.colors.dimmed,
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
                    S.of(context).remove,
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
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.feedBackground,
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
                    color: context.colors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: context.colors.accent,
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
        BotToast.showText(text: S.of(context).imageUploadFailed);
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
    BotToast.showText(text: S.of(context).copySuccess);
  }

  void doSave() {
    if (nameController.text.trim().isEmpty) {
      BotToast.showText(text: S.of(context).communityNameRequired);
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

        if (updateStatus) {
          groupProvider.editStatus(groupIdentifier!, publicValue, openValue);
        }
      }
      
      BotToast.showText(text: S.of(context).changesSaved);
      RouterUtil.back(context);
    } catch (e) {
      BotToast.showText(text: S.of(context).saveError);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}