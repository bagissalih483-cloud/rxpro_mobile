import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';

class NotificationPreferences {
  const NotificationPreferences({
    required this.pushEnabled,
    required this.appointmentReminders,
    required this.messages,
    required this.campaigns,
    required this.system,
  });

  const NotificationPreferences.defaults()
    : pushEnabled = true,
      appointmentReminders = true,
      messages = true,
      campaigns = true,
      system = true;

  final bool pushEnabled;
  final bool appointmentReminders;
  final bool messages;
  final bool campaigns;
  final bool system;

  factory NotificationPreferences.fromMap(Map<String, dynamic>? data) {
    final source = data ?? const <String, dynamic>{};
    return NotificationPreferences(
      pushEnabled: source['pushEnabled'] != false,
      appointmentReminders: source['appointmentReminders'] != false,
      messages: source['messages'] != false,
      campaigns: source['campaigns'] != false,
      system: source['system'] != false,
    );
  }

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? appointmentReminders,
    bool? messages,
    bool? campaigns,
    bool? system,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      appointmentReminders: appointmentReminders ?? this.appointmentReminders,
      messages: messages ?? this.messages,
      campaigns: campaigns ?? this.campaigns,
      system: system ?? this.system,
    );
  }

  Map<String, dynamic> toMap(String uid) {
    return {
      'uid': uid,
      'pushEnabled': pushEnabled,
      'appointmentReminders': appointmentReminders,
      'messages': messages,
      'campaigns': campaigns,
      'system': system,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedAtIso': DateTime.now().toIso8601String(),
    };
  }
}

class NotificationPreferencesRepository {
  NotificationPreferencesRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String get currentUid => _auth.currentUser?.uid.trim() ?? '';

  DocumentReference<Map<String, dynamic>> _doc(String uid) {
    return _firestore
        .collection(FirestoreCollections.notificationPreferences)
        .doc(uid);
  }

  Stream<NotificationPreferences> watchCurrentUserPreferences() {
    final uid = currentUid;
    if (uid.isEmpty) {
      return Stream.value(const NotificationPreferences.defaults());
    }

    return _doc(uid).snapshots().map(
      (snapshot) => NotificationPreferences.fromMap(snapshot.data()),
    );
  }

  Future<void> saveCurrentUserPreferences(
    NotificationPreferences preferences,
  ) async {
    final uid = currentUid;
    if (uid.isEmpty) {
      throw StateError('Bildirim tercihleri için giriş yapılmalıdır.');
    }

    await _doc(uid).set(preferences.toMap(uid), SetOptions(merge: true));
  }
}
