import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../component/appbar_bottom_border.dart';
import '../../data/group_metadata_repository.dart';
import '../../generated/l10n.dart';
import '../../util/router_util.dart';
import '../../util/theme_util.dart';

class CommunityGuidelinesScreen extends StatefulWidget {
  const CommunityGuidelinesScreen({super.key});

  @override
  State<StatefulWidget> createState() => _CommunityGuidelinesScreenState();
}

class _CommunityGuidelinesScreenState extends State<CommunityGuidelinesScreen> {
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final primaryForegroundColor = customColors.primaryForegroundColor;
    final secondaryForegroundColor = customColors.secondaryForegroundColor;
    const double cornerRadius = 8;
    const borderRadius = BorderRadius.all(Radius.circular(cornerRadius));
    final borderSide = BorderSide(color: secondaryForegroundColor);
    var bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;
    final localization = S.of(context);

    var arg = RouterUtil.routerArgs(context);
    if (arg == null || arg is! GroupIdentifier) {
      RouterUtil.back(context);
      return Container();
    }
    final id = arg;
    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        bottom: const AppBarBottomBorder(),
        title: Text(
          // TODO: Localize this
          "Community Guidelines",
          style: TextStyle(
            fontSize: bodyLargeFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer(builder: (context, ref, _) {
        final groupMetadata = ref.watch(groupMetadataProvider(id));
        return groupMetadata.when(
          data: (value) {
            _descriptionController.text = value?.communityGuidelines ?? "";
            return SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 26),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: localization.Description,
                        hintText: localization.Enter_Community_Description,
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: borderRadius,
                          borderSide: borderSide,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: borderRadius,
                          borderSide: borderSide,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: borderRadius,
                          borderSide: borderSide,
                        ),
                        labelStyle: TextStyle(color: primaryForegroundColor),
                      ),
                      maxLines: null,
                      minLines: 5,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                    ),
                  ),
                ],
              ),
            );
          },
          error: (error, stackTrace) => Center(child: ErrorWidget(error)),
          loading: () => const Center(child: CircularProgressIndicator()),
        );
      }),
    );
  }
}
