import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/nip05_valid_widget.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../data/user.dart';
import '../../main.dart';
import '../../provider/group_provider.dart';
import '../../provider/user_provider.dart';
import '../../util/router_util.dart';
import 'search_mention_widget.dart';

class SearchMentionUserWidget extends StatefulWidget {
  final GroupIdentifier? groupIdentifier;

  const SearchMentionUserWidget({
    super.key,
    this.groupIdentifier,
  });

  @override
  State<StatefulWidget> createState() {
    return _SearchMentionUserWidgetState();
  }
}

class _SearchMentionUserWidgetState extends State<SearchMentionUserWidget> {
  static const int searchMemLimit = 100;
  double _itemWidth = 50;

  List<User> _users = [];
  List<User?> _allUsers = [];
  bool _searchPerformed = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final groupId = widget.groupIdentifier;
    if (groupId == null) {
      return;
    }

    // Get the group members
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final groupMembers = groupProvider.getMembers(groupId);
    final memberPubkeys = groupMembers?.members;
    if (memberPubkeys == null || memberPubkeys.isEmpty) {
      return;
    }

    // Initialize the metadata list with nulls to maintain order
    setState(() {
      _allUsers = List.filled(memberPubkeys.length, null);
    });

    // Load metadata for each member
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    for (int i = 0; i < memberPubkeys.length; i++) {
      final pubkey = memberPubkeys[i];

      User? initialUser = userProvider.getUser(pubkey);
      if (initialUser != null) {
        _allUsers[i] = initialUser;
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var contentWidth = mediaDataCache.size.width - 4 * Base.basePadding;
    _itemWidth = (contentWidth - 10) / 2;

    return SearchMentionWidget(
      resultBuildFunc: _resultBuild,
      handleSearchFunc: _handleSearch,
    );
  }

  Widget _resultBuild() {
    if (_isSearching) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            "Searching relays...",
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontSize: 16,
            ),
          ),
        ],
      );
    } else if (_users.isEmpty) {
      // Check if we're showing empty results after a search, or just initial loading
      if (_searchPerformed) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              "No users found. Try a different search term.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 16,
              ),
            ),
          ),
        );
      } else {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
    }

    final userWidgetList = _users.map(
          (user) => SearchMentionUserItemWidget(
        user: user,
        width: _itemWidth,
      ),
    ).toList();

    return SingleChildScrollView(
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.only(
          top: Base.basePaddingHalf,
          bottom: Base.basePaddingHalf,
        ),
        child: SizedBox(
          width: _itemWidth * 2 + 10,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: userWidgetList,
          ),
        ),
      ),
    );
  }

  void _handleSearch(String? text) async {
    setState(() {
      _users.clear();
      _searchPerformed = true;
      _isSearching = text != null && text.isNotEmpty;
    });

    if (text == null || text.isEmpty) {
      setState(() {
        _users = _allUsers.whereType<User>().toList();
        _isSearching = false;
      });
      return;
    }

    // First, try to get users from the provider's findUser method (local cache)
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    var localUsers = userProvider.findUser(text, limit: searchMemLimit);
    
    // Do our own case-insensitive search on the local cache
    final allCachedUsers = userProvider.getAllUsers();
    final lowerText = text.toLowerCase();
    
    for (final user in allCachedUsers) {
      // Skip users already in the results
      if (localUsers.any((u) => u.pubkey == user.pubkey)) {
        continue;
      }
      
      // Case-insensitive search on display name, name, or nip05
      if ((user.displayName != null && user.displayName!.toLowerCase().contains(lowerText)) ||
          (user.name != null && user.name!.toLowerCase().contains(lowerText)) ||
          (user.nip05 != null && user.nip05!.toLowerCase().contains(lowerText))) {
        localUsers.add(user);
      }
    }
    
    // Update UI with local results first
    setState(() {
      _users = localUsers;
    });
    
    // Search for users based on the search term
    await _searchRelaysForUsers(text);
    
    // Finally, mark that we're done searching
    setState(() {
      _isSearching = false;
    });
  }
  
  Future<void> _searchRelaysForUsers(String searchText) async {
    // First check if it's a direct NIP-05 format (name@domain)
    if (searchText.contains('@') && !searchText.contains(' ')) {
      // This is likely a NIP-05 identifier - prioritize this search
      await _searchByExactNip05(searchText);
    }
    
    // Run parallel searches for other matching strategies
    await Future.wait([
      _searchRelaysWithMetadataFilter(searchText),
      // If the search text has a word that looks like a name (3+ chars without special chars)
      if (RegExp(r'\w{3,}').hasMatch(searchText)) 
        _searchRelaysForUsersByUsername(searchText),
    ]);
  }
  
  Future<void> _searchByExactNip05(String nip05Identifier) async {
    // This is a specialized search specifically for NIP-05 identifiers
    try {
      // Extract the parts from the NIP-05 identifier
      final parts = nip05Identifier.split('@');
      if (parts.length != 2) return;
      
      // Create a specialized filter just to find this exact NIP-05
      final filter = Filter(
        kinds: [EventKind.METADATA],
        limit: 20,
      );
      
      // Create a completer to wait for results
      final completer = Completer<void>();
      
      // Set a timeout
      Timer(const Duration(seconds: 8), () {
        try {
          completer.complete();
        } catch (_) {
          // Completer might already be completed
        }
      });
      
      // Query relays for this exact NIP-05
      nostr!.query([filter.toJson()], (event) {
        if (event.kind == EventKind.METADATA) {
          try {
            final content = jsonDecode(event.content);
            final userNip05 = content['nip05'] as String?;
            
            // Do case-insensitive exact matching
            if (userNip05 != null && 
                userNip05.toLowerCase() == nip05Identifier.toLowerCase()) {
              // We found an exact match!
              final user = User.fromJson(content);
              user.pubkey = event.pubkey;
              user.updatedAt = event.createdAt;
              
              // Add it if not already in results
              if (!_users.any((u) => u.pubkey == user.pubkey)) {
                setState(() {
                  _users.add(user);
                });
              }
            }
          } catch (e) {
            // Ignore errors parsing metadata
          }
        }
      });
      
      await completer.future;
    } catch (e) {
      // Ignore errors
    }
  }
  
  Future<void> _searchRelaysWithMetadataFilter(String searchText) async {
    try {
      // Query the relays for users with matching content in their metadata
      final filter = Filter(
        kinds: [EventKind.METADATA],
        limit: 50,  // Increased limit to get more potential matches
      );
      
      // Create a completer to wait for results
      final completer = Completer<void>();
      
      // Set a timeout - extended to 10 seconds for better search
      Timer(const Duration(seconds: 10), () {
        try {
          completer.complete();
        } catch (_) {
          // Completer might already be completed
        }
      });
      
      // Prepare for NIP-05 search if applicable
      bool isNip05Search = searchText.contains('@');
      String nip05Name = '';
      String nip05Domain = '';
      
      // If it looks like a NIP-05 identifier, extract parts for better matching
      if (isNip05Search && !searchText.contains(' ')) {
        final parts = searchText.split('@');
        if (parts.length == 2) {
          nip05Name = parts[0].toLowerCase();
          nip05Domain = parts[1].toLowerCase();
        }
      }
      
      // Search the relays
      nostr!.query([filter.toJson()], (event) {
        if (event.kind == EventKind.METADATA) {
          try {
            final content = jsonDecode(event.content);
            
            // Extract all the relevant fields we want to search in
            final userName = (content['name'] as String?)?.toLowerCase() ?? '';
            final userDisplayName = (content['display_name'] as String?)?.toLowerCase() ?? '';
            final userNip05 = (content['nip05'] as String?)?.toLowerCase() ?? '';
            final userAbout = (content['about'] as String?)?.toLowerCase() ?? '';
            
            // Lowercase search text for case-insensitive matching
            final lowerSearchText = searchText.toLowerCase();
            
            bool isMatch = false;
            
            // NIP-05 specific matching (if applicable)
            if (isNip05Search && userNip05.isNotEmpty) {
              // For NIP-05 searches, we need specialized matching logic
              if (nip05Name.isNotEmpty && nip05Domain.isNotEmpty) {
                // Check for exact NIP-05 match (highest priority)
                if (userNip05 == lowerSearchText) {
                  isMatch = true;
                } 
                // Check if domain matches and name contains/matches the search name
                else if (userNip05.endsWith('@$nip05Domain') && 
                         userNip05.contains(nip05Name)) {
                  isMatch = true;
                }
                // If only the domain matches, it's a lower priority match but still relevant
                else if (userNip05.endsWith('@$nip05Domain')) {
                  isMatch = true;
                }
              }
            }
            
            // Standard text matching for all fields
            if (!isMatch) {
              isMatch = userName.contains(lowerSearchText) || 
                      userDisplayName.contains(lowerSearchText) || 
                      userNip05.contains(lowerSearchText) ||
                      userAbout.contains(lowerSearchText);
            }
            
            if (isMatch) {
              // Process the event to update user cache
              final user = User.fromJson(content);
              user.pubkey = event.pubkey;
              user.updatedAt = event.createdAt;
              
              // Add user to results if not already there
              if (!_users.any((u) => u.pubkey == user.pubkey)) {
                setState(() {
                  _users.add(user);
                });
              }
            }
          } catch (e) {
            // Ignore errors parsing metadata
          }
        }
      });
      
      // Wait for timeout
      await completer.future;
    } catch (e) {
      // Ignore errors
    }
  }
  
  Future<void> _searchRelaysForUsersByUsername(String nameText) async {
    try {
      // Create a completer to wait for results
      final completer = Completer<void>();
      
      // Set a timeout
      Timer(const Duration(seconds: 8), () {
        try {
          completer.complete();
        } catch (_) {
          // Completer might already be completed
        }
      });
      
      // Process the search text to find likely name components
      final nameParts = nameText.split(RegExp(r'[\s@.,]+'))
          .where((part) => part.length >= 3)  // Only consider parts that might be names
          .map((part) => part.toLowerCase())
          .toList();
      
      if (nameParts.isEmpty) {
        completer.complete();
        return;
      }
      
      // Create a subscription to get recent events and filter them client-side
      final filter = Filter(
        kinds: [EventKind.METADATA], 
        limit: 100  // Get more events to increase chances of matches
      );
      
      nostr!.query([filter.toJson()], (event) {
        if (event.kind == EventKind.METADATA) {
          try {
            final content = jsonDecode(event.content);
            
            // Get all text fields we want to search in
            final textFields = [
              content['name'] as String?,
              content['display_name'] as String?,
              content['nip05'] as String?,
              content['about'] as String?,
            ].where((field) => field != null)
             .map((field) => field!.toLowerCase())
             .toList();
            
            // Check if any name part is in any of the text fields
            bool isMatch = false;
            for (final namePart in nameParts) {
              for (final field in textFields) {
                if (field.contains(namePart)) {
                  isMatch = true;
                  break;
                }
              }
              if (isMatch) break;
            }
            
            if (isMatch) {
              // Process the event to update user cache
              final user = User.fromJson(content);
              user.pubkey = event.pubkey;
              user.updatedAt = event.createdAt;
              
              // Check if this user is already in results
              if (!_users.any((u) => u.pubkey == user.pubkey)) {
                setState(() {
                  _users.add(user);
                });
              }
            }
          } catch (e) {
            // Ignore errors parsing metadata
          }
        }
      });
      
      // Wait for timeout
      await completer.future;
    } catch (e) {
      // Ignore errors
    }
  }
}

