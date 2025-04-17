
import 'package:bot_toast/bot_toast.dart';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/enum_selector_widget.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/provider/contact_list_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/provider/user_provider.dart';
import 'package:nostrmo/provider/relay_provider.dart';
import 'package:provider/provider.dart';

import '../../component/cust_state.dart';
import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../util/number_format_util.dart';
import '../../util/router_util.dart';

class UserStatisticsWidget extends StatefulWidget {
  final String pubkey;

  const UserStatisticsWidget({super.key, required this.pubkey});

  @override
  State<StatefulWidget> createState() {
    return _UserStatisticsWidgetState();
  }
}

class _UserStatisticsWidgetState extends CustState<UserStatisticsWidget> {
  Event? contactListEvent;

  ContactList? contactList;

  Event? relaysEvent;

  List<dynamic>? relaysTags;

  EventMemBox? zapEventBox;

  // followedMap
  Map<String, Event>? followedMap;

  int length = 0;
  int relaysNum = 0;
  int followedTagsLength = 0;
  int followedCommunitiesLength = 0;
  int? zapNum;
  int? followedNum;

  bool isLocal = false;

  String? pubkey;

  @override
  Widget doBuild(BuildContext context) {
    final localization = S.of(context);
    if (pubkey != null && pubkey != widget.pubkey) {
      // arg changed! reset
      contactListEvent = null;
      contactList = null;
      relaysEvent = null;
      relaysTags = null;
      zapEventBox = null;
      followedMap = null;

      length = 0;
      relaysNum = 0;
      followedTagsLength = 0;
      followedCommunitiesLength = 0;
      zapNum = null;
      followedNum = null;
      doQuery();
    }
    pubkey = widget.pubkey;
    isLocal = widget.pubkey == nostr!.publicKey;

    if (isLocal) {
      var provider = Provider.of<ContactListProvider>(context);
      List<Widget> list = [];
      list.add(UserStatisticsItemWidget(
        num: provider.total(),
        name: localization.following,
        onTap: onFollowingTap,
        onLongPressStart: onLongPressStart,
        onLongPressEnd: onLongPressEnd,
      ));

      list.add(UserStatisticsItemWidget(
          num: provider.followSetEventMap.length,
          name: localization.followSet,
          onTap: () {
            RouterUtil.router(context, RouterPath.followSetList);
          }));

      list.add(Selector<ListProvider, int>(builder: (context, number, child) {
        return UserStatisticsItemWidget(
            num: number,
            name: localization.groups,
            onTap: () {
              RouterUtil.router(context, RouterPath.groupList);
            });
      }, selector: (_, provider) {
        return provider.groupIdentifiers.length;
      }));

      list.add(Selector<RelayProvider, int>(builder: (context, number, child) {
        return UserStatisticsItemWidget(
            num: number, name: localization.relays, onTap: onRelaysTap);
      }, selector: (_, provider) {
        return provider.total();
      }));

      list.add(UserStatisticsItemWidget(
        num: followedNum,
        name: localization.followed,
        onTap: onFollowedTap,
        formatNum: true,
      ));

      list.add(UserStatisticsItemWidget(
        num: zapNum,
        name: "Zap",
        onTap: onZapTap,
        formatNum: true,
      ));

      list.add(UserStatisticsItemWidget(
        num: provider.totalFollowedTags(),
        name: localization.followedTags,
        onTap: onFollowedTagsTap,
      ));

      list.add(UserStatisticsItemWidget(
        num: provider.totalfollowedCommunities(),
        name: localization.followedCommunities,
        onTap: onFollowedCommunitiesTap,
      ));

      return Container(
        // color: Colors.red,
        height: 18,
        margin: const EdgeInsets.only(bottom: Base.basePadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: list,
        ),
      );
    } else {
      var provider = Provider.of<UserProvider>(context);
      contactList = provider.getContactList(pubkey!);

      List<Widget> list = [];

      if (contactList != null) {
        length = contactList!.list().length;
      }
      list.add(UserStatisticsItemWidget(
          num: length, name: localization.following, onTap: onFollowingTap));

      if (relaysTags != null) {
        relaysNum = relaysTags!.length;
      }
      list.add(UserStatisticsItemWidget(
          num: relaysNum, name: localization.relays, onTap: onRelaysTap));

      list.add(UserStatisticsItemWidget(
        num: followedNum,
        name: localization.followed,
        onTap: onFollowedTap,
        formatNum: true,
      ));

      list.add(UserStatisticsItemWidget(
        num: zapNum,
        name: "Zap",
        onTap: onZapTap,
        formatNum: true,
      ));

      if (contactList != null) {
        followedTagsLength = contactList!.tagList().length;
      }
      list.add(UserStatisticsItemWidget(
          num: followedTagsLength,
          name: localization.followedTags,
          onTap: onFollowedTagsTap));

      if (contactList != null) {
        followedCommunitiesLength =
            contactList!.followedCommunitiesList().length;
      }
      list.add(UserStatisticsItemWidget(
          num: followedCommunitiesLength,
          name: localization.followedCommunities,
          onTap: onFollowedCommunitiesTap));

      return Container(
        height: 18,
        margin: const EdgeInsets.only(bottom: Base.basePadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: list,
        ),
      );
    }
  }

