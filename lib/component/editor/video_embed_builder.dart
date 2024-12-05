import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../content/content_video_widget.dart';

class VideoEmbedBuilder extends EmbedBuilder {
  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle textStyle) {
    var url = node.value.data as String;
    return ContentVideoWidget(url: url);
  }

  @override
  String get key => BlockEmbed.videoType;
}
