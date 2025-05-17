import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/user/simple_name_widget.dart';
import 'package:nostrmo/component/sync_upload_dialog.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:provider/provider.dart';

import '../../component/appbar4stack.dart';
import '../../component/cust_state.dart';
import '../../component/event/event_list_widget.dart';
import '../../component/user/user_metadata_widget.dart';
import '../../component/report_user_dialog.dart';
import '../../consts/base_consts.dart';
import '../../data/user.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/user_provider.dart';
import '../../provider/group_provider.dart';
import '../../provider/relay_provider.dart';
import '../../provider/settings_provider.dart';
import '../../util/load_more_event.dart';
import '../../util/router_util.dart';
import '../../util/app_logger.dart';
import 'user_statistics_widget.dart';
import '../../util/theme_util.dart';

class UserWidget extends StatefulWidget {
  const UserWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _UserWidgetState();
  }
}

class _UserWidgetState extends CustState<UserWidget>
    with PendingEventsLaterFunction, LoadMoreEvent, WhenStopFunction {
  final GlobalKey<NestedScrollViewState> globalKey = GlobalKey();

  final ScrollController _controller = ScrollController();

  String? pubkey;

  bool showTitle = false;

  bool showAppbarBG = false;

  EventMemBox box = EventMemBox();

  @override
  void initState() {
    super.initState();
    bindLoadMoreScroll(_controller);

    whenStopMS = 1500;
    // queryLimit = 200;

    _controller.addListener(() {
      var showTitle = false;
      var showAppbarBG = false;

      var offset = _controller.offset;
      if (offset > showTitleHeight) {
        showTitle = true;
      }
      if (offset > showAppbarBGHeight) {
        showAppbarBG = true;
      }

      if (showTitle != showTitle || showAppbarBG != showAppbarBG) {
        setState(() {
          showTitle = showTitle;
          showAppbarBG = showAppbarBG;
        });
      }
    });
  }

  /// the offset to show title, bannerHeight + 50;
  double showTitleHeight = 50;

  /// the offset to appbar background color, showTitleHeight + 100;
  double showAppbarBGHeight = 50 + 100;

  @override
  Widget doBuild(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    if (StringUtil.isBlank(pubkey)) {
      pubkey = RouterUtil.routerArgs(context) as String?;
      if (StringUtil.isBlank(pubkey)) {
        RouterUtil.back(context);
        return Container();
      }
      var events = followEventProvider.eventsByPubkey(pubkey!);
      if (events.isNotEmpty) {
        box.addList(events);
      }
    } else {
      var arg = RouterUtil.routerArgs(context);
      if (arg != null && arg is String) {
        if (arg != pubkey) {
          // arg change! reset.
          box.clear();
          until = null;

          pubkey = arg;
          doQuery();
          updateUserdata();
        }
      }
    }
    preBuild();

    var paddingTop = mediaDataCache.padding.top;
    var maxWidth = mediaDataCache.size.width;

    showTitleHeight = maxWidth / 3 + 50;
    showAppbarBGHeight = showTitleHeight + 100;

    final themeData = Theme.of(context);

    return Selector<UserProvider, User?>(
      shouldRebuild: (previous, next) {
        return previous != next;
      },
      selector: (context, metadataProvider) {
        return userProvider.getUser(pubkey!);
      },
      builder: (context, user, child) {
        Widget? appbarTitle;
        if (showTitle) {
          String displayName = SimpleNameWidget.getSimpleName(pubkey!, user);

          appbarTitle = Container(
            alignment: Alignment.center,
            child: Text(
              displayName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: themeData.textTheme.bodyLarge!.fontSize,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }
        var appBar = Appbar4Stack(
          title: appbarTitle,
          actions: [
            // Report user button
            IconButton(
              icon: const Icon(Icons.flag),
              onPressed: () {
                _reportUser();
              },
              tooltip: "Report user",
            ),
            // Refresh profile button
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _refreshUserProfile();
              },
              tooltip: "Refresh profile",
            ),
          ],
        );

        Widget main = NestedScrollView(
          key: globalKey,
          controller: _controller,
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverToBoxAdapter(
                child: UserMetadataWidget(
                  pubkey: pubkey!,
                  user: user,
                  showBadges: true,
                  userPicturePreview: true,
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(bottom: Base.basePaddingHalf),
                  color: themeData.cardColor,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: UserStatisticsWidget(
                      pubkey: pubkey!,
                    ),
                  ),
                ),
              ),
            ];
          },
          body: MediaQuery.removePadding(
            removeTop: true,
            context: context,
            child: ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                var event = box.get(index);
                if (event == null) {
                  return null;
                }
                return EventListWidget(
                  event: event,
                  showVideo:
                      settingsProvider.videoPreviewInList != OpenStatus.close,
                );
              },
              itemCount: box.length(),
            ),
          ),
        );

      // Fixed app bar at the top of the screen
        List<Widget> mainList = [
          main,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: paddingTop),
              decoration: BoxDecoration(
                color: themeData.customColors.navBgColor,
                border: Border(
                  bottom:
                      BorderSide(color: themeData.customColors.separatorColor),
                ),
              ),
              child: SizedBox(
                height: Appbar4Stack.height,
                child: appBar,
              ),
            ),
          ),
        ];

        if (dataSyncMode) {
          mainList.add(Positioned(
            right: Base.basePadding * 5,
            bottom: Base.basePadding * 4,
            child: GestureDetector(
              onTap: beginToDown,
              child: const Icon(Icons.cloud_download),
            ),
          ));

          mainList.add(Positioned(
            right: Base.basePadding * 2,
            bottom: Base.basePadding * 4,
            child: GestureDetector(
              onTap: broadcaseAll,
              child: const Icon(Icons.cloud_upload),
            ),
          ));
        }

        return Scaffold(
            body: Stack(
          children: mainList,
        ));
      },
    );
  }

  String? subscribeId;

  @override
  Future<void> onReady(BuildContext context) async {
    doQuery();

    if (globalKey.currentState != null) {
      var controller = globalKey.currentState!.innerController;
      controller.addListener(() {
        loadMoreScrollCallback(controller);
      });
    }

    updateUserdata();
  }

  /// Updates user data with both standard and reliable relay lookup.
  /// 
  /// This method attempts to fetch the latest user profile data
  /// using both the regular update mechanism and our reliable relay lookup.
  /// The reliable relay lookup is especially useful when the user profile
  /// can't be found in the standard relay set.
  void updateUserdata() {
    // Try to force a profile refresh from reliable relays
    // This will fetch profile data in the background without blocking the UI
    userProvider.forceProfileRefresh(pubkey!);
    
    // Also schedule a standard update (this is added to a queue)
    userProvider.update(pubkey!);
  }

  void onEvent(event) {
    if (event.pubkey != pubkey) {
      return;
    }

    later(event, (list) {
      box.addList(list);
      setState(() {});
    }, null);
  }

  @override
  void dispose() {
    super.dispose();
    disposeLater();

    if (StringUtil.isNotBlank(subscribeId)) {
      try {
        nostr!.unsubscribe(subscribeId!);
      } catch (e) {
        log("unsubscribe error: $e");
      }
    }

    closeLoading();
  }

  void unSubscribe() {
    nostr!.unsubscribe(subscribeId!);
    subscribeId = null;
  }
  
  /// Refreshes the user profile data from reliable relays
  /// and shows a notification to the user.
  /// 
  /// This can be triggered manually by the user via the refresh button.
  Future<void> _refreshUserProfile() async {
    // Show a loading indicator
    BotToast.showLoading();
    
    try {
      // Force a profile refresh from reliable relays
      final success = await userProvider.forceProfileRefresh(pubkey!);
      
      // Hide the loading indicator
      BotToast.closeAllLoading();
      
      // Show a success or failure message
      if (success) {
        BotToast.showText(text: "Profile refreshed successfully");
      } else {
        BotToast.showText(text: "Could not find profile on reliable relays");
        
        // If reliable relays didn't have the profile, try standard relays
        userProvider.update(pubkey!);
      }
    } catch (e) {
      // Hide the loading indicator and show error
      BotToast.closeAllLoading();
      BotToast.showText(text: "Error refreshing profile: $e");
    }
  }

  @override
  void doQuery() {
    _doQuery(onEventFunc: onEvent);
  }

  void _doQuery({Function(Event)? onEventFunc}) {
    onEventFunc ??= onEvent;

    preQuery();
    if (StringUtil.isNotBlank(subscribeId)) {
      unSubscribe();
    }

    // load event from relay
    var filter = Filter(
      kinds: EventKind.supportedEvents,
      until: until,
      authors: [pubkey!],
      limit: queryLimit,
    );
    subscribeId = StringUtil.rndNameStr(16);

    if (!box.isEmpty() && readyComplete) {
      // query after init
      var activeRelays = nostr!.activeRelays();
      var oldestCreatedAts = box.oldestCreatedAtByRelay(
        activeRelays,
      );
      Map<String, List<Map<String, dynamic>>> filtersMap = {};
      for (var relay in activeRelays) {
        var oldestCreatedAt = oldestCreatedAts.createdAtMap[relay.url];
        filter.until = oldestCreatedAt;
        filtersMap[relay.url] = [filter.toJson()];
      }
      nostr!.queryByFilters(filtersMap, onEventFunc, id: subscribeId);
    } else {
      // this is init query
      // try to query from user's write relay.
      List<String>? tempRelays =
          userProvider.getExtralRelays(pubkey!, true);
      // the init page set to very small, due to open user page very often
      filter.limit = 10;
      nostr!.query([filter.toJson()], onEventFunc,
          id: subscribeId, tempRelays: tempRelays);
    }

    readyComplete = true;
  }

  var oldEventLength = 0;

  void downloadAllOnEvent(Event e) {
    onEvent(e);
    whenStop(() {
      log("whenStop box length ${box.length()}");
      if (box.length() > oldEventLength) {
        oldEventLength = box.length();
        _doQuery(onEventFunc: downloadAllOnEvent);
      } else {
        // download complete
        unSubscribe();
        closeLoading();
      }
    });
  }

  Future<void> broadcaseAll() async {
    await SyncUploadDialog.show(context, box.all());
  }

  @override
  EventMemBox getEventBox() {
    return box;
  }

  CancelFunc? cancelFunc;

  // void beginToSyncAll() {
  //   cancelFunc = BotToast.showLoading();
  //   oldEventLength = box.length();
  //   _doQuery(onEventFunc: syncAllOnEvent);
  // }

  void closeLoading() {
    if (cancelFunc != null) {
      try {
        cancelFunc!.call();
        cancelFunc = null;
      } catch (e) {
        log("cancelFunc error: $e");
      }
    }
  }

  void beginToDown() {
    cancelFunc = BotToast.showLoading();
    oldEventLength = box.length();
    _doQuery(onEventFunc: downloadAllOnEvent);
  }

  /// Shows the report user dialog and handles the user report submission.
  Future<void> _reportUser() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const ReportUserDialog(),
    );
    
    if (result != null && mounted) {
      final reason = result['reason'];
      final details = result['details'];
      
      logger.i('Creating report for user: $pubkey', null, null, LogCategory.core);
      logger.d('Report reason: $reason, details: $details', null, null, LogCategory.core);

      try {
        // Build tags for the report event
        List<List<String>> tags = [
          ["p", pubkey!], // The pubkey of the reported user
        ];
        
        // Add reason and details to tags
        if (reason != null && reason.isNotEmpty) {
          tags.add(["reason", reason]);
        }
        if (details != null && details.isNotEmpty) {
          tags.add(["details", details]);
        }
        
        logger.d('Constructing user report event with tags: $tags', null, null, LogCategory.network);
        
        // Create the report event (NIP-56)
        var reportEvent = Event(
          nostr!.publicKey,
          1984, // NIP-56 report event kind
          tags,
          '', // No content needed, all info in tags
        );
        
        logger.d('Signing user report event', null, null, LogCategory.network);
        await nostr!.signEvent(reportEvent);
        
        // Default to user's relays
        List<String> relayAddrs = userProvider.getExtralRelays(pubkey!, false);
        
        logger.i('Sending user report event to relays: ${relayAddrs.isEmpty ? "default relays" : relayAddrs.join(", ")}', 
            null, null, LogCategory.network);
        
        // Send the event
        var sent = await nostr!.sendEvent(
          reportEvent,
          tempRelays: relayAddrs.isEmpty ? null : relayAddrs,
          targetRelays: relayAddrs.isEmpty ? null : relayAddrs,
        );
        
        if (sent != null) {
          logger.i('User report event successfully published, ID: ${reportEvent.id}', null, null, LogCategory.network);
          if (mounted) {
            BotToast.showText(text: "Report submitted to community organizers");
          }
        } else {
          logger.e('Failed to publish user report event', null, null, LogCategory.network);
          if (mounted) {
            BotToast.showText(text: "${S.of(context).error}: Failed to submit report to community organizers");
          }
        }
      } catch (e, stackTrace) {
        logger.e('Error creating or sending user report event', e, stackTrace, LogCategory.network);
        if (mounted) {
          BotToast.showText(text: "Error sending report: $e");
        }
      }
    }
  }
}
