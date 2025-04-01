import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/user/simple_user_widget.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/main.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../consts/router_path.dart';
import '../../util/router_util.dart';
import '../../util/table_mode_util.dart';
import '../index/index_app_bar.dart';

class FollowSetDetailWidget extends StatefulWidget {
  const FollowSetDetailWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _FollowSetDetailWidgetState();
  }
}

class _FollowSetDetailWidgetState extends State<FollowSetDetailWidget> {
  FollowSet? followSet;

  late S localization;

  @override
  Widget build(BuildContext context) {
    var followSetItf = RouterUtil.routerArgs(context);
    if (followSetItf == null || followSetItf is! FollowSet) {
      RouterUtil.back(context);
      return Container();
    }
    followSet = followSetItf;

    localization = S.of(context);
    final themeData = Theme.of(context);
    var titleTextColor = themeData.appBarTheme.titleTextStyle!.color;
    var titleTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: titleTextColor,
    );
    Color? indicatorColor = titleTextColor;
    if (TableModeUtil.isTableMode()) {
      indicatorColor = themeData.primaryColor;
    }

    var main = TabBarView(
      children: [
        buildContacts(
            followSet!.privateContacts, privateController, addPrivate),
        buildContacts(followSet!.publicContacts, publicController, addPublic),
      ],
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: const AppbarBackBtnWidget(),
          title: TabBar(
            indicatorColor: indicatorColor,
            indicatorWeight: 3,
            tabs: [
              Container(
                height: IndexAppBar.height,
                alignment: Alignment.center,
                child: Text(
                  localization.Private,
                  style: titleTextStyle,
                ),
              ),
              Container(
                height: IndexAppBar.height,
                alignment: Alignment.center,
                child: Text(
                  localization.Public,
                  style: titleTextStyle,
                ),
              )
            ],
          ),
        ),
        body: main,
      ),
    );
  }

  TextEditingController privateController = TextEditingController();

  TextEditingController publicController = TextEditingController();

  void addPrivate() {
    var pubkey = getPlainPubkey(privateController);
    Contact contact = Contact(publicKey: pubkey);
    followSet!.addPrivate(contact);

    privateController.clear();
    contactListProvider.addFollowSet(followSet!);
    setState(() {});
  }

  void addPublic() {
    var pubkey = getPlainPubkey(publicController);
    Contact contact = Contact(publicKey: pubkey);
    followSet!.addPublic(contact);

    publicController.clear();
    contactListProvider.addFollowSet(followSet!);
    setState(() {});
  }

  String getPlainPubkey(TextEditingController controller) {
    var text = controller.text;
    if (Nip19.isPubkey(text)) {
      return Nip19.decode(text);
    }

    return text;
  }

  buildContacts(List<Contact> contacts, TextEditingController controller,
      VoidCallback onTap) {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: Base.basePadding),
            child: ListView.builder(
              itemBuilder: (context, index) {
                var contact = contacts[contacts.length - index - 1];
                return Container(
                  margin: const EdgeInsets.only(bottom: Base.basePaddingHalf),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      RouterUtil.router(
                          context, RouterPath.USER, contact.publicKey);
                    },
                    child: SimpleUserWidget(
                      pubkey: contact.publicKey,
                    ),
                  ),
                );
              },
              itemCount: contacts.length,
            ),
          ),
        ),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.person),
            hintText: localization.Please_input_user_pubkey,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: onTap,
            ),
          ),
        ),
      ],
    );
  }
}
