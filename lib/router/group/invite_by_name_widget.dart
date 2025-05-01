import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/provider/contact_list_provider.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/provider/user_provider.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/direct_invite_util.dart';
import 'package:nostrmo/component/appbar_back_btn_widget.dart';
import 'package:nostrmo/component/appbar_bottom_border.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

/// Widget for inviting people by name to a group
class InviteByNameWidget extends StatefulWidget {
  final GroupIdentifier? groupIdentifier;

  const InviteByNameWidget({
    super.key,
    this.groupIdentifier,
  });

  @override
  State<InviteByNameWidget> createState() => _InviteByNameWidgetState();
}

class _InviteByNameWidgetState extends State<InviteByNameWidget> {
  // Helper widget to handle avatar display with proper error handling
  Widget _buildUserAvatar(BuildContext context, String pubkey) {
    final user = Provider.of<UserProvider>(context, listen: false).getUserMeta(pubkey);
    
    // If no profile picture or no user data, show default icon
    if (user?.picture == null || user!.picture!.isEmpty) {
      return Icon(Icons.person, color: Theme.of(context).customColors.secondaryForegroundColor);
    }
    
    // Use ClipOval to ensure the image stays within bounds even during loading/errors
    return ClipOval(
      child: Container(
        width: 40,
        height: 40,
        color: Theme.of(context).customColors.feedBgColor,
        child: Builder(
          builder: (context) {
            // Use try-catch to handle any image loading issues
            try {
              return Image.network(
                user.picture!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // On error, show the default icon
                  return Icon(Icons.person, color: Theme.of(context).customColors.secondaryForegroundColor);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  // Show subtle loading indicator
                  return Container(
                    width: 40,
                    height: 40,
                    color: Theme.of(context).customColors.feedBgColor,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).customColors.secondaryForegroundColor.withAlpha(100),
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              );
            } catch (e) {
              // Catch any unexpected errors in image loading and show default
              return Icon(Icons.person, color: Theme.of(context).customColors.secondaryForegroundColor);
            }
          }
        ),
      ),
    );
  }
  final _log = Logger('InviteByNameWidget');
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormFieldState> _searchFormKey = GlobalKey<FormFieldState>();
  
