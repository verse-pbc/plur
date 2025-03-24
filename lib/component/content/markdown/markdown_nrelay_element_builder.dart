import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
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
