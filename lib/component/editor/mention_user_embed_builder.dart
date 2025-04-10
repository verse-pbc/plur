import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../content/content_mention_user_widget.dart';
import 'cust_embed_types.dart';

class MentionUserEmbedBuilder extends EmbedBuilder {
  @override
  bool get expanded => false;

  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle textStyle) {
    var pubkey = node.value.data;
    return AbsorbPointer(
      child: Container(
        margin: const EdgeInsets.only(
          left: 4,
          right: 4,
        ),
        child: ContentMentionUserWidget(pubkey: pubkey),
      ),
    );
  }

  @override
  String get key => CustEmbedTypes.mentionUser;
}
