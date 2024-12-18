import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InviteCommunityWidget extends StatelessWidget {
  final String shareableLink;

  const InviteCommunityWidget({super.key, required this.shareableLink});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invite people to join your community',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    text: shareableLink,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                      decorationColor:
                          theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: shareableLink));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied to clipboard')),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 40),

          Center(
            child: InkWell(
              onTap: () {
                // TODO: Go to next screen
              },
              highlightColor: theme.primaryColor.withOpacity(0.2),
              child: Container(
                color: theme.primaryColor,
                height: 40,
                alignment: Alignment.center,
                child: const Text(
                  'Create your first post',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
