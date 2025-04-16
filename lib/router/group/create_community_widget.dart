import 'package:flutter/material.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/component/primary_button_widget.dart';

class CreateCommunityWidget extends StatefulWidget {
  final void Function(String) onCreateCommunity;

  const CreateCommunityWidget({super.key, required this.onCreateCommunity});

  @override
  State<CreateCommunityWidget> createState() => _CreateCommunityWidgetState();
}

class _CreateCommunityWidgetState extends State<CreateCommunityWidget> {
  final TextEditingController _communityNameController =
      TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              localization.createYourCommunity,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(localization.nameYourCommunity),
            const SizedBox(height: 10),
            TextField(
              controller: _communityNameController,
              decoration: InputDecoration(
                hintText: localization.communityName,
                border: const OutlineInputBorder(),
              ),
              onChanged: (text) {
                setState(() {});
              },
            ),
            const SizedBox(height: 20),
            PrimaryButtonWidget(
              text: S.of(context).confirm,
              onTap: _communityNameController.text.isNotEmpty
                  ? _createCommunity
                  : null,
              enabled: _communityNameController.text.isNotEmpty,
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

    widget.onCreateCommunity(_communityNameController.text);
    // No need to set _isLoading back to false as we'll transition to the next screen
  }
}
