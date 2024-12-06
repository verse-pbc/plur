import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip19/nip19.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/data/metadata.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
import 'package:provider/provider.dart';

class SimpleNameWidget extends StatefulWidget {
  static String getSimpleName(String pubkey, Metadata? metadata) {
    String? name;
    if (metadata != null) {
      if (StringUtil.isNotBlank(metadata.displayName)) {
        name = metadata.displayName;
      } else if (StringUtil.isNotBlank(metadata.name)) {
        name = metadata.name;
      }
    }
    if (StringUtil.isBlank(name)) {
      name = Nip19.encodeSimplePubKey(pubkey);
    }

    return name!;
  }

  String pubkey;

  Metadata? metadata;

  TextStyle? textStyle;

  int? maxLines;

  TextOverflow? textOverflow;

  SimpleNameWidget({
    required this.pubkey,
    this.metadata,
    this.textStyle,
    this.maxLines,
    this.textOverflow,
  });

  @override
  State<StatefulWidget> createState() {
    return _SimpleNameWidgetState();
  }
}

class _SimpleNameWidgetState extends State<SimpleNameWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.metadata != null) {
      return buildWidget(widget.metadata);
    }

    return Selector<MetadataProvider, Metadata?>(
        builder: (context, metadata, child) {
      return buildWidget(metadata);
    }, selector: (_, provider) {
      return provider.getMetadata(widget.pubkey);
    });
  }

  Widget buildWidget(Metadata? metadata) {
    var name = SimpleNameWidget.getSimpleName(widget.pubkey, metadata);
    return Text(
      name,
      style: widget.textStyle,
      maxLines: widget.maxLines,
      overflow: widget.textOverflow,
    );
  }
}
