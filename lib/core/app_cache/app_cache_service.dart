import 'package:shared_preferences/shared_preferences.dart';

class AppCacheService {
  static Future<SharedPreferences>? _prefsFuture;

  static const String _displayNameKey = 'rxpro_last_display_name';
  static const String _roleKey = 'rxpro_last_role';
  static const String _uidKey = 'rxpro_last_uid';
  static const String _emailKey = 'rxpro_last_email';
  static const String _unreadMessageCountKey = 'rxpro_unread_message_count';
  static const String _unreadNotificationCountKey =
      'rxpro_unread_notification_count';
  static const String _followedBusinessIdsKey = 'rxpro_followed_business_ids';

  static Future<SharedPreferences> _prefs() {
    return _prefsFuture ??= SharedPreferences.getInstance();
  }

  Future<void> saveUserSnapshot({
    required String uid,
    required String displayName,
    required String role,
    String email = '',
  }) async {
    final prefs = await _prefs();

    await prefs.setString(_uidKey, uid);
    await prefs.setString(_displayNameKey, displayName);
    await prefs.setString(_roleKey, role);
    await prefs.setString(_emailKey, email);
  }

  Future<CachedUserSnapshot?> getUserSnapshot() async {
    final prefs = await _prefs();

    final uid = prefs.getString(_uidKey) ?? '';
    final displayName = prefs.getString(_displayNameKey) ?? '';
    final role = prefs.getString(_roleKey) ?? '';
    final email = prefs.getString(_emailKey) ?? '';

    if (uid.trim().isEmpty) {
      return null;
    }

    return CachedUserSnapshot(
      uid: uid,
      displayName: displayName,
      role: role,
      email: email,
    );
  }

  Future<void> clearUserSnapshot() async {
    final prefs = await _prefs();

    await prefs.remove(_uidKey);
    await prefs.remove(_displayNameKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_unreadMessageCountKey);
    await prefs.remove(_unreadNotificationCountKey);
    await prefs.remove(_followedBusinessIdsKey);
  }

  Future<void> saveUnreadCounts({
    required int unreadMessages,
    required int unreadNotifications,
  }) async {
    final prefs = await _prefs();

    await prefs.setInt(_unreadMessageCountKey, unreadMessages);
    await prefs.setInt(_unreadNotificationCountKey, unreadNotifications);
  }

  Future<CachedUnreadCounts> getUnreadCounts() async {
    final prefs = await _prefs();

    return CachedUnreadCounts(
      unreadMessages: prefs.getInt(_unreadMessageCountKey) ?? 0,
      unreadNotifications: prefs.getInt(_unreadNotificationCountKey) ?? 0,
    );
  }

  Future<void> saveFollowedBusinessIds(List<String> ids) async {
    final prefs = await _prefs();

    final cleanIds = ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    await prefs.setStringList(_followedBusinessIdsKey, cleanIds);
  }

  Future<List<String>> getFollowedBusinessIds() async {
    final prefs = await _prefs();

    return prefs.getStringList(_followedBusinessIdsKey) ?? const [];
  }

  Future<bool> isBusinessFollowed(String businessId) async {
    final ids = await getFollowedBusinessIds();

    return ids.contains(businessId);
  }

  Future<void> setBusinessFollowed({
    required String businessId,
    required bool followed,
  }) async {
    final ids = await getFollowedBusinessIds();
    final set = ids.toSet();

    if (followed) {
      set.add(businessId);
    } else {
      set.remove(businessId);
    }

    await saveFollowedBusinessIds(set.toList());
  }
}

class CachedUserSnapshot {
  final String uid;
  final String displayName;
  final String role;
  final String email;

  const CachedUserSnapshot({
    required this.uid,
    required this.displayName,
    required this.role,
    required this.email,
  });

  bool get hasDisplayName => displayName.trim().isNotEmpty;

  String get safeDisplayName {
    if (displayName.trim().isNotEmpty) {
      return displayName.trim();
    }

    if (email.trim().isNotEmpty) {
      return email.trim();
    }

    return 'Aktif Kullanıcı';
  }
}

class CachedUnreadCounts {
  final int unreadMessages;
  final int unreadNotifications;

  const CachedUnreadCounts({
    required this.unreadMessages,
    required this.unreadNotifications,
  });
}
