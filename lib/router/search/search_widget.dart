import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/user/user_top_widget.dart';
import 'package:nostrmo/data/event_find_util.dart';
import 'package:nostrmo/data/user.dart';
import 'package:nostrmo/router/search/search_action_item_widget.dart';
import 'package:nostrmo/router/search/search_actions.dart';
import 'package:provider/provider.dart';

import '../../component/cust_state.dart';
import '../../component/event/event_list_widget.dart';
import '../../component/event_delete_callback.dart';
import '../../consts/base_consts.dart';
import '../../consts/router_path.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/settings_provider.dart';
import '../../util/load_more_event.dart';
import '../../util/router_util.dart';

import '../../util/table_mode_util.dart';

class SearchWidget extends StatefulWidget {
  const SearchWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SearchWidgetState();
  }
}

class _SearchWidgetState extends CustState<SearchWidget>
    with PendingEventsLaterFunction, LoadMoreEvent, WhenStopFunction {
  TextEditingController controller = TextEditingController();

  ScrollController loadableScrollController = ScrollController();

  ScrollController scrollController = ScrollController();

  @override
  Future<void> onReady(BuildContext context) async {
    bindLoadMoreScroll(loadableScrollController);

    controller.addListener(() {
      var hasText = StringUtil.isNotBlank(controller.text);
      if (!showSuffix && hasText) {
        setState(() {
          showSuffix = true;
        });
        return;
      } else if (showSuffix && !hasText) {
        setState(() {
          showSuffix = false;
        });
      }

      whenStop(checkInput);
    });
  }

  bool showSuffix = false;

  @override
  Widget doBuild(BuildContext context) {
    final localization = S.of(context);
    final themeData = Theme.of(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    preBuild();

    Widget? suffixWidget;
    if (showSuffix) {
      suffixWidget = GestureDetector(
        onTap: () {
          controller.text = "";
        },
        child: const Icon(Icons.close),
      );
    }

    bool? loadable;
    Widget? body;
    if (searchAction == null && availableSearchActions.isNotEmpty) {
      // no searchAction, show availableSearchActions
      List<Widget> list = [];
      for (var action in availableSearchActions) {
        if (action == SearchActions.openPubkey) {
          list.add(SearchActionItemWidget(
              title: localization.Open_User_page, onTap: openPubkey));
        } else if (action == SearchActions.openNoteId) {
          list.add(SearchActionItemWidget(
              title: localization.Open_Note_detail, onTap: openNoteId));
        } else if (action == SearchActions.openHashtag) {
          list.add(SearchActionItemWidget(
              title: "${localization.open} ${localization.Hashtag}",
              onTap: openHashtag));
        } else if (action == SearchActions.searchMetadataFromCache) {
          list.add(SearchActionItemWidget(
              title: localization.Search_User_from_cache,
              onTap: searchMetadataFromCache));
        } else if (action == SearchActions.searchEventFromCache) {
          list.add(SearchActionItemWidget(
              title: localization.Open_Event_from_cache,
              onTap: searchEventFromCache));
        } else if (action == SearchActions.searchPubkeyEvent) {
          list.add(SearchActionItemWidget(
              title: localization.Search_pubkey_event,
              onTap: onEditingComplete));
        } else if (action == SearchActions.searchNoteContent) {
          list.add(SearchActionItemWidget(
              title: "${localization.Search_note_content} NIP-50",
              onTap: searchNoteContent));
        }
      }
      body = Column(
        mainAxisSize: MainAxisSize.min,
        children: list,
      );
    } else {
      if (searchAction == SearchActions.searchMetadataFromCache) {
        loadable = false;
        body = ListView.builder(
          controller: scrollController,
          itemBuilder: (BuildContext context, int index) {
            var user = users[index];

            return GestureDetector(
              onTap: () {
                RouterUtil.router(context, RouterPath.user, user.pubkey);
              },
              child: UserTopWidget(
                pubkey: user.pubkey!,
                user: user,
              ),
            );
          },
          itemCount: users.length,
        );
      } else if (searchAction == SearchActions.searchEventFromCache) {
        loadable = false;
        body = ListView.builder(
          controller: scrollController,
          itemBuilder: (BuildContext context, int index) {
            var event = events[index];

            return EventListWidget(
              event: event,
              showVideo:
                  settingsProvider.videoPreviewInList != OpenStatus.close,
            );
          },
          itemCount: events.length,
        );
      } else if (searchAction == SearchActions.searchPubkeyEvent) {
        loadable = true;
        var events = eventMemBox.all();
        body = ListView.builder(
          controller: loadableScrollController,
          itemBuilder: (BuildContext context, int index) {
            var event = events[index];

            return EventListWidget(
              event: event,
              showVideo:
                  settingsProvider.videoPreviewInList != OpenStatus.close,
            );
          },
          itemCount: itemLength,
        );
      }
    }
    if (body != null) {
      if (loadable != null && TableModeUtil.isTableMode()) {
        body = GestureDetector(
          onVerticalDragUpdate: (detail) {
            if (loadable == true) {
              loadableScrollController
                  .jumpTo(loadableScrollController.offset - detail.delta.dy);
            } else {
              scrollController
                  .jumpTo(scrollController.offset - detail.delta.dy);
            }
          },
          behavior: HitTestBehavior.translucent,
          child: body,
        );
      }
    } else {
      body = Container();
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: EventDeleteCallback(
        onDeleteCallback: onDeletedCallback,
        child: Column(children: [
          Container(
            color: themeData.cardColor,
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: localization.Please_input_search_content,
                suffixIcon: suffixWidget,
              ),
              onEditingComplete: onEditingComplete,
            ),
          ),
          Expanded(
            child: body,
          ),
        ]),
      ),
    );
  }

  List<int> searchEventKinds = EventKind.supportedEvents;

  String? subscribeId;

  EventMemBox eventMemBox = EventMemBox();

  // Filter? filter;
  Map<String, dynamic>? filterMap;

  @override
  void doQuery() {
    preQuery();

    if (subscribeId != null) {
      unSubscribe();
    }
    subscribeId = generatePrivateKey();

    if (!eventMemBox.isEmpty()) {
      var activeRelays = nostr!.activeRelays();
      var oldestCreatedAts = eventMemBox.oldestCreatedAtByRelay(activeRelays);
      Map<String, List<Map<String, dynamic>>> filtersMap = {};
      for (var relay in activeRelays) {
        var oldestCreatedAt = oldestCreatedAts.createdAtMap[relay.url];
        if (oldestCreatedAt != null) {
          filterMap!["until"] = oldestCreatedAt;
        }
        Map<String, dynamic> fm = {};
        for (var entry in filterMap!.entries) {
          fm[entry.key] = entry.value;
        }
        filtersMap[relay.url] = [fm];
      }
      nostr!.queryByFilters(filtersMap, onQueryEvent, id: subscribeId);
    } else {
      if (until != null) {
        filterMap!["until"] = until;
      }
      log(jsonEncode(filterMap));
      nostr!.query([filterMap!], onQueryEvent, id: subscribeId);
    }
  }

  void onQueryEvent(Event event) {
    later(event, (list) {
      var addResult = eventMemBox.addList(list);
      if (addResult) {
        setState(() {});
      }
    }, null);
  }

  void unSubscribe() {
    nostr!.unsubscribe(subscribeId!);
    subscribeId = null;
  }

  void onEditingComplete() {
    hideKeyBoard();
    searchAction = SearchActions.searchPubkeyEvent;

    var value = controller.text;
    value = value.trim();
    // if (StringUtil.isBlank(value)) {
    //   BotToast.showText(text: S.of(context).Empty_text_may_be_ban_by_relays);
    // }

    List<String>? authors;
    String? searchText;
    if (StringUtil.isNotBlank(value) && value.indexOf("npub") == 0) {
      try {
        var result = Nip19.decode(value);
        authors = [result];
      } catch (e) {
        log(e.toString());
        // registers new token on refresh when nostr is availablehandle error
        return;
      }
    } else {
      if (StringUtil.isNotBlank(value)) {
        searchText = value;
      }
    }

    eventMemBox = EventMemBox();
    until = null;
    filterMap =
        Filter(kinds: searchEventKinds, authors: authors, limit: queryLimit)
            .toJson();
    if (StringUtil.isNotBlank(searchText)) {
      filterMap!["search"] = searchText;
    }
    pendingEvents.clear;
    doQuery();
  }

  void hideKeyBoard() {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  EventMemBox getEventBox() {
    return eventMemBox;
  }

  @override
  void dispose() {
    super.dispose();
    disposeLater();
    disposeWhenStop();
  }

  static const int searchMemLimit = 100;

  onDeletedCallback(Event event) {
    eventMemBox.delete(event.id);
    setState(() {});
  }

  openPubkey() {
    hideKeyBoard();
    var text = controller.text;
    if (StringUtil.isNotBlank(text)) {
      String pubkey = text;
      if (Nip19.isPubkey(text)) {
        pubkey = Nip19.decode(text);
      }

      RouterUtil.router(context, RouterPath.user, pubkey);
    }
  }

  openNoteId() {
    hideKeyBoard();
    var text = controller.text;
    if (StringUtil.isNotBlank(text)) {
      String noteId = text;
      if (Nip19.isNoteId(text)) {
        noteId = Nip19.decode(text);
      }

      RouterUtil.router(context, RouterPath.eventDetail, noteId);
    }
  }

  openHashtag() {
    hideKeyBoard();
    var text = controller.text;
    if (StringUtil.isNotBlank(text)) {
      RouterUtil.router(context, RouterPath.tagDetail, text);
    }
  }

  List<User> users = [];

  searchMetadataFromCache() {
    hideKeyBoard();
    users.clear();
    searchAction = SearchActions.searchMetadataFromCache;

    var text = controller.text;
    if (StringUtil.isNotBlank(text)) {
      var list = userProvider.findUser(text, limit: searchMemLimit);

      setState(() {
        users = list;
      });
    }
  }

  List<Event> events = [];

  searchEventFromCache() async {
    hideKeyBoard();
    events.clear();
    searchAction = SearchActions.searchEventFromCache;

    var text = controller.text;
    if (StringUtil.isNotBlank(text)) {
      var list = await EventFindUtil.findEvent(text, limit: searchMemLimit);
      setState(() {
        events = list;
      });
    }
  }

  String? searchAction;

  List<String> availableSearchActions = [];

  String lastText = "";

  checkInput() {
    searchAction = null;
    availableSearchActions.clear();

    var text = controller.text;
    if (text == lastText) {
      return;
    }

    if (StringUtil.isNotBlank(text)) {
      if (Nip19.isPubkey(text)) {
        availableSearchActions.add(SearchActions.openPubkey);
      }
      if (Nip19.isNoteId(text)) {
        availableSearchActions.add(SearchActions.openNoteId);
      }
      if (availableSearchActions.isEmpty) {
        availableSearchActions.add(SearchActions.openHashtag);
      }
      availableSearchActions.add(SearchActions.searchMetadataFromCache);
      availableSearchActions.add(SearchActions.searchEventFromCache);
      availableSearchActions.add(SearchActions.searchPubkeyEvent);
      availableSearchActions.add(SearchActions.searchNoteContent);
    }

    lastText = text;
    setState(() {});
  }

  searchNoteContent() {
    hideKeyBoard();
    searchAction = SearchActions.searchPubkeyEvent;

    var value = controller.text;
    value = value.trim();
    // if (StringUtil.isBlank(value)) {
    //   BotToast.showText(text: S.of(context).Empty_text_may_be_ban_by_relays);
    // }

    eventMemBox = EventMemBox();
    until = null;
    filterMap = Filter(kinds: searchEventKinds, limit: queryLimit).toJson();
    filterMap!.remove("authors");
    filterMap!["search"] = value;
    pendingEvents.clear;
    doQuery();
  }
}
