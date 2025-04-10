import 'package:flutter/material.dart';

import 'index_drawer_content.dart';

class IndexPcDrawerWrapper extends StatefulWidget {
  final double fixWidth;

  const IndexPcDrawerWrapper({
    super.key,
    required this.fixWidth,
  });

  @override
  State<StatefulWidget> createState() {
    return _IndexPcDrawerWrapper();
  }
}

class _IndexPcDrawerWrapper extends State<IndexPcDrawerWrapper> {
  static const double smallWidth = 80;

  bool? smallMode;

  bool? forceSmallMode;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = widget.fixWidth;
    if (widget.fixWidth <= 170) {
      smallMode = true;
    } else {
      smallMode = false;
    }
    if (currentMode) {
      width = smallWidth;
    }

    return IndexPcDrawerWrapperCallback(
      toggle: toggleSize,
      child: SizedBox(
        width: width,
        child: IndexDrawerContent(
          smallMode: currentMode,
        ),
      ),
    );
  }

  bool get currentMode {
    return forceSmallMode != null ? forceSmallMode! : smallMode!;
  }

  void toggleSize() {
    if (forceSmallMode == null) {
      setState(() {
        forceSmallMode = !smallMode!;
      });
    } else {
      setState(() {
        forceSmallMode = !forceSmallMode!;
      });
    }
  }
}

class IndexPcDrawerWrapperCallback extends InheritedWidget {
  final Function toggle;

  const IndexPcDrawerWrapperCallback({super.key, required this.toggle, required super.child});

  static IndexPcDrawerWrapperCallback? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<IndexPcDrawerWrapperCallback>();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}