class SearchMentionUserItemWidget extends StatelessWidget {
  static const double IMAGE_WIDTH = 36;

  final User user;
  final double width;

  const SearchMentionUserItemWidget({
    super.key,
    required this.user,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var cardColor = themeData.cardColor;

    String nip19Name = Nip19.encodeSimplePubKey(user.pubkey!);
    String displayName = nip19Name;
    if (StringUtil.isNotBlank(user.displayName)) {
      displayName = user.displayName!;
    } else {
      if (StringUtil.isNotBlank(user.name)) {
        displayName = user.name!;
      }
    }

    var nip05Text = user.nip05;
    if (StringUtil.isBlank(nip05Text)) {
      nip05Text = nip19Name;
    }

    var main = Container(
      width: width,
      color: cardColor,
      padding: const EdgeInsets.all(Base.basePaddingHalf),
      child: Row(
        children: [
          UserPicWidget(
            pubkey: user.pubkey!,
            width: IMAGE_WIDTH,
            user: user,
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: Base.basePaddingHalf),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: nip05Text,
                          style: TextStyle(
                            fontSize: themeData.textTheme.bodySmall!.fontSize,
                            color: themeData.hintColor,
                          ),
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.ideographic,
                          child: Container(
                            margin: const EdgeInsets.only(left: 3),
                            child:
                                Nip05ValidWidget(pubkey: user.pubkey!),
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () {
        RouterUtil.back(context, user.pubkey);
      },
      child: main,
    );
  }
}
