import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/util/app_logger.dart';
import 'package:nostrmo/utils/string_util.dart' as app_string_util;

class UserBanDialog extends StatefulWidget {
  final GroupIdentifier groupIdentifier;
  final String userPubkey;
  final String? userName;
  
  const UserBanDialog({
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
      builder: (context) => UserBanDialog(
        groupIdentifier: groupIdentifier,
        userPubkey: userPubkey,
        userName: userName,
      ),
    );
  }

  @override
  State<UserBanDialog> createState() => _UserBanDialogState();
}

class _UserBanDialogState extends State<UserBanDialog> {
  final AppLogger _logger = AppLogger();
  final TextEditingController _reasonController = TextEditingController();
  bool _sendNotification = true;
  bool _isPermanent = true;
  bool _isBanning = false;

  // Ban duration options
  final List<BanDurationOption> _durationOptions = [
    BanDurationOption(label: "1 hour", seconds: 3600),
    BanDurationOption(label: "1 day", seconds: 86400),
    BanDurationOption(label: "1 week", seconds: 604800),
    BanDurationOption(label: "1 month", seconds: 2592000),
    BanDurationOption(label: "3 months", seconds: 7776000),
    BanDurationOption(label: "6 months", seconds: 15552000),
    BanDurationOption(label: "1 year", seconds: 31536000),
  ];
  
  BanDurationOption? _selectedDuration;

  @override
  void initState() {
    super.initState();
    _selectedDuration = _durationOptions[1]; // Default to 1 day
  }
  
  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // Handle the user ban
  Future<void> _banUser() async {
    if (_isBanning) return;
    
    setState(() {
      _isBanning = true;
    });
    
    try {
      final String? reason = _reasonController.text.trim().isNotEmpty 
          ? _reasonController.text.trim() 
          : null;
      
      // Get ban duration (null for permanent bans)
      final int? duration = _isPermanent ? null : _selectedDuration?.seconds;
      
      _logger.i("Banning user ${widget.userPubkey.substring(0, 8)}... from group ${widget.groupIdentifier.groupId}",
          LogCategory.groups);
      
      final success = await groupProvider.banUser(
        widget.groupIdentifier,
        widget.userPubkey,
        reason: reason,
        duration: duration,
        sendNotification: _sendNotification,
      );
      
      if (mounted) {
        if (success) {
          _logger.i("User banned successfully", LogCategory.groups);
          Navigator.of(context).pop(true);
        } else {
          _logger.e("Failed to ban user", LogCategory.groups);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error banning user")),
          );
          setState(() {
            _isBanning = false;
          });
        }
      }
    } catch (e) {
      _logger.e("Error banning user: $e", LogCategory.groups);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error banning user")),
        );
        setState(() {
          _isBanning = false;
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
      title: Text("Ban User from Group"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Are you sure you want to ban $displayName from this group?",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: "Reason (Optional)",
                border: const OutlineInputBorder(),
                hintText: "Optional explanation for why this user is being banned...",
              ),
              maxLines: 3,
              maxLength: 200,
            ),
            const SizedBox(height: 16),
            
            // Ban duration options
            Text(
              "Ban Duration",
              style: theme.textTheme.titleSmall,
            ),
            
            // Permanent ban toggle
            SwitchListTile(
              title: Text("Permanent Ban"),
              subtitle: Text("User will remain banned indefinitely"),
              value: _isPermanent,
              onChanged: (value) {
                setState(() {
                  _isPermanent = value;
                });
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            
            // Temporary ban options (visible only when not permanent)
            if (!_isPermanent) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<BanDurationOption>(
                decoration: InputDecoration(
                  labelText: "Ban Duration",
                  border: OutlineInputBorder(),
                ),
                value: _selectedDuration,
                items: _durationOptions.map((option) {
                  return DropdownMenuItem<BanDurationOption>(
                    value: option,
                    child: Text(option.label),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDuration = value;
                  });
                },
              ),
            ],
            
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _sendNotification,
              onChanged: (value) {
                setState(() {
                  _sendNotification = value ?? true;
                });
              },
              title: Text("Send notification to user"),
              subtitle: Text("User will receive a message explaining their ban"),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isBanning ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isBanning ? null : _banUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isBanning
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text("Ban User"),
        ),
      ],
    );
  }
}

/// Helper class to represent a ban duration option
class BanDurationOption {
  final String label;
  final int seconds;
  
  BanDurationOption({required this.label, required this.seconds});
} 