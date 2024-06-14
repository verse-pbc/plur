import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/translations.dart';
import 'package:nostrmo/component/webview_router.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/setting_provider.dart';
import 'package:nostrmo/provider/webview_provider.dart';
import 'package:nostrmo/util/platform_util.dart';
import 'package:provider/provider.dart';

import 'generated/l10n.dart';
import 'util/string_util.dart';

class HomeComponent extends StatefulWidget {
  Widget child;

  Locale? locale;

  ThemeData? theme;

  HomeComponent({
    required this.child,
    this.locale,
    this.theme,
  });

  @override
  State<StatefulWidget> createState() {
    return _HomeComponent();
  }
}

class _HomeComponent extends State<HomeComponent> {
  @override
  Widget build(BuildContext context) {
    PlatformUtil.init(context);
    var _webviewProvider = Provider.of<WebViewProvider>(context);
    var _settingProvider = Provider.of<SettingProvider>(context);

    Widget child = widget.child;
    if (StringUtil.isNotBlank(_settingProvider.backgroundImage)) {
      ImageProvider? image;
      if (_settingProvider.backgroundImage!.indexOf("http") == 0) {
        image = NetworkImage(_settingProvider.backgroundImage!);
      } else {
        image = FileImage(File(_settingProvider.backgroundImage!));
      }

      child = Container(
        decoration: BoxDecoration(
            image: DecorationImage(
          image: image,
          fit: BoxFit.cover,
        )),
        child: child,
      );
    }

    return MaterialApp(
      locale: widget.locale,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        S.delegate,
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      theme: widget.theme,
      home: Stack(
        children: [
          Positioned.fill(child: child),
          webViewProvider.url != null
              ? Positioned(
                  child: Offstage(
                  offstage: !_webviewProvider.showable,
                  child: WebViewRouter(url: _webviewProvider.url!),
                ))
              : Container()
        ],
      ),
    );
  }
}
