import 'aid.dart';
import 'event.dart';
import 'event_kind.dart';
import 'nip19/nip19.dart';
import 'nip19/nip19_tlv.dart';
import 'nip94/file_metadata.dart';
import 'utils/spider_util.dart';
import 'nip29/group_identifier.dart';

/// This class is designed for get the relation from event, but it seam to used for get tagInfo from event before event_main display.
class EventRelation {
  late String id;

  late String pubkey;

  List<String> tagPList = [];

  List<String> tagEList = [];

  String? rootId;

  String? rootRelayAddr;

  String? replyId;

  String? replyRelayAddr;

  String? subject;

  bool warning = false;

  AId? aId;

  String? zapraiser;

  String? dTag;

  String? type;

  List<EventZapInfo> zapInfos = [];

  String? innerZapContent;

  Map<String, FileMetadata> fileMetadatas = {};

  /// The NIP-29 group id, if one is found in the tags.
  GroupIdentifier? groupIdentifier;

  String? get replyOrRootId {
    return replyId ?? rootId;
  }

  String? get replyOrRootRelayAddr {
    return replyId != null ? replyRelayAddr : rootRelayAddr;
  }

  /// Initializes the various fields on EventRelation from the given Event object.
  EventRelation.fromEvent(Event event) {
    id = event.id;
    pubkey = event.pubkey;

    Map<String, int> pMap = {};
    var length = event.tags.length;
    for (var i = 0; i < length; i++) {
      var tag = event.tags[i];

      var mentionStr = "#[$i]";
      if (event.content.contains(mentionStr)) {
        continue;
      }

      var tagLength = tag.length;
      if (tagLength > 1 && tag[1] is String) {
        var tagKey = tag[0];
        var value = tag[1] as String;
        switch (tagKey) {
          case "p":
            // check if is Text Note References
            var nip19Str = "nostr:${Nip19.encodePubKey(value)}";
            if (event.content.contains(nip19Str)) {
              continue;
            }
            nip19Str = NIP19Tlv.encodeNprofile(Nprofile(pubkey: value));
            if (event.content.contains(nip19Str)) {
              continue;
            }
            pMap[value] = 1;

          case "e":
            if (tagLength > 3) {
              var marker = tag[3];
              if (marker == "root") {
                rootId = value;
                rootRelayAddr = tag[2];
              } else if (marker == "reply") {
                replyId = value;
                replyRelayAddr = tag[2];
              } else if (marker == "mention") {
                continue;
              }
            }
            tagEList.add(value);

          case "subject":
            subject = value;

          case "content-warning":
            warning = true;

          case "a":
            aId = AId.fromString(value);

          case "zapraiser":
            zapraiser = value;

          case "d":
            dTag = value;

          case "type":
            type = value;

          case "zap":
            if (tagLength > 3) {
              var zapInfo = EventZapInfo.fromTags(tag);
              zapInfos.add(zapInfo);
            }

          case "description" when event.kind == EventKind.ZAP:
            innerZapContent = SpiderUtil.subUntil(value, '"content":"', '",');

          case "imeta":
            var fileMetadata = FileMetadata.fromNIP92Tag(tag);
            if (fileMetadata != null) {
              fileMetadatas[fileMetadata.url] = fileMetadata;
            }

          case "h" when event.sources.isNotEmpty:
            var groupId = value;
            var host = event.sources.first;
            groupIdentifier = GroupIdentifier(host, groupId);
        }
      }
    }

    var tagELength = tagEList.length;
    if (tagELength == 1 && rootId == null && replyId == null) {
      rootId = tagEList[0];
    } else if (tagELength > 1) {
      if (rootId == null && replyId == null) {
        rootId = tagEList.first;
        replyId = tagEList.last;
      } else if (rootId != null && replyId == null) {
        for (var i = tagELength - 1; i > -1; i--) {
          var id = tagEList[i];
          if (id != rootId) {
            replyId = id;
          }
        }
      } else if (rootId == null && replyId != null) {
        for (var i = 0; i < tagELength; i++) {
          var id = tagEList[i];
          if (id != replyId) {
            rootId = id;
          }
        }
      } else {
        rootId ??= tagEList.first;
        replyId ??= tagEList.last;
      }
    }

    if (rootId != null && replyId == rootId && rootRelayAddr == null) {
      rootRelayAddr = replyRelayAddr;
    }

    pMap.remove(event.pubkey);
    tagPList.addAll(pMap.keys);
  }

  static String getInnerZapContent(Event event) {
    String innerContent = "";
    for (var tag in event.tags) {
      var tagLength = tag.length;
      if (tagLength > 1) {
        var k = tag[0];
        var v = tag[1];
        if (k == "description") {
          innerContent = SpiderUtil.subUntil(v, '"content":"', '",');
          break;
        }
      }
    }

    return innerContent;
  }
}

class EventZapInfo {
  late String pubkey;

  late String relayAddr;

  late double weight;

  EventZapInfo(this.pubkey, this.relayAddr, this.weight);

  factory EventZapInfo.fromTags(List tag) {
    var pubkey = tag[1] as String;
    var relayAddr = tag[2] as String;
    var sourceWeight = tag[3];
    double weight = 1;
    if (sourceWeight is String) {
      weight = double.parse(sourceWeight);
    } else if (sourceWeight is double) {
      weight = sourceWeight;
    } else if (sourceWeight is int) {
      weight = sourceWeight.toDouble();
    }

    return EventZapInfo(pubkey, relayAddr, weight);
  }
}
