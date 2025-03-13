import 'package:flutter/material.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';

class EventLoadListWidget extends StatelessWidget {
  const EventLoadListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var cardColor = themeData.cardColor;

    final localization = S.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: Base.basePaddingHalf),
      color: cardColor,
      height: 60,
      child: Center(child: Text(localization.Note_loading)),
    );
  }
}
