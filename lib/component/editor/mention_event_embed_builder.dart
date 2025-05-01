import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../event/event_quote_widget.dart';
import 'cust_embed_types.dart';

class MentionEventEmbedBuilder extends EmbedBuilder {
  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    var id = embedContext.node.value.data;
    return AbsorbPointer(
      child: EventQuoteWidget(id: id),
    );
  }

  @override
  String get key => CustEmbedTypes.mentionEvent;
}