  String _searchQuery = '';
  List<String> _searchResults = [];
  String? _selectedUser;
  bool _isLoading = false;
  bool _isSending = false;
  String _role = 'member';
  bool _isReusable = true;
  DateTime? _expiryDate;
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      _selectedUser = null;
    });
    
    if (_searchQuery.isNotEmpty) {
      _searchUsers();
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }
  
  Future<void> _searchUsers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final contactListProvider = Provider.of<ContactListProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // First search in contacts
      final contacts = contactListProvider.getContactPubkeys();
      
      // Filter contacts by name or pubkey matching search query
      final filteredContacts = contacts.where((pubkey) {
        final user = userProvider.getUserMeta(pubkey);
        if (user == null) return false;
        
        final name = user.getName().toLowerCase();
        final lowercaseQuery = _searchQuery.toLowerCase();
        
        return name.contains(lowercaseQuery) || 
               pubkey.toLowerCase().contains(lowercaseQuery);
      }).toList();
      
      setState(() {
        _searchResults = filteredContacts;
        _isLoading = false;
      });
    } catch (e) {
      _log.severe('Error searching users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _selectUser(String pubkey) {
    setState(() {
      _selectedUser = pubkey;
    });
  }
  
  Future<void> _sendInvite() async {
    if (_selectedUser == null) return;
    
    setState(() {
      _isSending = true;
    });
    
    final cancelFunc = BotToast.showLoading();
    
    try {
      final groupId = widget.groupIdentifier;
      if (groupId == null) {
        BotToast.showText(text: S.of(context).groupNotFound);
        return;
      }
      
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final groupMetadata = groupProvider.getMetadata(groupId);
      
      final success = await DirectInviteUtil.sendDirectInvite(
        groupIdentifier: groupId,
        recipientPubkey: _selectedUser!,
        groupName: groupMetadata?.name ?? S.of(context).group,
        avatar: groupMetadata?.picture,
        role: _role,
        expiresAt: _expiryDate,
        reusable: _isReusable,
      );
      
      if (success) {
        BotToast.showText(text: S.of(context).inviteSent);
        RouterUtil.back(context);
      } else {
        BotToast.showText(text: "Failed to send invite");
      }
    } catch (e) {
      _log.severe('Error sending invite: $e');
      BotToast.showText(text: "${S.of(context).error}: $e");
    } finally {
      cancelFunc.call();
      setState(() {
        _isSending = false;
      });
    }
  }
  
  Widget _buildUserSearchField() {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    return TextFormField(
      key: _searchFormKey,
      controller: _searchController,
      decoration: InputDecoration(
        hintText: S.of(context).searchContacts,
        prefixIcon: Icon(Icons.search, color: customColors.secondaryForegroundColor),
        suffix: _searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: customColors.secondaryForegroundColor),
                onPressed: () {
                  _searchController.clear();
                },
              )
            : null,
        filled: true,
        fillColor: customColors.feedBgColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: customColors.accentColor, width: 1),
        ),
      ),
      style: TextStyle(
        color: customColors.primaryForegroundColor,
        fontSize: 16,
      ),
      cursorColor: customColors.accentColor,
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_searchQuery.isEmpty) {
      return Center(
        child: Text(
          S.of(context).searchContactsToInvite,
          style: TextStyle(
            color: Theme.of(context).customColors.secondaryForegroundColor,
          ),
        ),
      );
    }
    
    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          S.of(context).noUsersFound,
          style: TextStyle(
            color: Theme.of(context).customColors.secondaryForegroundColor,
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final pubkey = _searchResults[index];
        final isSelected = _selectedUser == pubkey;
        
        return InkWell(
          onTap: () => _selectUser(pubkey),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected 
                ? Theme.of(context).customColors.accentColor.withAlpha(26)
                : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Just the user avatar
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context).customColors.feedBgColor,
                          child: _buildUserAvatar(context, pubkey),
                        ),
                      ),
                      // User name with clean background
                      Expanded(
                        child: Text(
                          Provider.of<UserProvider>(context, listen: false)
                                  .getUserMeta(pubkey)?.getName() ?? pubkey.substring(0, 8),
                          style: TextStyle(
                            color: Theme.of(context).customColors.primaryForegroundColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).customColors.accentColor,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildRoleDropdown() {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    return DropdownButtonFormField<String>(
      value: _role,
      decoration: InputDecoration(
        labelText: S.of(context).role,
        filled: true,
        fillColor: customColors.feedBgColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      style: TextStyle(
        color: customColors.primaryForegroundColor,
        fontSize: 16,
      ),
      dropdownColor: customColors.feedBgColor,
      items: [
        DropdownMenuItem(
          value: 'member',
          child: Text(S.of(context).member),
        ),
        DropdownMenuItem(
          value: 'admin',
          child: Text(S.of(context).admin),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _role = value;
          });
        }
      },
    );
  }
  
  Widget _buildExpiryDatePicker() {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    return DropdownButtonFormField<String>(
      value: _expiryDate == null ? 'never' : 'custom',
      decoration: InputDecoration(
        labelText: S.of(context).expires,
        filled: true,
        fillColor: customColors.feedBgColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      style: TextStyle(
        color: customColors.primaryForegroundColor,
        fontSize: 16,
      ),
      dropdownColor: customColors.feedBgColor,
      items: [
        DropdownMenuItem(
          value: 'never',
          child: Text(S.of(context).never),
        ),
        DropdownMenuItem(
          value: '1d',
          child: Text(S.of(context).oneDay),
        ),
        DropdownMenuItem(
          value: '7d',
          child: Text(S.of(context).oneWeek),
        ),
        DropdownMenuItem(
          value: '30d',
          child: Text(S.of(context).oneMonth),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            switch (value) {
              case 'never':
                _expiryDate = null;
                break;
              case '1d':
                _expiryDate = DateTime.now().add(const Duration(days: 1));
                break;
              case '7d':
                _expiryDate = DateTime.now().add(const Duration(days: 7));
                break;
              case '30d':
                _expiryDate = DateTime.now().add(const Duration(days: 30));
                break;
            }
          });
        }
      },
    );
  }
  
  Widget _buildReusableToggle() {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: customColors.feedBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            S.of(context).reusable,
            style: TextStyle(
              color: customColors.primaryForegroundColor,
              fontSize: 16,
            ),
          ),
          Switch(
            value: _isReusable,
            onChanged: (value) {
              setState(() {
                _isReusable = value;
              });
            },
            activeColor: customColors.accentColor,
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final localization = S.of(context);
    
    final groupId = widget.groupIdentifier ?? RouterUtil.routerArgs(context);
    if (groupId == null || groupId is! GroupIdentifier) {
      RouterUtil.back(context);
      return Container();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localization.inviteByName,
          style: TextStyle(
            color: customColors.primaryForegroundColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        leading: const AppbarBackBtnWidget(),
        bottom: const AppBarBottomBorder(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildUserSearchField(),
            ),
            
            // Search results
            Expanded(
              child: _buildSearchResults(),
            ),
            
            // Invite configuration (only shown when a user is selected)
            if (_selectedUser != null)
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildRoleDropdown(),
                    const SizedBox(height: 16),
                    _buildExpiryDatePicker(),
                    const SizedBox(height: 16),
                    _buildReusableToggle(),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSending ? null : _sendInvite,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: customColors.accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSending
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  customColors.buttonTextColor,
                                ),
                              ),
                            )
                          : Text(
                              localization.sendInvite,
                              style: TextStyle(
                                color: customColors.buttonTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}