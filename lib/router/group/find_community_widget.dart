import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:nostrmo/component/primary_button_widget.dart';
import 'package:nostrmo/data/public_group_info.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/provider/relay_provider.dart';

/// A widget that shows a list of public groups and allows the user to join them
class FindCommunityWidget extends StatefulWidget {
  final void Function(String) onJoinCommunity;

  const FindCommunityWidget({super.key, required this.onJoinCommunity});

  @override
  State<FindCommunityWidget> createState() => _FindCommunityWidgetState();
}

class _FindCommunityWidgetState extends State<FindCommunityWidget> {
  bool _isLoading = true;
  List<PublicGroupInfo> _publicGroups = [];
  String _sortBy = 'members'; // 'members' or 'activity'
  
  @override
  void initState() {
    super.initState();
    _fetchPublicGroups();
  }
  
  Future<void> _fetchPublicGroups() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final listProvider = Provider.of<ListProvider>(context, listen: false);
      
      // Try our own default relay first, then fallback to other well-known relays
      const defaultRelay = RelayProvider.defaultGroupsRelayAddress;
      
      // Start with just the default relay for faster results
      print("📡 STAGE 1: Querying default relay: $defaultRelay");
      final groups1 = await listProvider.queryPublicGroups([defaultRelay]);
      
      if (groups1.isNotEmpty) {
        print("✅ SUCCESS: Found ${groups1.length} groups on default relay");
        setState(() {
          _publicGroups = groups1;
          _sortGroups();
          _isLoading = false;
        });
        return; // If we found groups, exit early
      }
      
      // If no groups found, try well-known relays
      print("📡 STAGE 2: No groups found on default relay, trying well-known relays");
      final wellKnownRelays = [
        'wss://relay.nostr.band',
        'wss://nos.lol',
        'wss://relay.damus.io',
        'wss://relay.nostr.wirednet.jp',
        'wss://purplepag.es',
        'wss://eden.nostr.land',
        'wss://nostr.ethsig.xyz'
      ];
      
      final groups2 = await listProvider.queryPublicGroups(wellKnownRelays);
      
      // Show diagnostic information for both attempts
      if (groups1.isEmpty && groups2.isEmpty) {
        print("⚠️ WARNING: No public groups found on any relay. Check logs for details.");
      } else {
        print("✅ SUCCESS: Found ${groups2.length} groups on well-known relays");
        for (var group in groups2) {
          print("  > Group: ${group.name} (${group.identifier.host})");
        }
      }
      
      setState(() {
        _publicGroups = groups2;
        _sortGroups();
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print("❌ ERROR: Failed fetching public groups: $e");
      print("Stack trace: $stackTrace");
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _sortGroups() {
    if (_sortBy == 'members') {
      _publicGroups.sort((a, b) => b.memberCount.compareTo(a.memberCount));
    } else {
      _publicGroups.sort((a, b) => b.lastActive.compareTo(a.lastActive));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button in top left
        Align(
          alignment: Alignment.topLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).maybePop();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 24,
          ),
        ),
        const SizedBox(height: 10),
        
        Text(
          l10n.discoverGroups,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 20),
        
        // Sort options
        Row(
          children: [
            Text(
              'Sort by: ',
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  _sortBy = 'members';
                  _sortGroups();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _sortBy == 'members' 
                      ? theme.primaryColor.withOpacity(0.1) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _sortBy == 'members' 
                        ? theme.primaryColor 
                        : theme.dividerColor,
                  ),
                ),
                child: Text(
                  l10n.members,
                  style: TextStyle(
                    color: _sortBy == 'members' 
                        ? theme.primaryColor 
                        : theme.textTheme.bodyMedium?.color,
                    fontWeight: _sortBy == 'members' 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () {
                setState(() {
                  _sortBy = 'activity';
                  _sortGroups();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _sortBy == 'activity' 
                      ? theme.primaryColor.withOpacity(0.1) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _sortBy == 'activity' 
                        ? theme.primaryColor 
                        : theme.dividerColor,
                  ),
                ),
                child: Text(
                  l10n.active,
                  style: TextStyle(
                    color: _sortBy == 'activity' 
                        ? theme.primaryColor 
                        : theme.textTheme.bodyMedium?.color,
                    fontWeight: _sortBy == 'activity' 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchPublicGroups,
              splashRadius: 24,
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        // Group list
        if (_isLoading)
          _buildLoadingState()
        else if (_publicGroups.isEmpty)
          _buildEmptyState()
        else
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _publicGroups.length,
              itemBuilder: (context, index) {
                final group = _publicGroups[index];
                return _buildGroupItem(group);
              },
            ),
          ),
      ],
    );
  }
  
  Widget _buildLoadingState() {
    return Column(
      children: List.generate(3, (index) => 
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        )
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No public groups found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Possible reasons:\n• No public groups on the relays\n• Not connected to any relays\n• Relays not responding\n• Group metadata uses a different format',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We searched both the default relay and several well-known relays',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PrimaryButtonWidget(
                text: 'Retry',
                onTap: _fetchPublicGroups,
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Go back to the community options
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildGroupItem(PublicGroupInfo group) {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: group.picture != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.network(
                            group.picture!,
                            fit: BoxFit.cover,
                            width: 50,
                            height: 50,
                            errorBuilder: (context, error, stackTrace) => 
                                Icon(Icons.group, color: Theme.of(context).primaryColor),
                          ),
                        )
                      : Icon(Icons.group, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (group.about != null && group.about!.isNotEmpty)
                        Text(
                          group.about!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.people, 
                            size: 16, 
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${group.memberCount} members',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.access_time, 
                            size: 16, 
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Active: ${dateFormat.format(group.lastActive)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => _joinGroup(group),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, 36),
                  ),
                  child: Text(S.of(context).joinGroup),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _joinGroup(PublicGroupInfo group) {
    // Generate join link to use with the existing join mechanism
    final joinLink = 'holis://join-community?group-id=${group.identifier.groupId}';
    widget.onJoinCommunity(joinLink);
  }
}