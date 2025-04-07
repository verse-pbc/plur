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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button in top left
        Align(
          alignment: Alignment.topLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Go back to the option selection screen
              FocusScope.of(context).unfocus();
              Navigator.of(context).maybePop();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 24,
          ),
        ),
        const SizedBox(height: 10),
        
        const Text(
          "Create your community",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 20),
        const Text("Name your community"),
        const SizedBox(height: 10),
        TextField(
          controller: _communityNameController,
          decoration: const InputDecoration(
            hintText: "community name",
            border: OutlineInputBorder(),
          ),
          onChanged: (text) {
            setState(() {});
          },
        ),
        const SizedBox(height: 20),
        PrimaryButtonWidget(
          text: S.of(context).Confirm,
          onTap: _communityNameController.text.isNotEmpty
              ? () => widget.onCreateCommunity(_communityNameController.text)
              : null,
          enabled: _communityNameController.text.isNotEmpty,
        ),
      ],
    );
  }
}
