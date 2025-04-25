import 'package:flutter/material.dart';

import '../../component/primary_button_widget.dart';
import '../../generated/l10n.dart';
import 'privacy_selection_widget.dart';

class CreateCommunityWidget extends StatefulWidget {
  final void Function(String, CommunityPrivacy) onCreateCommunity;

  const CreateCommunityWidget({super.key, required this.onCreateCommunity});

  @override
  State<CreateCommunityWidget> createState() => _CreateCommunityWidgetState();
}

class _CreateCommunityWidgetState extends State<CreateCommunityWidget> {
  final TextEditingController _communityNameController =
      TextEditingController();
  bool _isLoading = false;
  CommunityPrivacy? _selectedPrivacy;

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localization.Create_your_community,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              localization.Name_your_community,
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _communityNameController,
              decoration: InputDecoration(
                hintText: localization.community_name,
                border: const OutlineInputBorder(),
              ),
              onChanged: (text) {
                setState(() {});
              },
            ),
            const SizedBox(height: 30),
            PrivacySelectionWidget(
              selectedPrivacy: _selectedPrivacy,
              onPrivacySelected: (privacy) {
                setState(() {
                  _selectedPrivacy = privacy;
                });
              },
            ),
            const SizedBox(height: 30),
            PrimaryButtonWidget(
              text: localization.Confirm,
              onTap: (_communityNameController.text.isNotEmpty &&
                      _selectedPrivacy != null &&
                      !_isLoading)
                  ? _createCommunity
                  : null,
              enabled: _communityNameController.text.isNotEmpty &&
                  _selectedPrivacy != null &&
                  !_isLoading,
            ),
          ],
        ),
      ),
    );
  }

  void _createCommunity() {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    widget.onCreateCommunity(_communityNameController.text, _selectedPrivacy!);
  }
}
