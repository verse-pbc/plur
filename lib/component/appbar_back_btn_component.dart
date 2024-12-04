import 'package:flutter/material.dart';

import '../util/router_util.dart';

class AppbarBackBtnWidget extends StatefulWidget {
  const AppbarBackBtnWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AppbarBackBtnWidgetState();
  }
}

class _AppbarBackBtnWidgetState extends State<AppbarBackBtnWidget> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);

    return GestureDetector(
      onTap: () {
        RouterUtil.back(context);
      },
      child: Icon(
        Icons.arrow_back_ios,
        color: themeData.appBarTheme.titleTextStyle!.color,
      ),
    );
  }
}
