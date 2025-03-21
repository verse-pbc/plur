import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/nip05_valid_widget.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../data/metadata.dart';
import '../../main.dart';
import '../../provider/group_provider.dart';
import '../../provider/metadata_provider.dart';
import '../../util/router_util.dart';
import 'search_mention_widget.dart';

class SearchMentionUserWidget extends StatefulWidget {
  final GroupIdentifier? groupIdentifier;

  const SearchMentionUserWidget({
    super.key,
    this.groupIdentifier,
  });

  @override
  State<StatefulWidget> createState() {
    return _SearchMentionUserWidgetState();
  }
}

class _SearchMentionUserWidgetState extends State<SearchMentionUserWidget> {
  static const int searchMemLimit = 100;
  double _itemWidth = 50;

  List<Metadata> _metadatas = [];
  List<Metadata?> _allMemberMetadatas = [];

  @override
  void initState() {
    super.initState();
    _loadMemberMetadata();
  }

  Future<void> _loadMemberMetadata() async {
    final groupId = widget.groupIdentifier;
    if (groupId == null) {
      return;
    }

    // Get the group members
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final groupMembers = groupProvider.getMembers(groupId);
    final memberPubkeys = groupMembers?.members;
    if (memberPubkeys == null || memberPubkeys.isEmpty) {
      return;
    }

    // Initialize the metadata list with nulls to maintain order
    setState(() {
      _allMemberMetadatas = List.filled(memberPubkeys.length, null);
    });

    // Load metadata for each member
    final metadataProvider = Provider.of<MetadataProvider>(context, listen: false);
    for (int i = 0; i < memberPubkeys.length; i++) {
      final pubkey = memberPubkeys[i];

      Metadata? initialMetadata = metadataProvider.getMetadata(pubkey);
      if (initialMetadata != null) {
        _allMemberMetadatas[i] = initialMetadata;
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var contentWidth = mediaDataCache.size.width - 4 * Base.basePadding;
    _itemWidth = (contentWidth - 10) / 2;

    return SearchMentionWidget(
      resultBuildFunc: _resultBuild,
      handleSearchFunc: _handleSearch,
    );
  }

  Widget _resultBuild() {
    if (_metadatas.isEmpty) {
     return const Center(
       child: CircularProgressIndicator(),
     );
    }

    final userWidgetList = _metadatas.map(
          (metadata) => SearchMentionUserItemWidget(
        metadata: metadata,
        width: _itemWidth,
      ),
    ).toList();

    return SingleChildScrollView(
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.only(
          top: Base.basePaddingHalf,
          bottom: Base.basePaddingHalf,
        ),
        child: SizedBox(
          width: _itemWidth * 2 + 10,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: userWidgetList,
          ),
        ),
      ),
    );
  }

  void _handleSearch(String? text) {
    _metadatas.clear();

    if (text == null || text.isEmpty) {
      _metadatas = _allMemberMetadatas.whereType<Metadata>().toList();
    } else {
      final metadataProvider = Provider.of<MetadataProvider>(context, listen: false);
      _metadatas = metadataProvider.findUser(text, limit: searchMemLimit);
    }

    setState(() {});
  }
}

class SearchMentionUserItemWidget extends StatelessWidget {
  static const double IMAGE_WIDTH = 36;

  final Metadata metadata;
  final double width;

  const SearchMentionUserItemWidget({
    super.key,
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
      padding: const EdgeInsets.all(Base.basePaddingHalf),
      child: Row(
        children: [
          UserPicWidget(
            pubkey: metadata.pubkey!,
            width: IMAGE_WIDTH,
            metadata: metadata,
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: Base.basePaddingHalf),
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
