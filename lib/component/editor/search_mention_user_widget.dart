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
    
    // Then search the relays - first check if the input might be a nip05 address
    if (text.contains('@')) {
      // Possible NIP-05 format, let's search on relays
      await _searchRelaysForNip05(text);
    }
    
    // Search relays for users by name
    await _searchRelaysForUsersByName(text);
    
    // Finally, mark that we're done searching
    setState(() {
      _isSearching = false;
    });
  }
  
  Future<void> _searchRelaysForNip05(String nip05Text) async {
    // Check if it's potentially a NIP-05 identifier
    if (!nip05Text.contains('@')) return;
    
    try {
      // Query the relays for users with this nip05
      final filter = Filter(
        kinds: [EventKind.METADATA],
        limit: 10,
      );
      
      // We'll collect results here
      List<Event> events = [];
      
      // Create a completer to wait for results
      final completer = Completer<void>();
      
      // Set a timeout
      Timer(const Duration(seconds: 5), () {
        try {
          completer.complete();
        } catch (_) {
          // Completer might already be completed
        }
      });
      
      // Search the relays
      nostr!.query([filter.toJson()], (event) {
        if (event.kind == EventKind.METADATA) {
          try {
            final content = jsonDecode(event.content);
            final userNip05 = content['nip05'] as String?;
            
            if (userNip05 != null && userNip05.toLowerCase().contains(nip05Text.toLowerCase())) {
              events.add(event);
              
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
  
  Future<void> _searchRelaysForUsersByName(String nameText) async {
    try {
      // Query the relays for users with matching names
      final filter = Filter(
        kinds: [EventKind.METADATA],
        limit: 20,
      );
      
      // We'll collect results here
      List<Event> events = [];
      
      // Create a completer to wait for results
      final completer = Completer<void>();
      
      // Set a timeout
      Timer(const Duration(seconds: 5), () {
        try {
          completer.complete();
        } catch (_) {
          // Completer might already be completed
        }
      });
      
      // Search the relays
      nostr!.query([filter.toJson()], (event) {
        if (event.kind == EventKind.METADATA) {
          try {
            final content = jsonDecode(event.content);
            final userName = content['name'] as String?;
            final userDisplayName = content['display_name'] as String?;
            
            final lowerNameText = nameText.toLowerCase();
            if ((userName != null && userName.toLowerCase().contains(lowerNameText)) ||
                (userDisplayName != null && userDisplayName.toLowerCase().contains(lowerNameText))) {
              events.add(event);
              
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
