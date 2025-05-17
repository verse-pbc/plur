import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class NoNotesWidget extends StatelessWidget {
  final String groupName;
  final Future<void> Function()? onRefresh;

  const NoNotesWidget({
    Key? key,
    required this.groupName,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: onRefresh ?? () async {},
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height,
              maxWidth: MediaQuery.of(context).size.width,
            ),
            child: ListView(
              physics: const ClampingScrollPhysics(),
              shrinkWrap: true,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.all(80.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          groupName,
                          style: TextStyle(
                            fontSize:
                                Theme.of(context).textTheme.bodyLarge!.fontSize,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Write a note to welcome your community!',
                          style: TextStyle(
                            fontSize:
                                Theme.of(context).textTheme.bodyMedium!.fontSize,
                            color: Theme.of(context).textTheme.bodyMedium!.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
