import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/keep_alive_cust_state.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/provider/relay_provider.dart';
import 'package:nostrmo/features/communities/community_widget.dart';
import 'package:nostrmo/features/communities/empty_communities_widget.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/time_util.dart';
import 'package:provider/provider.dart';
import 'dart:developer';

/// Widget that displays a grid of communities the user has joined
class CommunitiesGridWidget extends StatefulWidget {
  const CommunitiesGridWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _CommunitiesGridWidgetState();
  }
}

class _CommunitiesGridWidgetState extends KeepAliveCustState<CommunitiesGridWidget>
    with PendingEventsLaterFunction {
  final subscribeId = StringUtil.rndNameStr(16);
  
  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) {
      return 4; // Large screens
    } else if (width > 800) {
      return 3; // Medium sized screens
    } else {
      return 2; // Default for mobile
    }
  }

  @override
  Widget doBuild(BuildContext context) {
    final listProvider = Provider.of<ListProvider>(context);
    final groupIds = listProvider.groupIdentifiers;

    return Container(
      child: groupIds.isEmpty
          ? const EmptyCommunitiesWidget()
          : RefreshIndicator(
              onRefresh: refresh,
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _calculateCrossAxisCount(context),
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 24.0,
                  childAspectRatio: 1,
                ),
                itemCount: groupIds.length,
                itemBuilder: (context, index) {
                  final groupIdentifier = groupIds[index];
                  return InkWell(
                    onTap: () {
                      RouterUtil.router(
                          context, RouterPath.groupDetail, groupIdentifier);
                    },
                    child: CommunityWidget(groupIdentifier),
                  );
                },
              ),
            ),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    _subscribe();
  }

  void _subscribe() {
    if (StringUtil.isNotBlank(subscribeId)) {
      _unsubscribe();
    }

    // Get current timestamp to only receive events from now onwards.
    final since = currentUnixTimestamp();
    final filters = [
      {
        // Listen for communities where user is a member
        "kinds": [EventKind.groupMembers],
        "#p": [nostr!.publicKey],
        "since": since,
      },
      {
        // Listen for communities where user is an admin
        "kinds": [EventKind.groupAdmins],
        "#p": [nostr!.publicKey],
        "since": since,
      },
      {
        // Listen for community deletions
        "kinds": [EventKind.groupDeleteGroup],
        "since": since,
      },
      {
        // Listen for community metadata edits
        "kinds": [EventKind.groupEditMetadata],
        "since": since,
      }
    ];

    try {
      nostr!.subscribe(
        filters,
        _handleSubscriptionEvent,
        id: subscribeId,
        relayTypes: [RelayType.temp],
        tempRelays: [RelayProvider.defaultGroupsRelayAddress],
        sendAfterAuth: true,
      );
    } catch (e) {
      log("Error in subscription: $e");
    }
  }

  void _handleSubscriptionEvent(Event event) {
    later(event, (list) {
      final listProvider = Provider.of<ListProvider>(context, listen: false);

      switch (event.kind) {
        case EventKind.groupDeleteGroup:
          listProvider.handleGroupDeleteEvent(event);
        case EventKind.groupMembers || EventKind.groupAdmins:
          listProvider.handleAdminMembershipEvent(event);
        case EventKind.groupEditMetadata:
          listProvider.handleEditMetadataEvent(event);
      }
    }, null);
  }

  Future<void> refresh() async {
    _subscribe();
    return Future.value();
  }

  void _unsubscribe() {
    try {
      nostr!.unsubscribe(subscribeId);
    } catch (e) {
      log("Error unsubscribing: $e");
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    disposeLater();
    super.dispose();
  }
}