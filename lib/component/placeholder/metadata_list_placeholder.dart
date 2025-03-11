import 'package:flutter/material.dart';
import 'package:nostrmo/component/placeholder/metadata_placeholder.dart';

class MetadataListPlaceholder extends StatelessWidget {
  Function? onRefresh;

  MetadataListPlaceholder({super.key, this.onRefresh});

  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: RefreshIndicator(
        onRefresh: () async {
          if (onRefresh != null) {
            onRefresh!();
          }
        },
        child: ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            return const MetadataPlaceholder();
          },
          itemCount: 10,
        ),
      ),
    );
  }
}
