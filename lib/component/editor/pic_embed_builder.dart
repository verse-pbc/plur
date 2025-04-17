import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:nostrmo/consts/base64.dart';
import 'package:nostrmo/generated/l10n.dart';

import '../image_widget.dart';

class PicEmbedBuilder extends EmbedBuilder {
  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle textStyle) {
    var imageUrl = node.value.data as String;
    
    Widget child;
    if (imageUrl.indexOf("http") == 0 || imageUrl.indexOf(BASE64.prefix) == 0) {
      // network image
      child = ImageWidget(
        url: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => const CircularProgressIndicator(),
      );
    } else {
      // local image
      child = Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        Text(
          S.of(context).allMediaPublic,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
        ),
      ],
    );
  }

  @override
  String get key => BlockEmbed.imageType;
}
