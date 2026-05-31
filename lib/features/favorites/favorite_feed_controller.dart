import 'package:flutter/foundation.dart';

class FavoriteFeedController<TFeed, TSaved> extends ChangeNotifier {
  FavoriteFeedController({
    required Future<TFeed> Function(String uid) loadFeed,
    required Future<TSaved> Function(String uid) loadSaved,
    required Future<TFeed> Function() emptyFeed,
    required Future<TSaved> Function() emptySaved,
  }) : _loadFeed = loadFeed,
       _loadSaved = loadSaved,
       _emptyFeed = emptyFeed,
       _emptySaved = emptySaved;

  final Future<TFeed> Function(String uid) _loadFeed;
  final Future<TSaved> Function(String uid) _loadSaved;
  final Future<TFeed> Function() _emptyFeed;
  final Future<TSaved> Function() _emptySaved;

  int _selectedTab = 0;
  String? _loadedUid;
  Future<TFeed>? _feedFuture;
  Future<TSaved>? _savedFuture;

  int get selectedTab => _selectedTab;
  Future<TFeed>? get feedFuture => _feedFuture;
  Future<TSaved>? get savedFuture => _savedFuture;

  void selectTab(int value) {
    if (value == _selectedTab) return;
    _selectedTab = value;
    notifyListeners();
  }

  void ensureLoaded(String? uid) {
    if (uid == null || uid.isEmpty) {
      _loadedUid = null;
      _feedFuture = _emptyFeed();
      _savedFuture = _emptySaved();
      return;
    }

    if (_loadedUid != uid || _feedFuture == null || _savedFuture == null) {
      _loadedUid = uid;
      _feedFuture = _loadFeed(uid);
      _savedFuture = _loadSaved(uid);
    }
  }

  Future<void> refresh(String? uid) async {
    _loadedUid = null;
    ensureLoaded(uid);
    notifyListeners();

    await Future.wait<dynamic>([
      _feedFuture ?? _emptyFeed(),
      _savedFuture ?? _emptySaved(),
    ]);
  }
}
