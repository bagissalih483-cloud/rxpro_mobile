import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/firestore/firestore_collections.dart';
import '../../../core/firestore/firestore_fields.dart';
import '../../../core/realtime/rx_notification_service.dart';
import '../../../core/session/app_role.dart';
import '../../../core/session/session_role_policy.dart';

class NotificationCenterRepository {
  NotificationCenterRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String? get currentUid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection(FirestoreCollections.notifications);

  Future<NotificationCenterScope> resolveScope({
    String? businessId,
    String? businessName,
  }) async {
    final user = _auth.currentUser;
    final explicitBusinessId = (businessId ?? '').trim();

    if (explicitBusinessId.isNotEmpty) {
      return NotificationCenterScope.business(
        uid: user?.uid,
        businessId: explicitBusinessId,
        businessName: (businessName ?? 'İşletme').trim(),
      );
    }

    if (user == null) {
      return const NotificationCenterScope.guest();
    }

    try {
      final doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .get();

      final data = Map<String, dynamic>.from(doc.data() ?? {});
      final canonicalRole = SessionRolePolicy.resolveCanonicalRole(data);
      final businessId = _businessIdFromUserData(data);

      final shouldUseBusinessScope =
          (canonicalRole == AppRole.corporateOwner ||
              canonicalRole == AppRole.corporateStaff) &&
          businessId.isNotEmpty;

      if (shouldUseBusinessScope) {
        return NotificationCenterScope.business(
          uid: user.uid,
          businessId: businessId,
          businessName: _businessNameFromUserData(data),
        );
      }
    } catch (_) {
      // Keep notification center available as a personal feed if user lookup fails.
    }

    return NotificationCenterScope.user(uid: user.uid);
  }

  Stream<List<NotificationCenterItem>> watchNotifications(
    NotificationCenterScope scope,
  ) {
    Query<Map<String, dynamic>> query;

    if (scope.businessId.trim().isNotEmpty) {
      query = _notifications
          .where(FirestoreFields.targetScope, isEqualTo: 'business')
          .where(FirestoreFields.businessId, isEqualTo: scope.businessId.trim())
          .limit(100);
    } else if ((scope.uid ?? '').trim().isNotEmpty) {
      query = _notifications
          .where(
            FirestoreFields.targetScope,
            whereIn: NotificationCenterFieldNames.userTargetScopes,
          )
          .where(FirestoreFields.recipientUid, isEqualTo: scope.uid!.trim())
          .limit(100);
    } else {
      return const Stream<List<NotificationCenterItem>>.empty();
    }

    return query.snapshots().map((snapshot) {
      final items = snapshot.docs
          .where((doc) => _visibleForScope(doc.data(), scope))
          .map(NotificationCenterItem.fromDoc)
          .toList();

      items.sort((a, b) => b.createdMillis.compareTo(a.createdMillis));
      return items;
    });
  }

  Future<void> markRead(String id) {
    return RxNotificationService.markRead(id);
  }

  Future<int> markAllRead(List<NotificationCenterItem> items) async {
    final unread = items.where((item) => !item.isRead).toList();

    for (final item in unread) {
      await markRead(item.id);
    }

    return unread.length;
  }

  bool _visibleForScope(
    Map<String, dynamic> data,
    NotificationCenterScope scope,
  ) {
    final targetScope = (data[FirestoreFields.targetScope] ?? '')
        .toString()
        .toLowerCase()
        .trim();

    final recipientUid =
        (data[FirestoreFields.recipientUid] ??
                data[FirestoreFields.targetUid] ??
                data[FirestoreFields.userId] ??
                data[FirestoreFields.customerUid] ??
                data[NotificationCenterFieldNames.receiverUid] ??
                data[NotificationCenterFieldNames.clientUid] ??
                '')
            .toString()
            .trim();

    final dataBusinessId = (data[FirestoreFields.businessId] ?? '')
        .toString()
        .trim();
    final businessId = scope.businessId.trim();

    if (businessId.isNotEmpty) {
      return targetScope == 'business' && dataBusinessId == businessId;
    }

    final uid = (scope.uid ?? '').trim();
    if (uid.isEmpty) return false;

    return (targetScope == 'user' || targetScope == 'customer') &&
        recipientUid == uid;
  }

