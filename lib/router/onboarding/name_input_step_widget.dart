import 'package:flutter/material.dart';
import '../../generated/l10n.dart';
import '../../util/theme_util.dart';
import 'utils/name_generator.dart';
import '../../consts/base.dart';
import '../../component/primary_button_widget.dart';

/// Handles name/nickname collection in the onboarding process.
class NameInputStepWidget extends StatefulWidget {
  final void Function(String name) onContinue;

  const NameInputStepWidget({
    super.key,
    required this.onContinue,
  });

  @override
  State<NameInputStepWidget> createState() => _NameInputStepWidgetState();
}

class _NameInputStepWidgetState extends State<NameInputStepWidget> {
  final TextEditingController _nameController = TextEditingController();
  bool _isButtonEnabled = false;
  final _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateButtonState);
    _generateRandomName();
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateButtonState);
    _nameController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    final newState = _nameController.text.trim().isNotEmpty;
    if (_isButtonEnabled != newState) {
      setState(() {
        _isButtonEnabled = newState;
      });
    }
  }

  void _generateRandomName() {
    _nameController.text = NameGenerator.generateRandomName();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final localization = S.of(context);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: Base.maxScreenWidth),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 48),
            Text(
              localization.onboarding_name_input_title,
              key: const Key('name_input_title'),
              style: TextStyle(
                color: themeData.customColors.primaryForegroundColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: themeData.customColors.primaryForegroundColor
                    .withOpacity(0.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 12),
                    child: Text(
                      'Your Nickname',
                      style: TextStyle(
                        color: themeData.customColors.primaryForegroundColor
                            .withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextField(
                    controller: _nameController,
                    style: TextStyle(
                        color: themeData.customColors.primaryForegroundColor),
                    decoration: InputDecoration(
                      hintText: localization.onboarding_name_input_hint,
                      hintStyle: TextStyle(
                          color: themeData.customColors.primaryForegroundColor
                              .withOpacity(0.3)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      suffixIcon: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: themeData.customColors.dimmedColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Icon(Icons.refresh,
                              color: themeData
                                  .customColors.primaryForegroundColor),
                        ),
                        onPressed: _generateRandomName,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Tip: Use a random name or create your own. This name may be visible in your communities.',
                style: TextStyle(
                  color: themeData.customColors.secondaryForegroundColor,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
            const Spacer(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: PrimaryButtonWidget(
                  text: localization.Continue,
                  borderRadius: 4,
                  enabled: _isButtonEnabled && !_isLoading,
                  onTap: () {
                    final name = _nameController.text.trim();
                    if (name.isNotEmpty) {
                      widget.onContinue(name);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
