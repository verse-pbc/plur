import 'package:nostrmo/component/content/trie_text_matcher/target_text_type.dart';

import 'trie_text_matcher.dart';

class TrieTextMatcherBuilder {
  static TrieTextMatcher build({Map<String, String>? emojiMap}) {
    TrieTextMatcher matcher = TrieTextMatcher();

    matcher.addNodes(TargetTextType.mdLink,
        [..."[".codeUnits, -1, ..."](".codeUnits, -1, ...")".codeUnits]);
    matcher.addNodes(TargetTextType.mdImage,
        [..."![".codeUnits, -1, ..."](".codeUnits, -1, ...")".codeUnits]);
    matcher.addNodes(
        TargetTextType.mdImage, [..."![](".codeUnits, -1, ...")".codeUnits]);
    matcher.addNodes(
        TargetTextType.mdBold, [..."**".codeUnits, -1, ..."**".codeUnits]);
    matcher.addNodes(
        TargetTextType.mdBold, [..."__".codeUnits, -1, ..."__".codeUnits]);
    matcher.addNodes(
        TargetTextType.mdItalic, [..."*".codeUnits, -1, ..."*".codeUnits]);
    matcher.addNodes(
        TargetTextType.mdItalic, [..."_".codeUnits, -1, ..."_".codeUnits]);
    matcher.addNodes(
        TargetTextType.mdDelete, [..."~~".codeUnits, -1, ..."~~".codeUnits]);
    matcher.addNodes(TargetTextType.mdHighlight,
        [..."==".codeUnits, -1, ..."==".codeUnits]);
    matcher.addNodes(TargetTextType.mdInlineCode,
        [..."`".codeUnits, -1, ..."`".codeUnits]);
    matcher.addNodes(TargetTextType.mdInlineCode,
        [..."```".codeUnits, -1, ..."```".codeUnits]);
    matcher.addNodes(TargetTextType.mdBoldAndItalic,
        [..."***".codeUnits, -1, ..."***".codeUnits]);

    if (emojiMap != null && emojiMap.isNotEmpty) {
      for (var emojiKey in emojiMap.keys) {
        matcher.addNodes(
            TargetTextType.nostrCustomEmoji, ":$emojiKey:".codeUnits,
            allowNoArg: true);
      }
    }

    return matcher;
  }
}
