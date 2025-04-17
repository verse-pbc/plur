import 'package:flutter/material.dart';
import 'package:nostrmo/util/router_util.dart';

import '../generated/l10n.dart';

class ConfirmDialog {
  static Future<bool?> show(BuildContext context, String content) async {
    final localization = S.of(context);
    return await showDialog<bool>(
        context: context,
        useRootNavigator: false,
        builder: (context) {
          return AlertDialog(
            title: Text(localization.notice),
            content: Text(content),
            actions: <Widget>[
              TextButton(
                child: Text(localization.cancel),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
              TextButton(
                child: Text(localization.confirm),
                onPressed: () async {
                  RouterUtil.back(context, true);
                },
              ),
            ],
          );
        });
  }
}
