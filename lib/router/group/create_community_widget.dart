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
      children: [
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
