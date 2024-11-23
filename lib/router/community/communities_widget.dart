
import 'package:flutter/material.dart';
import 'package:nostrmo/provider/community_list_provider.dart';
import 'package:provider/provider.dart';
import '../../consts/colors.dart';

class CommunitiesWidget extends StatelessWidget {
  const CommunitiesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final communityProvider = Provider.of<CommunityListProvider>(context);
    final communities = communityProvider.communities;

    if (communities.isEmpty) {
      return const Center(
        child: Text('No communities available.'),
      );
    }

    return Container(
      color: ColorList.plurPurple,
      child: GridView.builder(
        padding: const EdgeInsets.only(top: 52.0, left: 20.0, right: 20.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 0.0,
          mainAxisSpacing: 32.0,
          childAspectRatio: 1,
        ),
        itemCount: communities.length,
        itemBuilder: (context, index) {
          final community = communities[index];
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColorList.borderColor,
                    width: 4,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    community.imageUrl,
                    fit: BoxFit.cover,
                    width: 100,
                    height: 100,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 120,
                child: Text(
                  community.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}