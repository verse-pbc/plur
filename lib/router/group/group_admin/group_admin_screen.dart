import 'package:bot_toast/bot_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostr_sdk/nip29/group_metadata.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:provider/provider.dart';

import '../../../component/appbar_back_btn_widget.dart';
import '../../../component/group/group_avatar_widget.dart';
import '../../../consts/router_path.dart';
import '../../../generated/l10n.dart';
import '../../../provider/group_provider.dart';
import '../../../provider/uploader.dart';
import '../../../util/router_util.dart';

class GroupAdminScreen extends StatefulWidget {
  const GroupAdminScreen({super.key});

  @override
  State<GroupAdminScreen> createState() => _GroupAdminScreenState();
}

class _GroupAdminScreenState extends State<GroupAdminScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _pictureUrl;
  var _hasChanges = false;
  var _isSaving = false;
  var _isUploading = false;

  @override
  void initState() {
    _nameController.addListener(_checkForChanges);
    _descriptionController.addListener(_checkForChanges);

    super.initState();
  }

  @override
  void dispose() {
    _nameController.removeListener(_checkForChanges);
    _descriptionController.removeListener(_checkForChanges);
    _nameController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final groupId = context.read<GroupIdentifier>();
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final metadata = groupProvider.getMetadata(groupId);

    _nameController.text = metadata?.name ?? "";
    _descriptionController.text = metadata?.about ?? "";
    _pictureUrl = metadata?.picture;
    setState(() => _hasChanges = false);
  }

  void _checkForChanges() {
    final groupId = context.read<GroupIdentifier>();
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final metadata = groupProvider.getMetadata(groupId);

    final newHasChanges = _nameController.text != metadata?.name ||
        _descriptionController.text != metadata?.about ||
        _pictureUrl != metadata?.picture;

    if (_hasChanges != newHasChanges) {
      setState(() => _hasChanges = newHasChanges);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final localization = S.of(context);

    const double cornerRadius = 8;
    const borderRadius = BorderRadius.all(Radius.circular(cornerRadius));
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide:
        BorderSide(color: themeData.customColors.secondaryForegroundColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide:
        BorderSide(color: themeData.customColors.secondaryForegroundColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
            color: themeData.customColors.secondaryForegroundColor, width: 2),
      ),
      labelStyle:
          TextStyle(color: themeData.customColors.primaryForegroundColor),
    );

    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        title: Text(
          localization.Admin_Panel,
          style: TextStyle(
            color: themeData.customColors.primaryForegroundColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isSaving)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    themeData.customColors.accentColor,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _hasChanges ? _save : null,
              style: const ButtonStyle(),
              child: Text(
                localization.Save,
                style: TextStyle(
                  color: _hasChanges
                      ? themeData.customColors.accentColor
                      : Colors.grey,
                  fontSize: 18,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 26),
            Stack(
              alignment: Alignment.center,
              children: [
                GroupAvatar(imageUrl: _pictureUrl),
                if (_isUploading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
            TextButton(
              onPressed: _updateImage,
              style: TextButton.styleFrom(
                textStyle: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                ),
                foregroundColor: themeData.customColors.accentColor,
              ),
              child: Text(localization.Update_Image),
            ),
            const SizedBox(height: 44),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextFormField(
                controller: _nameController,
                decoration: inputDecoration.copyWith(
                  labelText: localization.Community_Name,
                  hintText: localization.Enter_Community_Name,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextFormField(
                controller: _descriptionController,
                decoration: inputDecoration.copyWith(
                  labelText: localization.Description,
                  hintText: localization.Enter_Community_Description,
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                minLines: 5,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cornerRadius),
              ),
              clipBehavior: Clip.antiAlias,
              // Ensures the InkWell respects rounded corners
              child: Column(
                children: [
                  _NavigationRow(
                    title: localization.Members,
                    onTap: () {
                      final groupId = context.read<GroupIdentifier>();
                      RouterUtil.router(
                          context, RouterPath.GROUP_MEMBERS, groupId);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateImage() async {
    try {
      final files = await Uploader.pickFiles(
        context,
        type: FileType.image,
        allowMultiple: false,
      );

      final firstFile = files.firstOrNull;
      if (firstFile == null) return;

      setState(() => _isUploading = true);
      final remoteUrl = await Uploader.upload(firstFile);
      if (!mounted) return;

      if (remoteUrl == null) {
        throw S.of(context).Image_upload_failed;
      }
      setState(() => _pictureUrl = remoteUrl);
      _checkForChanges();
    } catch (e) {
      BotToast.showText(text: e.toString());
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _save() async {
    setState(() => _isSaving = true);

    final groupIdentifier = context.read<GroupIdentifier>();
    GroupMetadata groupMetadata = GroupMetadata(
      groupIdentifier.groupId,
      0,
      name: _nameController.text,
      picture: _pictureUrl,
      about: _descriptionController.text,
    );

    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      await groupProvider.updateMetadata(groupIdentifier, groupMetadata);

      if (!mounted) return;
      RouterUtil.back(context);
    } catch (e) {
      BotToast.showText(text: e.toString());
    } finally {
      setState(() => _isSaving = false);
    }
  }
}

class _NavigationRow extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _NavigationRow({
    Key? key,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: themeData.customColors.feedBgColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white54,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
