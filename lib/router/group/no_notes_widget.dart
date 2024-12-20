import 'package:flutter/material.dart';

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
          // Added Center widget here
          child: ListView(
            shrinkWrap: true, // Added shrinkWrap to true
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.all(80.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        groupName,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 20.0,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Write a note to welcome your community!',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 18.0,
                          color: Colors.white,
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
      );
}