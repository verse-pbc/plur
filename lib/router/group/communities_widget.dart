import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/router/group/group_add_dialog.dart';
import 'package:nostrmo/router/group/no_communities_widget.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../../consts/colors.dart';
import '../../generated/l10n.dart';
import 'community_widget.dart';

class CommunitiesWidget extends StatefulWidget {
  const CommunitiesWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _CommunitiesWidgetState();
  }
}

class _CommunitiesWidgetState extends State<CommunitiesWidget> {
  @override
  Widget build(BuildContext context) {
    final listProvider = Provider.of<ListProvider>(context);
    final groupIds = listProvider.groupIdentifiers;

    return Scaffold(
      appBar: AppBar(
        actions: [
          GestureDetector(
            onTap: groupAdd,
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
                padding:
                    const EdgeInsets.symmetric(vertical: 52),
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

  void groupAdd() {
    GroupAddDialog.show(context);
  }
}
