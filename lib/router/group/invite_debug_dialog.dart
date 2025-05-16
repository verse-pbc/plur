import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/theme/app_colors.dart';
import 'package:nostrmo/util/group_invite_link_util.dart';
import 'package:bot_toast/bot_toast.dart';
import 'dart:developer' as dev;

/// Debug dialog for testing invite link generation and format
/// This allows entering custom values for groupId, code, and relay
class InviteDebugDialog extends StatefulWidget {
  const InviteDebugDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (_) {
        return const InviteDebugDialog();
      },
    );
  }

  @override
  State<InviteDebugDialog> createState() => _InviteDebugDialogState();
}

class _InviteDebugDialogState extends State<InviteDebugDialog> {
  final TextEditingController _groupIdController = TextEditingController(text: '1234abcd');
  final TextEditingController _codeController = TextEditingController(text: 'ABC123XY');
  final TextEditingController _relayController = TextEditingController(text: 'wss://communities.nos.social');
  
  String _standardInviteUrl = '';
  String _directProtocolUrl = '';
  String _universalLinkUrl = '';
  String _webInviteUrl = '';
  String _shortUrlInviteUrl = '';
  String _apiResponse = 'Not tested';
  
  @override
  void initState() {
    super.initState();
    _generateLinks();
  }
  
  @override
  void dispose() {
    _groupIdController.dispose();
    _codeController.dispose();
    _relayController.dispose();
    super.dispose();
  }
  
  void _generateLinks() {
    final String groupId = _groupIdController.text;
    final String code = _codeController.text;
    final String relay = _relayController.text;
    
    // Generate various link formats for comparison
    setState(() {
      _standardInviteUrl = GroupInviteLinkUtil.generateStandardInviteUrl(code);
      _directProtocolUrl = GroupInviteLinkUtil.generateDirectProtocolUrl(groupId, code, relay);
      _universalLinkUrl = GroupInviteLinkUtil.generateUniversalLink(groupId, code, relay);
      _webInviteUrl = GroupInviteLinkUtil.generateWebInviteUrl(code);
      
      // Short URL would require API access, but show the format
      _shortUrlInviteUrl = "https://chus.me/j/[shortened version of $code]";
    });
    
    dev.log('Generated standard invite URL: $_standardInviteUrl', name: 'InviteDebug');
    dev.log('Generated direct protocol URL: $_directProtocolUrl', name: 'InviteDebug');
    dev.log('Generated universal link URL: $_universalLinkUrl', name: 'InviteDebug');
    dev.log('Generated web invite URL: $_webInviteUrl', name: 'InviteDebug');
  }
  
  Future<void> _testApiRegistration() async {
    setState(() {
      _apiResponse = 'Testing API...';
    });
    
    try {
      final result = await GroupInviteLinkUtil.registerStandardInvite(
        _groupIdController.text, 
        _relayController.text
      );
      
      setState(() {
        if (result != null) {
          _apiResponse = '✅ Success: $result';
        } else {
          _apiResponse = '❌ API returned null';
        }
      });
    } catch (e) {
      setState(() {
        _apiResponse = '❌ Error: $e';
      });
      dev.log('API Error: $e', name: 'InviteDebug');
    }
  }
  
  Widget _buildLinkRow(String label, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  url,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: url));
                        BotToast.showText(text: 'Copied to clipboard');
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Copy', style: TextStyle(fontSize: 10)),
                    ),
                    TextButton(
                      onPressed: () {
                        BotToast.showText(text: 'Would open in browser: $url');
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Test Open', style: TextStyle(fontSize: 10)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    
    return Scaffold(
      backgroundColor: (themeData.textTheme.bodyMedium!.color ?? Colors.black).withAlpha(51),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => RouterUtil.back(context),
            child: Container(color: Colors.black54),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.feedBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bug_report, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Invite Link Debug Tool',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.colors.primaryText,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: context.colors.primaryText,
                          ),
                          onPressed: () => RouterUtil.back(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Input fields
                    TextField(
                      controller: _groupIdController,
                      decoration: InputDecoration(
                        labelText: 'Group ID',
                        labelStyle: TextStyle(color: context.colors.secondaryText),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      style: TextStyle(color: context.colors.primaryText),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: 'Invite Code',
                        labelStyle: TextStyle(color: context.colors.secondaryText),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      style: TextStyle(color: context.colors.primaryText),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _relayController,
                      decoration: InputDecoration(
                        labelText: 'Relay URL',
                        labelStyle: TextStyle(color: context.colors.secondaryText),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      style: TextStyle(color: context.colors.primaryText),
                    ),
                    const SizedBox(height: 16),
                    
                    ElevatedButton(
                      onPressed: _generateLinks,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.accent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Generate Links'),
                    ),
                    
                    const SizedBox(height: 16),
                    const Divider(),
                    
                    // Generated links section
                    const Text(
                      'Generated Links:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    _buildLinkRow('Standard:', _standardInviteUrl),
                    _buildLinkRow('Direct Protocol:', _directProtocolUrl),
                    _buildLinkRow('Universal:', _universalLinkUrl),
                    _buildLinkRow('Web Invite:', _webInviteUrl),
                    _buildLinkRow('Short URL:', _shortUrlInviteUrl),
                    
                    const SizedBox(height: 16),
                    const Divider(),
                    
                    // API testing section
                    Row(
                      children: [
                        const Text(
                          'API Status:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _apiResponse,
                            style: TextStyle(
                              fontSize: 12,
                              color: _apiResponse.contains('✅') 
                                  ? Colors.green 
                                  : (_apiResponse.contains('❌') ? Colors.red : Colors.blue),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _testApiRegistration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Test API Registration'),
                    ),
                    
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => RouterUtil.back(context),
                          child: Text(
                            'Close',
                            style: TextStyle(
                              color: context.colors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 