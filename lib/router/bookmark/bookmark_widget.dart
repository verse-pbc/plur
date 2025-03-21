import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/util/table_mode_util.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../component/content/content_link_pre_widget.dart';
import '../../component/cust_state.dart';
import '../../component/event/event_quote_widget.dart';
import '../../generated/l10n.dart';
import '../index/index_app_bar.dart';

class BookmarkWidget extends StatefulWidget {
  const BookmarkWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _BookmarkWidgetState();
  }
}

class _BookmarkWidgetState extends CustState<BookmarkWidget> {
  @override
  Widget doBuild(BuildContext context) {
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
    final localization = S.of(context);

    var main =
        Selector<ListProvider, Bookmarks>(builder: (context, bookmarks, child) {
      return TabBarView(
        children: [
          buildBookmarkItems(bookmarks.privateItems),
          buildBookmarkItems(bookmarks.publicItems),
        ],
      );
    }, selector: (_, provider) {
      return provider.getBookmarks();
    });

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

  @override
  Future<void> onReady(BuildContext context) async {}

  Widget buildBookmarkItems(List<BookmarkItem> items) {
    return ListView.builder(
      itemBuilder: (context, index) {
        var item = items[items.length - index - 1];
        if (item.key == "r") {
          return ContentLinkPreWidget(
            link: item.value,
          );
        } else {
          return EventQuoteWidget(
            id: item.key == "e" ? item.value : null,
            aId: item.key == "a" ? AId.fromString(item.value) : null,
          );
        }
      },
      itemCount: items.length,
    );
  }
}
