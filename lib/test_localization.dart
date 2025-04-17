// Test file for checking localization keys
import 'package:flutter/material.dart';
import 'generated/l10n.dart';

class TestLocalization extends StatelessWidget {
  const TestLocalization({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    
    // Access using camelCase (proper Flutter convention)
    print(localization.cancel);
    print(localization.confirm);
    print(localization.discard);
    
    return Container();
  }
}