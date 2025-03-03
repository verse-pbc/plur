import 'package:flutter/material.dart';
import 'package:nostrmo/consts/base.dart';

import '../generated/l10n.dart';

class NewNotesUpdatedWidget extends StatelessWidget {
  int num;

  Function? onTap;

  NewNotesUpdatedWidget({super.key, required this.num, this.onTap});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    Color? textColor = Colors.white;

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!();
        }
      },
      child: Container(
        padding: const EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: Base.BASE_PADDING,
          right: Base.BASE_PADDING,
        ),
        decoration: BoxDecoration(
          color: mainColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          "$num ${S.of(context).notes_updated}",
          style: TextStyle(color: textColor),
        ),
      ),
    );
  }
}
