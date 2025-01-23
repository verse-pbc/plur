import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/router/group/create_community_dialog.dart';
import 'package:nostrmo/router/group/no_communities_widget.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/utils/peddingevents_later_function.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/keep_alive_cust_state.dart';
import 'package:nostr_sdk/relay/relay_type.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostrmo/main.dart';

import '../../consts/colors.dart';
import 'community_widget.dart';
import '../../provider/relay_provider.dart';

class CommunitiesWidget extends StatefulWidget {
  const CommunitiesWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _CommunitiesWidgetState();
  }
}

class _CommunitiesWidgetState extends KeepAliveCustState<CommunitiesWidget>
    with PenddingEventsLaterFunction {
  var subscribeId = StringUtil.rndNameStr(16);

  @override
  Widget doBuild(BuildContext context) {
    final listProvider = Provider.of<ListProvider>(context);
    final groupIds = listProvider.groupIdentifiers;

    return Scaffold(
      appBar: AppBar(
        actions: [
          GestureDetector(
            onTap: showCreateCommunityDialog,
            behavior: HitTestBehavior.translucent,
            child: Container(
              width: 50,
              alignment: Alignment.center,
              child: const Icon(Icons.group_add),
            ),
          ),
        ],
      ),
      body: Container(
        color: ColorList.plurPurple,
        child: groupIds.isEmpty
            ? const Center(
                child: NoCommunitiesWidget(),
              )
            : GridView.builder(
                padding: const EdgeInsets.symmetric(vertical: 52),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 0.0,
                  mainAxisSpacing: 32.0,
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
                }),
      ),
    );
  }

  void showCreateCommunityDialog() {
    CreateCommunityDialog.show(context);
  }

  @override
  Future<void> onReady(BuildContext context) async {
    _subscribe();
  }

  void _subscribe() {
    if (StringUtil.isNotBlank(subscribeId)) {
      _unsubscribe();
    }

    final memberFilter = Filter(kinds: [EventKind.GROUP_MEMBERS]);
    final memberFilterMap = memberFilter.toJson();
    memberFilterMap["#p"] = [nostr!.publicKey];

    final adminFilter = Filter(kinds: [EventKind.GROUP_ADMINS]);
    final adminFilterMap = adminFilter.toJson();
    adminFilterMap["#p"] = [nostr!.publicKey];

    final groupDeleteFilter = Filter(kinds: [EventKind.GROUP_DELETE_GROUP]);
    final groupDeleteFilterMap = groupDeleteFilter.toJson();

    final groupEditMetadataFilter =
        Filter(kinds: [EventKind.GROUP_EDIT_METADATA]);
    final groupEditMetadataFilterMap = groupEditMetadataFilter.toJson();

    try {
      nostr!.subscribe(
        [
          memberFilterMap,
          adminFilterMap,
          groupDeleteFilterMap,
          groupEditMetadataFilterMap
        ],
        _handleSubscriptionEvent,
        id: subscribeId,
        relayTypes: [RelayType.TEMP],
        tempRelays: [RelayProvider.defaultGroupsRelayAddress],
        sendAfterAuth: true,
      );
    } catch (e) {
      print("Error in subscription: $e");
    }
  }

  void _handleSubscriptionEvent(Event event) {
    later(event, (list) {
      final listProvider = Provider.of<ListProvider>(context, listen: false);

      switch (event.kind) {
        case EventKind.GROUP_DELETE_GROUP:
          listProvider.handleGroupDeleteEvent(event);
          break;
        case EventKind.GROUP_MEMBERS:
        case EventKind.GROUP_ADMINS:
          listProvider.handleAdminMembershipEvent(event);
          break;
        case EventKind.GROUP_EDIT_METADATA:
          listProvider.handleEditMetadataEvent(event);
          break;
      }
    }, null);
  }

  Future<void> refresh() async {
    _subscribe();
  }

  void _unsubscribe() {
    try {
      nostr!.unsubscribe(subscribeId);
    } catch (e) {
      print("Error unsubscribing: $e");
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    disposeLater();
    super.dispose();
  }
}
