import 'package:flutter/foundation.dart';

import 'models/account_entry_context.dart';

class AccountEntryController extends ChangeNotifier {
  final Set<int> _openSections = <int>{};
  Future<AccountEntryContext>? _contextFuture;
  String? _loadedKey;

  Set<int> get openSections => Set.unmodifiable(_openSections);
  Future<AccountEntryContext>? get contextFuture => _contextFuture;
  String? get loadedKey => _loadedKey;

  bool needsContext(String? key) {
    return _contextFuture == null || _loadedKey != key;
  }

  void setContextFuture({
    required String? loadedKey,
    required Future<AccountEntryContext> future,
    bool notify = true,
  }) {
    _loadedKey = loadedKey;
    _contextFuture = future;
    if (notify) notifyListeners();
  }

  void clearContext({bool clearOpenSections = false, bool notify = true}) {
    _loadedKey = null;
    _contextFuture = null;
    if (clearOpenSections) {
      _openSections.clear();
    }
    if (notify) notifyListeners();
  }

  void toggleSection(int index) {
    if (_openSections.contains(index)) {
      _openSections.remove(index);
    } else {
      _openSections.add(index);
    }
    notifyListeners();
  }
}