  String? fetchLocalContactsId;

  EventMemBox? localContactBox;

  void onLongPressStart(LongPressStartDetails d) {
    if (fetchLocalContactsId == null) {
      fetchLocalContactsId = StringUtil.rndNameStr(16);
      localContactBox = EventMemBox(sortAfterAdd: false);
      var filter =
          Filter(authors: [widget.pubkey], kinds: [EventKind.contactList]);
      nostr!.query([filter.toJson()], (event) {
        localContactBox!.add(event);
      }, id: fetchLocalContactsId);
      BotToast.showText(text: S.of(context).beginToLoadContactHistory);
    }
  }

  Future<void> onLongPressEnd(LongPressEndDetails d) async {
    if (fetchLocalContactsId != null) {
      nostr!.unsubscribe(fetchLocalContactsId!);
      fetchLocalContactsId = null;

      var format = FixedDateTimeFormatter("YYYY-MM-DD hh:mm:ss");

      localContactBox!.sort();
      var list = localContactBox!.all();

      List<EnumObj> enumList = [];
      for (var event in list) {
        var contactList = ContactList.fromJson(event.tags, event.createdAt);
        var dt = DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);
        enumList.add(
            EnumObj(event, "${format.encode(dt)} (${contactList.total()})"));
      }

      var result = await EnumSelectorWidget.show(context, enumList);
      if (!mounted) return;
      if (result != null) {
        var event = result.value as Event;
        var contactList = ContactList.fromJson(event.tags, event.createdAt);
        RouterUtil.router(
            context, RouterPath.userHistoryContactList, contactList);
      }
    }
  }

  String queryId2 = "";

  @override
  Future<void> onReady(BuildContext context) async {
    if (!isLocal) {
      doQuery();
    }
  }

  void doQuery() {
    {
      queryId2 = StringUtil.rndNameStr(16);
      var filter = Filter(
          authors: [widget.pubkey],
          limit: 1,
          kinds: [EventKind.relayListMetadata]);
      nostr!.query([filter.toJson()], (event) {
        if (((relaysEvent != null &&
                    event.createdAt > relaysEvent!.createdAt) ||
                relaysEvent == null) &&
            !_disposed) {
          setState(() {
            relaysEvent = event;
            relaysTags = event.tags;
          });
        }
      }, id: queryId2);
    }
  }

  onFollowingTap() {
    if (isLocal) {
      var cl = contactListProvider.contactList;
      if (cl != null) {
        RouterUtil.router(context, RouterPath.userContactList, cl);
      }
    } else {
      var contactList = userProvider.getContactList(pubkey!);
      if (contactList != null) {
        RouterUtil.router(context, RouterPath.userContactList, contactList);
      }
    }
  }

  onFollowedTagsTap() {
    if (contactList != null) {
      RouterUtil.router(context, RouterPath.followedTagsList, contactList);
    } else if (isLocal) {
      var cl = contactListProvider.contactList;
      if (cl != null) {
        RouterUtil.router(context, RouterPath.followedTagsList, cl);
      }
    }
  }

  String followedSubscribeId = "";

  onFollowedTap() {
    if (followedMap == null) {
      // load data
      followedMap = {};
      // pull zap event
      Map<String, dynamic> filter = {};
      filter["kinds"] = [EventKind.contactList];
      filter["#p"] = [widget.pubkey];
      followedSubscribeId = StringUtil.rndNameStr(12);
      nostr!.query([filter], (e) {
        var oldEvent = followedMap![e.pubkey];
        if (oldEvent == null || e.createdAt > oldEvent.createdAt) {
          followedMap![e.pubkey] = e;

          setState(() {
            followedNum = followedMap!.length;
          });
        }
      }, id: followedSubscribeId);

      followedNum = 0;
    } else {
      // jump to see
      var pubkeys = followedMap!.keys.toList();
      RouterUtil.router(context, RouterPath.followed, pubkeys);
    }
  }

  onRelaysTap() {
    if (relaysTags != null && relaysTags!.isNotEmpty) {
      RouterUtil.router(context, RouterPath.userRelays, relaysTags);
    } else if (isLocal) {
      RouterUtil.router(context, RouterPath.relays);
    }
  }

  String zapSubscribeId = "";

  onZapTap() {
    if (zapEventBox == null) {
      zapEventBox = EventMemBox(sortAfterAdd: false);
      // pull zap event
      var filter = Filter(kinds: [EventKind.zap], p: [widget.pubkey]);
      zapSubscribeId = StringUtil.rndNameStr(12);

      nostr!.query([filter.toJson()], onZapEvent, id: zapSubscribeId);

      zapNum = 0;
    } else {
      // Router to vist list
      zapEventBox!.sort();
      var list = zapEventBox!.all();
      RouterUtil.router(context, RouterPath.userZapList, list);
    }
  }

  onZapEvent(Event event) {
    if (event.kind == EventKind.zap && zapEventBox!.add(event)) {
      setState(() {
        zapNum = zapNum! + ZapInfoUtil.getNumFromZapEvent(event);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();

    _disposed = true;
    checkAndUnsubscribe(queryId2);
    checkAndUnsubscribe(zapSubscribeId);
  }

  void checkAndUnsubscribe(String queryId) {
    if (StringUtil.isNotBlank(queryId)) {
      try {
        nostr!.unsubscribe(queryId);
      } catch (_) {}
    }
  }

  bool _disposed = false;

  onFollowedCommunitiesTap() {
    if (contactList != null) {
      RouterUtil.router(context, RouterPath.followedCommunities, contactList);
    } else if (isLocal) {
      var cl = contactListProvider.contactList;
      if (cl != null) {
        RouterUtil.router(context, RouterPath.followedCommunities, cl);
      }
    }
  }
}

class UserStatisticsItemWidget extends StatelessWidget {
  final int? num;

  final String name;

  final Function onTap;

  final bool formatNum;

  final Function(LongPressStartDetails)? onLongPressStart;

  final Function(LongPressEndDetails)? onLongPressEnd;

  const UserStatisticsItemWidget({super.key, 
    required this.num,
    required this.name,
    required this.onTap,
    this.formatNum = false,
    this.onLongPressStart,
    this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var fontSize = themeData.textTheme.bodySmall!.fontSize;

    List<Widget> list = [];
    if (num != null) {
      var numStr = num.toString();
      if (formatNum) {
        numStr = NumberFormatUtil.format(num!);
      }

      list.add(Text(
        numStr,
        style: TextStyle(
          fontSize: fontSize,
        ),
      ));
    } else {
      list.add(const Icon(
        Icons.download,
        size: 14,
      ));
    }
    list.add(Container(
      margin: const EdgeInsets.only(left: 4),
      child: Text(
        name,
        style: TextStyle(
          color: hintColor,
          fontSize: fontSize,
        ),
      ),
    ));

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        onTap();
      },
      onLongPressStart: onLongPressStart,
      onLongPressEnd: onLongPressEnd,
      child: Container(
        margin: const EdgeInsets.only(left: Base.basePadding),
        child: Row(children: list),
      ),
    );
  }
}
