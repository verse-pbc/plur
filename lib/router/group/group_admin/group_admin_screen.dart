import 'package:flutter/material.dart';
import 'package:nostrmo/util/theme_util.dart';

import '../../../component/appbar_back_btn_widget.dart';
import '../../../generated/l10n.dart';
import 'group_admin_widget.dart';

class GroupAdminScreen extends StatelessWidget {
  const GroupAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final localization = S.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        title: Text(
          localization.Admin_Panel,
          style: TextStyle(
            color: themeData.customColors.primaryForegroundColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: const GroupAdminWidget(),
    );
  }
}
