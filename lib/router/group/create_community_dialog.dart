import 'package:flutter/material.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';

class CreateCommunityDialog extends StatefulWidget {
  const CreateCommunityDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (_) {
        return const CreateCommunityDialog();
      },
    );
  }

  @override
  State<StatefulWidget> createState() {
    return _CreateCommunityDialogState();
  }
}

class _CreateCommunityDialogState extends State<CreateCommunityDialog> {
  final TextEditingController communityNameController = TextEditingController();
  String selectedVisibility = 'Public + anyone can join and post';

  late S localization;

  @override
  Widget build(BuildContext context) {
    localization = S.of(context);
    final themeData = Theme.of(context);
    Color cardColor = themeData.cardColor;

    List<Widget> dialogContent = [
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
        controller: communityNameController,
        decoration: const InputDecoration(
          hintText: "Field community name",
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
        leading: Radio<String>(
          value: "Public + anyone can join and post",
          groupValue: selectedVisibility,
          onChanged: (value) {
            setState(() {
              selectedVisibility = value!;
            });
          },
        ),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text("Public + request to join and post"),
        leading: Radio<String>(
          value: "Public + request to join and post",
          groupValue: selectedVisibility,
          onChanged: (value) {
            setState(() {
              selectedVisibility = value!;
            });
          },
        ),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text("Private + request to join"),
        leading: Radio<String>(
          value: "Private + request to join",
          groupValue: selectedVisibility,
          onChanged: (value) {
            setState(() {
              selectedVisibility = value!;
            });
          },
        ),
      ),
      const SizedBox(height: 20),
      InkWell(
        onTap: communityNameController.text.isNotEmpty ? _onCreateCommunity : null,
        highlightColor: Theme.of(context).primaryColor.withOpacity(0.2),
        child: Container(
          color: communityNameController.text.isNotEmpty ? Theme.of(context).primaryColor : Colors.grey,
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
    ];

    return Scaffold(
      backgroundColor: ThemeUtil.getDialogCoverColor(themeData),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              RouterUtil.back(context);
            },
            child: Container(
              color: Colors.black54,
            ),
          ),
          SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            RouterUtil.back(context);
                          },
                        ),
                      ),
                      ...dialogContent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onCreateCommunity() {
    final communityName = communityNameController.text;

    // Handle community creation logic here in next PR
    RouterUtil.back(context);
  }
}
