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
              localization.Create_your_community,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(localization.Name_your_community),
            const SizedBox(height: 10),
            TextField(
              controller: _communityNameController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: localization.community_name,
                border: const OutlineInputBorder(),
              ),
              onChanged: (text) {
                setState(() {});
              },
            ),
            const SizedBox(height: 20),
            _isLoading
                ? Container(
                    height: 48,
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(),
                    ),
                  )
                : PrimaryButtonWidget(
                    text: S.of(context).Confirm,
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
