import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../consts/nip05status.dart';
import '../provider/metadata_provider.dart';

class Nip05ValidWidget extends StatefulWidget {
  String pubkey;

  Nip05ValidWidget({super.key, required this.pubkey});

  @override
  State<StatefulWidget> createState() {
    return _Nip05ValidWidgetState();
  }
}

class _Nip05ValidWidgetState extends State<Nip05ValidWidget> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;

    return Selector<MetadataProvider, int>(
        builder: (context, nip05Status, child) {
      var iconData = Icons.check_circle;
      if (nip05Status == Nip05Status.NIP05_NOT_FOUND ||
          nip05Status == Nip05Status.METADATA_NOT_FOUND) {
        // iconData = Icons.error;
        return const SizedBox(
          width: 0,
          height: 0,
        );
      }

      Color iconColor = Colors.red;
      if (nip05Status == Nip05Status.NIP05_NOT_VALID) {
        iconColor = Colors.yellow;
      } else if (nip05Status == Nip05Status.NIP05_VALID) {
        iconColor = mainColor;
      }

      return Icon(
        iconData,
        color: iconColor,
        size: smallTextSize,
      );
    }, selector: (_, provider) {
      return provider.getNip05Status(widget.pubkey);
    });
  }
}
