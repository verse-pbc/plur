import 'package:bot_toast/bot_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostr_sdk/nip29/group_metadata.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:provider/provider.dart';

import '../../../component/group/group_avatar_widget.dart';
import '../../../consts/router_path.dart';
import '../../../generated/l10n.dart';
import '../../../provider/group_provider.dart';
import '../../../provider/uploader.dart';
import '../../../util/router_util.dart';
import '../../../util/app_logger.dart';
import '../../../main.dart'; // Import main.dart for the nostr global variable

class GroupAdminScreen extends StatefulWidget {
  final GroupIdentifier groupId;

  const GroupAdminScreen({super.key, required this.groupId});

  @override
  State<GroupAdminScreen> createState() => _GroupAdminScreenState();
}

class _GroupAdminScreenState extends State<GroupAdminScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  GroupMetadata? groupMetadata;
  AppLogger logger = AppLogger();
  late final GroupProvider groupProvider;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _pictureUrl;
  var _hasChanges = false;
  var _isSaving = false;
  var _isUploading = false;
  
  @override
  void initState() {
    super.initState();
    
    // Force admin access to ensure consistent behavior
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final myPubkey = nostr?.publicKey;
      if (myPubkey != null) {
        groupProvider = Provider.of<GroupProvider>(context, listen: false);
        groupProvider.forceAdminForGroup(widget.groupId, myPubkey);
        logger.i("Admin screen: Forced admin status for consistent behavior", 
            null, null, LogCategory.groups);
      }
      _initializeData();
    });

    _nameController.addListener(_checkForChanges);
    _descriptionController.addListener(_checkForChanges);
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
        leading: TextButton(
          onPressed: _cancel,
          child: Text(
            localization.cancel,
            style: TextStyle(
              color: themeData.customColors.accentColor,
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.visible,
            maxLines: 1,
            softWrap: false,
          ),
        ),
        title: Text(
          localization.edit,
          style: TextStyle(
            color: themeData.customColors.primaryForegroundColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
                localization.save,
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
              child: Text(localization.updateImage),
            ),
            const SizedBox(height: 44),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextFormField(
                controller: _nameController,
                decoration: inputDecoration.copyWith(
                  labelText: localization.communityName,
                  hintText: localization.enterCommunityName,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextFormField(
                controller: _descriptionController,
                decoration: inputDecoration.copyWith(
                  labelText: localization.description,
                  hintText: localization.enterCommunityDescription,
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
                    title: localization.members,
                    onTap: () {
                      final groupId = context.read<GroupIdentifier>();
                      RouterUtil.router(
                          context, RouterPath.groupMembers, groupId);
                    },
                  ),
                  _NavigationRow(
                    title: localization.communityGuidelines,
                    onTap: () {
                      final groupId = context.read<GroupIdentifier>();
                      RouterUtil.router(
                          context, RouterPath.communityGuidelines, groupId);
                    },
                  ),
                  _NavigationRow(
                    title: "Report Management",
                    onTap: () {
                      final groupId = context.read<GroupIdentifier>();
                      RouterUtil.router(
                          context, RouterPath.reportManagement, groupId);
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
        final errorMessage = S.of(context).imageUploadFailed;
        throw Exception(errorMessage);
      }
      setState(() => _pictureUrl = remoteUrl);
      _checkForChanges();
    } catch (e) {
      BotToast.showText(text: e.toString());
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _cancel() async {
    final themeData = Theme.of(context);
    final localization = S.of(context);
    if (_hasChanges) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (context) => Theme(
          data: themeData,
          child: AlertDialog(
            backgroundColor: themeData.colorScheme.surface,
            content: Text(
              localization.confirmDiscard,
              style: TextStyle(
                color: themeData.colorScheme.onSurface,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(localization.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(localization.discard),
              ),
            ],
          ),
        ),
      );
      if (!mounted) return;

      if (shouldDiscard == true) {
        Navigator.pop(context, false);
      }
    } else {
      Navigator.pop(context, false);
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

  void _initializeData() {
    _nameController.addListener(_checkForChanges);
    _descriptionController.addListener(_checkForChanges);
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
              style: TextStyle(
                color: themeData.customColors.primaryForegroundColor,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: themeData.customColors.secondaryForegroundColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
