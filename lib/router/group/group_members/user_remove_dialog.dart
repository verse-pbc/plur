import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/util/app_logger.dart';
import 'package:nostrmo/utils/string_util.dart' as app_string_util;

class UserRemoveDialog extends StatefulWidget {
  final GroupIdentifier groupIdentifier;
  final String userPubkey;
  final String? userName;
  
  const UserRemoveDialog({
    super.key,
    required this.groupIdentifier,
    required this.userPubkey,
    this.userName,
  });

  static Future<bool?> show(
    BuildContext context,
    GroupIdentifier groupIdentifier,
    String userPubkey,
    {String? userName}
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => UserRemoveDialog(
        groupIdentifier: groupIdentifier,
        userPubkey: userPubkey,
        userName: userName,
      ),
    );
  }

  @override
  State<UserRemoveDialog> createState() => _UserRemoveDialogState();
}

class _UserRemoveDialogState extends State<UserRemoveDialog> {
  final AppLogger _logger = AppLogger();
  final TextEditingController _reasonController = TextEditingController();
  bool _sendNotification = true;
  bool _isRemoving = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // Handle the user removal
  Future<void> _removeUser() async {
    if (_isRemoving) return;
    
    setState(() {
      _isRemoving = true;
    });
    
    try {
      final String? reason = _reasonController.text.trim().isNotEmpty 
          ? _reasonController.text.trim() 
          : null;
      
      _logger.i("Removing user ${widget.userPubkey.substring(0, 8)}... from group ${widget.groupIdentifier.groupId}",
          LogCategory.groups);
      
      final success = await groupProvider.removeUser(
        widget.groupIdentifier,
        widget.userPubkey,
        reason: reason,
        sendNotification: _sendNotification,
      );
      
      if (mounted) {
        if (success) {
          _logger.i("User removed successfully", LogCategory.groups);
          Navigator.of(context).pop(true);
        } else {
          _logger.e("Failed to remove user", LogCategory.groups);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error removing user")),
          );
          setState(() {
            _isRemoving = false;
          });
        }
      }
    } catch (e) {
      _logger.e("Error removing user: $e", LogCategory.groups);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error removing user")),
        );
        setState(() {
          _isRemoving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = S.of(context);
    
    final displayName = widget.userName ?? 
                      app_string_util.StringUtil.formatPublicKey(widget.userPubkey);
    
    return AlertDialog(
      title: Text("Remove User from Group"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Are you sure you want to remove $displayName from this group?",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: "Reason (Optional)",
                border: const OutlineInputBorder(),
                hintText: "Optional explanation for why this user is being removed...",
              ),
              maxLines: 3,
              maxLength: 200,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _sendNotification,
              onChanged: (value) {
                setState(() {
                  _sendNotification = value ?? true;
                });
              },
              title: Text("Send notification to user"),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isRemoving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isRemoving ? null : _removeUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isRemoving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text("Remove User"),
        ),
      ],
    );
  }
} 