import 'package:flutter/material.dart';

import '../data/community.dart';

class CommunityListProvider extends ChangeNotifier {
  bool _isLoading = true;
  List<Community> _communities = [];

  bool get isLoading => _isLoading;
  List<Community> get communities => List.unmodifiable(_communities);

  CommunityListProvider() {
    _loadCommunities();
  }

  Future<void> _loadCommunities() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate delay
    _communities = [
      Community(
        name: 'Valencia Ravers',
        imageUrl: 'https://cdn.vectorstock.com/i/thumbs/33/25/colorful-abstract-psychedelic-art-background-vector-10753325.jpg',
        shortDescription: 'A community for Flutter developers.',
      ),
      Community(
        name: 'Music Lovers',
        imageUrl: 'http://www.clipartbest.com/cliparts/nTX/xLX/nTXxLXXLc.gif',
        shortDescription: 'A community for Flutter developers.',
      ),
      Community(
        name: 'VLC Mutual Aid',
        imageUrl: 'https://media.glassdoor.com/sqll/1323451/community-aid-squarelogo-1572950623553.png',
        shortDescription: 'A community for Flutter developers.',
      ),
      Community(
        name: 'Sou Sou Family',
        imageUrl: 'https://freesvg.org/storage/img/thumb/pitr_First_aid_icon.png',
        shortDescription: 'A community for Flutter developers.',
      ),
      Community(
        name: 'Flutter Enthusiasts',
        imageUrl: 'https://emojis.slackmojis.com/emojis/images/1645198685/53297/dash-flutter.png?1645198685',
        shortDescription: 'A community for Flutter developers.',
      ),
      Community(
        name: 'Tech Innovators',
        imageUrl: 'https://eddulharu.com/wp-content/uploads/2021/03/ed-blog.png',
        shortDescription: 'A group exploring the latest tech trends.',
      ),
      Community(
        name: 'Nature Lovers',
        imageUrl: 'https://www.thepcmanwebsite.com/free_clipart/clipart/nature/spruce.gif',
        shortDescription: 'Sharing adventures in nature.',
      ),
    ];
    _isLoading = false;
    notifyListeners(); // Notify listeners of state change
  }
}