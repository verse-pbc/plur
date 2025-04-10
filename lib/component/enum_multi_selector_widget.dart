import 'package:flutter/material.dart';
import 'package:nostrmo/component/enum_selector_widget.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/router_util.dart';

import '../consts/base_consts.dart';

class EnumMultiSelectorWidget extends StatefulWidget {
  final List<EnumObj> list;

  final List<EnumObj> values;

  const EnumMultiSelectorWidget({super.key, 
    required this.list,
    required this.values,
  });

  static Future<List<EnumObj>?> show(
      BuildContext context, List<EnumObj> list, List<EnumObj> values) async {
    return await showDialog<List<EnumObj>?>(
      context: context,
      useRootNavigator: false,
      builder: (_) {
        return EnumMultiSelectorWidget(
          list: list,
          values: values,
        );
      },
    );
  }

  @override
  State<StatefulWidget> createState() {
    return _EnumMultiSelectorWidgetState();
  }
}

class _EnumMultiSelectorWidgetState extends State<EnumMultiSelectorWidget> {
  double btnWidth = 50;

  late List<EnumObj> values;

  @override
  void initState() {
    super.initState();
    values = widget.values;
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var btnTextColor = themeData.appBarTheme.titleTextStyle!.color;

    return Stack(
      alignment: Alignment.center,
      children: [
        EnumSelectorWidget(list: widget.list, enumItemBuild: enumItemBuild),
        Positioned(
          bottom: mediaDataCache.size.height / 20,
          child: GestureDetector(
            onTap: () {
              return RouterUtil.back(context, values);
            },
            child: Container(
              width: btnWidth,
              height: btnWidth,
              decoration: BoxDecoration(
                color: mainColor,
                borderRadius: BorderRadius.circular(btnWidth / 2),
              ),
              child: Icon(
                Icons.done,
                color: btnTextColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget enumItemBuild(BuildContext context, EnumObj enumObj) {
    bool isLast = false;
    if (enumObj.value == widget.list.last.value) {
      isLast = true;
    }

    bool exist = false;
    for (var value in values) {
      if (value.value == enumObj.value) {
        exist = true;
      }
    }

    return EnumSelectorItemWidget(
      enumObj: enumObj,
      isLast: isLast,
      onTap: onTap,
      color: exist ? Colors.blue.withOpacity(0.2) : null,
    );
  }

  void onTap(EnumObj enumObj) {
    bool exist = false;
    for (var value in values) {
      if (value.value == enumObj.value) {
        exist = true;
      }
    }

    if (exist) {
      values.removeWhere((element) {
        return element.value == enumObj.value;
      });
    } else {
      values.add(enumObj);
    }

    setState(() {});
  }
}
