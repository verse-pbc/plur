import 'package:flutter/material.dart';

import '../consts/base.dart';
import '../consts/colors.dart';
import '../util/router_util.dart';

class ColorSelectorWidget extends StatelessWidget {
  const ColorSelectorWidget({super.key});

  static Future<Color?> show(BuildContext context) async {
    return await showDialog(
      context: context,
      useRootNavigator: false,
      builder: (_) {
        return const ColorSelectorWidget();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];
    for (var i = 0; i < ColorList.ALL_COLOR.length; i++) {
      var c = ColorList.ALL_COLOR[i];
      widgets.add(SliverToBoxAdapter(
        child: ColorSelectorItemWidget(
          color: c,
        ),
      ));
    }

    Widget main = Container(
        width: double.infinity,
        height: 100,
        padding: const EdgeInsets.only(
          left: Base.basePadding,
          right: Base.basePadding,
          top: Base.basePaddingHalf,
          bottom: Base.basePaddingHalf,
        ),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          color: Colors.white,
        ),
        child: CustomScrollView(
          scrollDirection: Axis.horizontal,
          slivers: widgets,
        ));

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.2),
      body: FocusScope(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            RouterUtil.back(context);
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.only(
              left: Base.basePadding,
              right: Base.basePadding,
            ),
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {},
              child: main,
            ),
          ),
        ),
      ),
    );
  }
}

class ColorSelectorItemWidget extends StatelessWidget {
  static const double HEIGHT = 44;

  final Color color;

  const ColorSelectorItemWidget({super.key,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        RouterUtil.back(context, color);
      },
      child: Container(
        margin: const EdgeInsets.all(Base.basePadding),
        alignment: Alignment.center,
        height: HEIGHT,
        child: Container(
          height: HEIGHT,
          width: HEIGHT,
          color: color,
        ),
      ),
    );
  }
}
