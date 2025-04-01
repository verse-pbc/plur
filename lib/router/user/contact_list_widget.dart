import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:provider/provider.dart';

import '../../component/user/user_metadata_widget.dart';
import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../data/user.dart';
import '../../provider/user_provider.dart';
import '../../util/router_util.dart';
import '../../util/table_mode_util.dart';

class ContactListWidget extends StatefulWidget {
  final ContactList contactList;

  const ContactListWidget({super.key, required this.contactList});

  @override
  State<StatefulWidget> createState() {
    return _ContactListWidgetState();
  }
}

class _ContactListWidgetState extends State<ContactListWidget> {
  final ScrollController _controller = ScrollController();

  List<Contact>? list;

  @override
  Widget build(BuildContext context) {
    list ??= widget.contactList.list().toList();

    Widget main = ListView.builder(
      controller: _controller,
      itemBuilder: (context, index) {
        var contact = list![index];
        return Container(
          margin: const EdgeInsets.only(bottom: Base.basePaddingHalf),
          child: Selector<UserProvider, User?>(
            builder: (context, user, child) {
              return GestureDetector(
                onTap: () {
                  RouterUtil.router(
                      context, RouterPath.USER, contact.publicKey);
                },
                behavior: HitTestBehavior.translucent,
                child: UserMetadataWidget(
                  pubkey: contact.publicKey,
                  user: user,
                  jumpable: true,
                ),
              );
            },
            selector: (context, provider) {
              return provider.getUser(contact.publicKey);
            },
          ),
        );
      },
      itemCount: list!.length,
    );

    if (TableModeUtil.isTableMode()) {
      main = GestureDetector(
        onVerticalDragUpdate: (detail) {
          _controller.jumpTo(_controller.offset - detail.delta.dy);
        },
        behavior: HitTestBehavior.translucent,
        child: main,
      );
    }

    return main;
  }
}
