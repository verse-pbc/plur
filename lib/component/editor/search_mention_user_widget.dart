import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/nip05_valid_widget.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';

import '../../consts/base.dart';
import '../../data/metadata.dart';
import '../../main.dart';
import '../../util/router_util.dart';
import 'search_mention_widget.dart';

class SearchMentionUserWidget extends StatefulWidget {
  const SearchMentionUserWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SearchMentionUserWidgetState();
  }
}

class _SearchMentionUserWidgetState extends State<SearchMentionUserWidget>
    with WhenStopFunction {
  double itemWidth = 50;

  @override
  Widget build(BuildContext context) {
    var contentWidth = mediaDataCache.size.width - 4 * Base.BASE_PADDING;
    itemWidth = (contentWidth - 10) / 2;

    return SearchMentionWidget(
      resultBuildFunc: resultBuild,
      handleSearchFunc: handleSearch,
    );
  }

  Widget resultBuild() {
    List<Widget> userWidgetList = [];
    for (var metadata in metadatas) {
      userWidgetList.add(SearchMentionUserItemWidget(
        metadata: metadata,
        width: itemWidth,
      ));
    }
    return SingleChildScrollView(
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.only(
          top: Base.BASE_PADDING_HALF,
          bottom: Base.BASE_PADDING_HALF,
        ),
        child: SizedBox(
          width: itemWidth * 2 + 10,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: userWidgetList,
          ),
        ),
      ),
    );
  }

  static const int searchMemLimit = 100;

  List<Metadata> metadatas = [];

  void handleSearch(String? text) {
    metadatas.clear();

    if (StringUtil.isNotBlank(text)) {
      var list = metadataProvider.findUser(text!, limit: searchMemLimit);
      metadatas = list;
    }

    setState(() {});
  }
}

class SearchMentionUserItemWidget extends StatelessWidget {
  static const double IMAGE_WIDTH = 36;

  Metadata metadata;

  double width;

  SearchMentionUserItemWidget({
    required this.metadata,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var cardColor = themeData.cardColor;

    String nip19Name = Nip19.encodeSimplePubKey(metadata.pubkey!);
    String displayName = nip19Name;
    if (StringUtil.isNotBlank(metadata.displayName)) {
      displayName = metadata.displayName!;
    } else {
      if (StringUtil.isNotBlank(metadata.name)) {
        displayName = metadata.name!;
      }
    }

    var nip05Text = metadata.nip05;
    if (StringUtil.isBlank(nip05Text)) {
      nip05Text = nip19Name;
    }

    var main = Container(
      width: width,
      color: cardColor,
      padding: const EdgeInsets.all(Base.BASE_PADDING_HALF),
      child: Row(
        children: [
          UserPicWidget(
            pubkey: metadata.pubkey!,
            width: IMAGE_WIDTH,
            metadata: metadata,
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: Base.BASE_PADDING_HALF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: nip05Text,
                          style: TextStyle(
                            fontSize: themeData.textTheme.bodySmall!.fontSize,
                            color: themeData.hintColor,
                          ),
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.ideographic,
                          child: Container(
                            margin: const EdgeInsets.only(left: 3),
                            child:
                                Nip05ValidWidget(pubkey: metadata.pubkey!),
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () {
        RouterUtil.back(context, metadata.pubkey);
      },
      child: main,
    );
  }
}
