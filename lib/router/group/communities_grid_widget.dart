import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/keep_alive_cust_state.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/provider/relay_provider.dart';
import 'package:nostrmo/router/group/community_widget.dart';
import 'package:nostrmo/router/group/no_communities_widget.dart';
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

  @override
  Widget doBuild(BuildContext context) {
    final listProvider = Provider.of<ListProvider>(context);
    final groupIds = listProvider.groupIdentifiers;

    return Container(
      child: groupIds.isEmpty
          ? const Center(
              child: NoCommunitiesWidget(),
            )
          : RefreshIndicator(
              onRefresh: refresh,
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
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
                          context, RouterPath.GROUP_DETAIL, groupIdentifier);
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
        "kinds": [EventKind.GROUP_MEMBERS],
        "#p": [nostr!.publicKey],
        "since": since,
      },
      {
        // Listen for communities where user is an admin
        "kinds": [EventKind.GROUP_ADMINS],
        "#p": [nostr!.publicKey],
        "since": since,
      },
      {
        // Listen for community deletions
        "kinds": [EventKind.GROUP_DELETE_GROUP],
        "since": since,
      },
      {
        // Listen for community metadata edits
        "kinds": [EventKind.GROUP_EDIT_METADATA],
        "since": since,
      }
    ];

    try {
      nostr!.subscribe(
        filters,
        _handleSubscriptionEvent,
        id: subscribeId,
        relayTypes: [RelayType.TEMP],
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
        case EventKind.GROUP_DELETE_GROUP:
          listProvider.handleGroupDeleteEvent(event);
        case EventKind.GROUP_MEMBERS || EventKind.GROUP_ADMINS:
          listProvider.handleAdminMembershipEvent(event);
        case EventKind.GROUP_EDIT_METADATA:
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