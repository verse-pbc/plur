import 'package:flutter/material.dart';
import 'package:nostrmo/router/group/no_communities_widget.dart';

void main() {
  runApp(const TestNoCommunitiesApp());
}

class TestNoCommunitiesApp extends StatelessWidget {
  const TestNoCommunitiesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test NoCommunitiesWidget',
      theme: ThemeData.dark(),
      home: const Scaffold(
        body: Center(
          child: NoCommunitiesWidget(forceShow: true),
        ),
      ),
    );
  }
}