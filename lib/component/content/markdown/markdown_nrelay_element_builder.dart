import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/painting/text_style.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/src/ast.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/content/content_mention_user_widget.dart';
import 'package:nostrmo/component/content/content_relay_widget.dart';

class MarkdownNrelayElementBuilder implements MarkdownElementBuilder {
  static const String TAG = "relay";

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
    if (NIP19Tlv.isNrelay(nip19Text)) {
      var nrelay = NIP19Tlv.decodeNrelay(nip19Text);
      if (nrelay != null) {
        key = nrelay.addr;
      }
    }

    if (key != null) {
      return ContentRelayWidget(key);
    }
    return null;
  }

  @override
  bool isBlockElement() {
    return false;
  }
}