  static String _businessIdFromUserData(Map<String, dynamic> data) {
    return (data[FirestoreFields.activeBusinessId] ??
            data[FirestoreFields.ownedBusinessId] ??
            data[FirestoreFields.businessId] ??
            data[FirestoreFields.selectedBusinessId] ??
            data[FirestoreFields.staffBusinessId] ??
            data[FirestoreFields.linkedBusinessId] ??
            '')
        .toString()
        .trim();
  }

  static String _businessNameFromUserData(Map<String, dynamic> data) {
    final name =
        (data[FirestoreFields.businessName] ??
                data[FirestoreFields.displayName] ??
                data[FirestoreFields.companyName] ??
                'İşletme')
            .toString()
            .trim();

    return name.isEmpty ? 'İşletme' : name;
  }
}

class NotificationCenterScope {
  const NotificationCenterScope._({
    required this.uid,
    required this.businessId,
    required this.businessName,
  });

  const NotificationCenterScope.guest()
    : this._(uid: null, businessId: '', businessName: '');

  const NotificationCenterScope.user({required String uid})
    : this._(uid: uid, businessId: '', businessName: '');

  const NotificationCenterScope.business({
    required String? uid,
    required String businessId,
    required String businessName,
  }) : this._(uid: uid, businessId: businessId, businessName: businessName);

  final String? uid;
  final String businessId;
  final String businessName;

  bool get isLoggedIn => (uid ?? '').trim().isNotEmpty;
}

class NotificationCenterItem {
  const NotificationCenterItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.route,
    required this.isRead,
    required this.createdMillis,
    required this.createdText,
  });

  factory NotificationCenterItem.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final type = (data[NotificationCenterFieldNames.type] ?? 'general')
        .toString();
    final route = (data[NotificationCenterFieldNames.route] ?? '').toString();

    return NotificationCenterItem(
      id: doc.id,
      title: (data[NotificationCenterFieldNames.title] ?? 'Bildirim')
          .toString(),
      body: (data[NotificationCenterFieldNames.body] ?? '').toString(),
      type: type,
      route: route,
      isRead: data[NotificationCenterFieldNames.isRead] == true,
      createdMillis: _createdMillis(data),
      createdText: _formatCreated(data),
    );
  }

  final String id;
  final String title;
  final String body;
  final String type;
  final String route;
  final bool isRead;
  final int createdMillis;
  final String createdText;

  static int _createdMillis(Map<String, dynamic> data) {
    final ts = data[NotificationCenterFieldNames.createdAt];
    if (ts is Timestamp) return ts.millisecondsSinceEpoch;

    final iso = (data[NotificationCenterFieldNames.createdAtIso] ?? '')
        .toString();
    final parsed = DateTime.tryParse(iso);
    if (parsed != null) return parsed.millisecondsSinceEpoch;

    return 0;
  }

  static String _formatCreated(Map<String, dynamic> data) {
    final ts = data[NotificationCenterFieldNames.createdAt];
    DateTime? date;

    if (ts is Timestamp) {
      date = ts.toDate();
    } else {
      date = DateTime.tryParse(
        (data[NotificationCenterFieldNames.createdAtIso] ?? '').toString(),
      );
    }

    if (date == null) return 'Yeni';

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';

    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');

    return '$d.$m.${date.year} $h:$min';
  }
}

class NotificationCenterFieldNames {
  const NotificationCenterFieldNames._();

  static const receiverUid = 'receiverUid';
  static const clientUid = 'clientUid';
  static const title = 'title';
  static const body = 'body';
  static const type = 'type';
  static const route = 'route';
  static const isRead = 'isRead';
  static const createdAt = 'createdAt';
  static const createdAtIso = 'createdAtIso';
  static const userTargetScopes = <String>['user', 'customer'];
}
