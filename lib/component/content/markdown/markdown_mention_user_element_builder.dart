import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/content/content_mention_user_widget.dart';

class MarkdownMentionUserElementBuilder implements MarkdownElementBuilder {
  static const String tag = "mentionUser";

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return null;
  }

  @override
  void visitElementBefore(md.Element element) {}

  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) {
    return null;
  }

  @override
  Widget? visitElementAfterWithContext(BuildContext context, md.Element element,
      TextStyle? preferredStyle, TextStyle? parentStyle) {
    var pureText = element.textContent;
    var nip19Text = pureText.replaceFirst("nostr:", "");

    String? key;
    if (Nip19.isPubkey(nip19Text)) {
      key = Nip19.decode(nip19Text);
    } else if (NIP19Tlv.isNprofile(nip19Text)) {
      var nprofile = NIP19Tlv.decodeNprofile(nip19Text);
      if (nprofile != null) {
        key = nprofile.pubkey;
      }
    }

    if (key != null) {
      return ContentMentionUserWidget(pubkey: key);
    }
    return null;
  }

  @override
  bool isBlockElement() {
    return false;
  }
}
