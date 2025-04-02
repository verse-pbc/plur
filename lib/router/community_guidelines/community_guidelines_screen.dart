import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../component/appbar_bottom_border.dart';
import '../../generated/l10n.dart';
import '../../util/router_util.dart';
import '../../util/theme_util.dart';
import 'community_guidelines_controller.dart';

/// A screen that displays and allows editing of the community guidelines for a
/// group.
class CommunityGuidelinesScreen extends ConsumerStatefulWidget {
  const CommunityGuidelinesScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _CommunityGuidelinesScreenState();
  }
}

class _CommunityGuidelinesScreenState
    extends ConsumerState<CommunityGuidelinesScreen> {
  /// Holds the state of the text input.
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final accentColor = customColors.accentColor;
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
    final controller = ref.watch(communityGuidelinesControllerProvider(id));
    final isSaveDisabled = controller.isLoading || controller.hasError;
    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        bottom: const AppBarBottomBorder(),
        title: Text(
          localization.Community_Guidelines,
          style: TextStyle(
            fontSize: bodyLargeFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: isSaveDisabled ? null : () => _save(id),
            style: TextButton.styleFrom(
              foregroundColor: accentColor,
              disabledForegroundColor: accentColor.withOpacity(0.4),
            ),
            child: Text(
              localization.Save,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      body: controller.when(
        data: (value) {
          _descriptionController.text = value;
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
      ),
    );
  }

  /// Saves current input.
  void _save(GroupIdentifier id) {
    final provider = communityGuidelinesControllerProvider(id);
    final controller = ref.read(provider.notifier);
    controller.save(_descriptionController.text);
  }
}
