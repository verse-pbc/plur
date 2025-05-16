import 'package:flutter/material.dart';

import '../consts/base.dart';
import '../theme/app_colors.dart';
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
    // Define available theme colors for selection
    final themeColors = [
      Colors.purple[700]!,
      Colors.blue[700]!,
      Colors.cyan[700]!,
      const Color(0xff519495),  // Custom teal
      Colors.yellow[700]!,
      Colors.orange[700]!,
      Colors.red[700]!,
    ];
    
    for (var i = 0; i < themeColors.length; i++) {
      var c = themeColors[i];
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
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(15)),
          color: context.colors.surface,
        ),
        child: CustomScrollView(
          scrollDirection: Axis.horizontal,
          slivers: widgets,
        ));

    return Scaffold(
      backgroundColor: Colors.black.withAlpha((255 * 0.2).round()),
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
  static const double height = 44;

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
        height: height,
        child: Container(
          height: height,
          width: height,
          color: color,
        ),
      ),
    );
  }
}
