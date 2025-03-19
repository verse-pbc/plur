import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/music/music_info_builder.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/music_provider.dart';


BlankLinkMusicInfoBuilder blankLinkMusicInfoBuilder =
    BlankLinkMusicInfoBuilder();

class BlankLinkMusicInfoBuilder extends MusicInfoBuilder {
  @override
  Future<MusicInfo?> build(String content, String? eventId) async {
    String? imageUrl = "";
    String? name;
    if (StringUtil.isNotBlank(eventId)) {
      var event = singleEventProvider.getEvent(eventId!);
      if (event != null) {
        final user = metadataProvider.getUser(event.pubkey);
        if (user != null) {
          imageUrl = user.picture;
          name = user.name;
        }
      }
    }

    return MusicInfo("", eventId, content, name, content, imageUrl,
        sourceUrl: content);
  }

  @override
  bool check(String content) {
    return PathTypeUtil.getPathType(content) == "audio";
  }
}
