import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/event/event_quote_widget.dart';

class MarkdownMentionEventElementBuilder implements MarkdownElementBuilder {
  static const String tag = "mentionEvent";

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
    String? relayAddr;
    AId? aid;

    if (Nip19.isNoteId(nip19Text)) {
      key = Nip19.decode(nip19Text);
    } else if (NIP19Tlv.isNevent(nip19Text)) {
      var nevent = NIP19Tlv.decodeNevent(nip19Text);
      if (nevent != null) {
        key = nevent.id;
        if (nevent.relays != null && nevent.relays!.isNotEmpty) {
          relayAddr = nevent.relays![0];
        }
      }
    } else if (NIP19Tlv.isNaddr(nip19Text)) {
      var naddr = NIP19Tlv.decodeNaddr(nip19Text);
      if (naddr != null) {
        key = naddr.id;
        if (naddr.relays != null && naddr.relays!.isNotEmpty) {
          relayAddr = naddr.relays![0];
        }

        if (key.length > 64 && StringUtil.isNotBlank(naddr.author)) {
          aid = AId(kind: naddr.kind, pubkey: naddr.author, title: naddr.id);
          key = null;
        }
      }
    }

    if (key != null) {
      return EventQuoteWidget(
        id: key,
        aId: aid,
        eventRelayAddr: relayAddr,
      );
    }
    return null;
  }

  @override
  bool isBlockElement() {
    return true;
  }
}
