import 'package:flutter/material.dart';

import '../consts/base.dart';
import '../consts/router_path.dart';
import '../util/router_util.dart';

class TagWidget extends StatelessWidget {
  final String tag;

  bool jumpable;

  TagWidget({
    required this.tag,
    this.jumpable = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;

    var main = Container(
      padding: EdgeInsets.only(
        left: Base.basePaddingHalf,
        right: Base.basePaddingHalf,
        top: 4,
        bottom: 4,
      ),
      decoration: BoxDecoration(
        color: mainColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    );

    if (!jumpable) {
      return main;
    }

    return GestureDetector(
      onTap: () {
        RouterUtil.router(context, RouterPath.TAG_DETAIL, tag);
      },
      child: main,
    );
  }
}
