import 'package:flutter/material.dart';

import '../consts/index_taps.dart';

// Community view modes - grid or feed
enum CommunityViewMode {
  grid,
  feed
}

class IndexProvider extends ChangeNotifier {
  int _currentTap = IndexTaps.follow;
  
  // Default to grid view for communities
  CommunityViewMode _communityViewMode = CommunityViewMode.grid;
  
  @override
  void dispose() {
    // Clear the static reference when disposed
    if (_instance == this) {
      _instance = null;
    }
    super.dispose();
  }

  // Static reference to the global instance for safe access
  static IndexProvider? _instance;

  // Static methods for global access that don't require context
  static void setGlobalViewModeToGrid() {
    if (_instance != null) {
      _instance!._communityViewMode = CommunityViewMode.grid;
      _instance!.notifyListeners();
    }
  }

  static void setGlobalViewModeToFeed() {
    if (_instance != null) {
      _instance!._communityViewMode = CommunityViewMode.feed;
      _instance!.notifyListeners();
    }
  }

  int get currentTap => _currentTap;
  CommunityViewMode get communityViewMode => _communityViewMode;

  IndexProvider({int? indexTap}) {
    if (indexTap != null) {
      _currentTap = indexTap;
    }
    
    // Store reference to this instance
    _instance = this;
  }
  
  // Change the community view mode
  void setCommunityViewMode(CommunityViewMode mode) {
    _communityViewMode = mode;
    notifyListeners();
  }

  // Track if we're currently animating
  bool _isAnimating = false;
  
  // Track the previously selected tab
  int _previousTap = 0;
  
  // Track the last time a tab switch happened (to throttle rapid switches)
  DateTime? _lastTabSwitchTime;
  
  // Get the previous tab index
  int get previousTap => _previousTap;
  
  // Keep track of pending tab changes to handle rapid switches
  int? _pendingTabChange;
  
  // Use a map to track which tabs have fully loaded their content
  final Map<int, bool> _tabLoaded = {0: false, 1: false, 2: false};
  
  // Method to mark a tab as loaded
  void markTabLoaded(int tabIndex) {
    _tabLoaded[tabIndex] = true;
  }
  
  // Get whether a tab has been fully loaded
  bool isTabLoaded(int tabIndex) {
    return _tabLoaded[tabIndex] ?? false;
  }
  
  void setCurrentTap(int v) {
    // Don't do anything if we're already on this tab
    if (_currentTap == v) return;
    
    // Store the previous tab
    _previousTap = _currentTap;
    
    // Throttle rapid tab switches to prevent UI jank
    final now = DateTime.now();
    if (_lastTabSwitchTime != null) {
      final diff = now.difference(_lastTabSwitchTime!).inMilliseconds;
      if (diff < 300) {
        // Too soon after last switch, remember the most recent request
        _pendingTabChange = v;
        return;
      }
    }
    
    _lastTabSwitchTime = now;
    _setCurrentTabWithAnimation(v);
  }
  
  void _setCurrentTabWithAnimation(int v) {
    // Update the current tab immediately to avoid UI lag
    _currentTap = v;
    
    // Prevent redundant UI updates during animation
    if (!_isAnimating) {
      _isAnimating = true;
      
      // Use a microtask for smoother UI transitions
      Future.microtask(() {
        notifyListeners();
        
        // Add a delay after the tab change to prevent rapid switches
        Future.delayed(const Duration(milliseconds: 200), () {
          _isAnimating = false;
          
          // Process any pending tab change that came in while we were animating
          if (_pendingTabChange != null && _pendingTabChange != _currentTap) {
            final pendingTab = _pendingTabChange;
            _pendingTabChange = null;
            setCurrentTap(pendingTab!);
          }
        });
      });
    }
  }

  TabController? _followTabController;

  void setFollowTabController(TabController? followTabController) {
    _followTabController = followTabController;
  }

  ScrollController? _followPostsScrollController;

  void setFollowPostsScrollController(
      ScrollController? followPostsScrollController) {
    _followPostsScrollController = followPostsScrollController;
  }

  ScrollController? _followScrollController;

  void setFollowScrollController(ScrollController? followScrollController) {
    _followScrollController = followScrollController;
  }

  ScrollController? _mentionedScrollController;

  void setMentionedScrollController(
      ScrollController? mentionedScrollController) {
    _mentionedScrollController = mentionedScrollController;
  }

  void followScrollToTop() {
    if (_followTabController != null) {
      if (_followTabController!.index == 0 &&
          _followPostsScrollController != null) {
        _followPostsScrollController!.jumpTo(0);
      } else if (_followTabController!.index == 1 &&
          _followScrollController != null) {
        _followScrollController!.jumpTo(0);
      } else if (_followTabController!.index == 2 &&
          _mentionedScrollController != null) {
        _mentionedScrollController!.jumpTo(0);
      }
    }
  }

  TabController? _globalTabController;

  void setGlobalTabController(TabController? globalTabController) {
    _globalTabController = globalTabController;
  }

  ScrollController? _eventScrollController;

  void setEventScrollController(ScrollController? eventScrollController) {
    _eventScrollController = eventScrollController;
  }

  ScrollController? _userScrollController;

  void setUserScrollController(ScrollController? userScrollController) {
    _userScrollController = userScrollController;
  }

  void globalScrollToTop() {
    if (_globalTabController != null) {
      if (_globalTabController!.index == 0 && _eventScrollController != null) {
        _eventScrollController!.jumpTo(0);
      } else if (_globalTabController!.index == 1 &&
          _userScrollController != null) {
        _userScrollController!.jumpTo(0);
      }
    }
  }
}
