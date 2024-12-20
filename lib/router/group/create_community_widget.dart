import 'package:flutter/material.dart';
import 'package:nostrmo/generated/l10n.dart';

class CreateCommunityWidget extends StatefulWidget {
  final void Function(String) onCreateCommunity;

  const CreateCommunityWidget({super.key, required this.onCreateCommunity});

  @override
  State<CreateCommunityWidget> createState() => _CreateCommunityWidgetState();
}

enum CommunityVisibility {
  publicAnyone,
  publicRequest,
  privateRequest,
}

class _CreateCommunityWidgetState extends State<CreateCommunityWidget> {
  final TextEditingController _communityNameController =
      TextEditingController();
  CommunityVisibility selectedVisibility = CommunityVisibility.publicAnyone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        const Text("Select visibility and posting options:"),
        const SizedBox(height: 10),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Public + anyone can join and post"),
          leading: Radio<CommunityVisibility>(
            value: CommunityVisibility.publicAnyone,
            groupValue: selectedVisibility,
            onChanged: (value) {
              setState(() {
                selectedVisibility = value!;
              });
            },
          ),
          onTap: () {
            setState(() {
              selectedVisibility = CommunityVisibility.publicAnyone;
            });
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Public + request to join and post"),
          leading: Radio<CommunityVisibility>(
            value: CommunityVisibility.publicRequest,
            groupValue: selectedVisibility,
            onChanged: (value) {
              setState(() {
                selectedVisibility = value!;
              });
            },
          ),
          onTap: () {
            setState(() {
              selectedVisibility = CommunityVisibility.publicRequest;
            });
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Private + request to join"),
          leading: Radio<CommunityVisibility>(
            value: CommunityVisibility.privateRequest,
            groupValue: selectedVisibility,
            onChanged: (value) {
              setState(() {
                selectedVisibility = value!;
              });
            },
          ),
          onTap: () {
            setState(() {
              selectedVisibility = CommunityVisibility.privateRequest;
            });
          },
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: _communityNameController.text.isNotEmpty
              ? () => widget.onCreateCommunity(_communityNameController.text)
              : null,
          highlightColor: theme.primaryColor.withOpacity(0.2),
          child: Container(
            color: _communityNameController.text.isNotEmpty
                ? theme.primaryColor
                : theme.disabledColor,
            height: 40,
            alignment: Alignment.center,
            child: Text(
              S.of(context).Confirm,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}