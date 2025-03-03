import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/translations.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/webview_widget.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/settings_provider.dart';
import 'package:nostrmo/provider/webview_provider.dart';
import 'package:provider/provider.dart';

import 'generated/l10n.dart';

class HomeWidget extends StatefulWidget {
  Widget child;

  Locale? locale;

  ThemeData? theme;

  HomeWidget({
    super.key,
    required this.child,
    this.locale,
    this.theme,
  });

  @override
  State<StatefulWidget> createState() {
    return _HomeWidgetState();
  }
}

class _HomeWidgetState extends State<HomeWidget> {
  @override
  Widget build(BuildContext context) {
    PlatformUtil.init(context);
    var _webviewProvider = Provider.of<WebViewProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    Widget child = widget.child;
    if (StringUtil.isNotBlank(settingsProvider.backgroundImage)) {
      ImageProvider? image;
      if (settingsProvider.backgroundImage!.indexOf("http") == 0) {
        image = NetworkImage(settingsProvider.backgroundImage!);
      } else {
        image = FileImage(File(settingsProvider.backgroundImage!));
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
                  child: WebViewWidget(url: _webviewProvider.url!),
                ))
              : Container()
        ],
      ),
    );
  }
}
