import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/appointments/presentation/pages/customer_appointments_page.dart';
import '../../features/notifications/notification_center_page.dart';
import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> rxFirebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class RxPushNotificationService {
  RxPushNotificationService._();

  static final RxPushNotificationService instance =
      RxPushNotificationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const MethodChannel _nativeNotifications = MethodChannel(
    'rxpro/native_notifications',
  );

  static const String _lastUidKey = 'rxpro_last_fcm_uid';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<String>? _tokenRefreshSub;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _messaging
          .requestPermission(alert: true, badge: true, sound: true)
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('RX_PUSH_PERMISSION_SKIPPED $e');
    }

    try {
      await _syncForInitialUser().timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('RX_PUSH_INITIAL_SYNC_SKIPPED $e');
    }

    _authSub ??= FirebaseAuth.instance.authStateChanges().listen((user) async {
      await _handleAuthChanged(user);
    });

    _tokenRefreshSub ??= _messaging.onTokenRefresh.listen((_) async {
      await syncTokenForCurrentUser();
    });

    FirebaseMessaging.onMessage.listen(_showForegroundNativeNotification);

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      unawaited(_openFromData(message.data));
    });

    RemoteMessage? initialMessage;
    try {
      initialMessage = await _messaging.getInitialMessage().timeout(
        const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('RX_PUSH_INITIAL_MESSAGE_SKIPPED $e');
    }

    final launchMessage = initialMessage;
    if (launchMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_openFromData(launchMessage.data));
      });
    }
  }

  Future<void> _handleAuthChanged(User? user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUid = prefs.getString(_lastUidKey);

      if (lastUid != null && lastUid.isNotEmpty && lastUid != user?.uid) {
        await deactivateTokenForUid(lastUid);
        await prefs.remove(_lastUidKey);
      }

      if (user == null) {
        return;
      }

      await syncTokenForCurrentUser();
    } catch (e) {
      debugPrint('RX_41I_AUTH_CHANGE_ERROR $e');
    }
  }

  Future<void> _syncForInitialUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      final lastUid = prefs.getString(_lastUidKey);

      if (lastUid != null && lastUid.isNotEmpty && lastUid != user?.uid) {
        await deactivateTokenForUid(lastUid);
        await prefs.remove(_lastUidKey);
      }

      if (user != null) {
        await syncTokenForCurrentUser();
      }
    } catch (e) {
      debugPrint('RX_41I_INITIAL_SYNC_ERROR $e');
    }
  }

  String _tokenDocId(String token) {
    return token.trim().replaceAll(RegExp(r'[/\\.#\[\]*]'), '_');
  }

  String _tokenTail(String token) {
    final clean = token.trim();
    if (clean.length <= 10) return clean;
    return clean.substring(clean.length - 10);
  }

  Future<void> _deactivateOtherActiveTokensForUid({
    required String uid,
    required String currentToken,
    required String currentTokenDocId,
  }) async {
    final cleanUid = uid.trim();
    final cleanToken = currentToken.trim();

    if (cleanUid.isEmpty || cleanToken.isEmpty) return;

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(cleanUid);

      final activeSnap = await userRef
          .collection('fcmTokens')
          .where('active', isEqualTo: true)
          .limit(100)
          .get();

      if (activeSnap.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      var closedCount = 0;

      for (final doc in activeSnap.docs) {
        final data = doc.data();
        final docToken = (data['token'] ?? '').toString().trim();

        final isCurrent =
            doc.id == currentTokenDocId ||
            doc.id == cleanToken ||
            docToken == cleanToken;

        if (isCurrent) continue;

        batch.set(doc.reference, {
          'active': false,
          'deactivatedReason': 'replaced_by_latest_login_token',
          'deactivatedAt': FieldValue.serverTimestamp(),
          'deactivatedAtIso': DateTime.now().toIso8601String(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        closedCount++;
      }

      if (closedCount > 0) {
        await batch.commit();
      }

      debugPrint(
        'RX_41I_B_OTHER_TOKENS_DEACTIVATED uid=$cleanUid count=$closedCount',
      );
    } catch (e) {
      debugPrint(
        'RX_41I_B_OTHER_TOKENS_DEACTIVATE_ERROR uid=$cleanUid error=$e',
      );
    }
  }

  Future<void> syncTokenForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token == null || token.trim().isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final lastUid = prefs.getString(_lastUidKey);

      if (lastUid != null && lastUid.isNotEmpty && lastUid != user.uid) {
        await deactivateTokenForUid(lastUid);
      }

      final cleanToken = token.trim();
      final tokenDocId = _tokenDocId(cleanToken);
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      await userRef.set({
        'fcmToken': cleanToken,
        'fcmTokenOwnerUid': user.uid,
        'fcmPlatform': Platform.operatingSystem,
        'fcmTokenActive': true,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'fcmTokenUpdatedAtIso': DateTime.now().toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await userRef.collection('fcmTokens').doc(tokenDocId).set({
        'token': cleanToken,
        'ownerUid': user.uid,
        'platform': Platform.operatingSystem,
        'active': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedAtIso': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      await _deactivateOtherActiveTokensForUid(
        uid: user.uid,
        currentToken: cleanToken,
        currentTokenDocId: tokenDocId,
      );

      debugPrint('RX_41I_B_AFTER_TOKEN_WRITE_UNIQUE uid=${user.uid}');

      await prefs.setString(_lastUidKey, user.uid);

      debugPrint(
        'RX_41I_TOKEN_SYNC_SUCCESS uid=${user.uid} tokenTail=${_tokenTail(cleanToken)}',
      );
    } catch (e) {
      debugPrint('RX_41I_TOKEN_SYNC_ERROR $e');
    }
  }

  Future<void> deactivateTokenForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.trim().isEmpty) return;
    await deactivateTokenForUid(uid);
  }

  Future<void> deactivateTokenForUid(String uid) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return;

    try {
      final token = await _messaging.getToken();
      final cleanToken = (token ?? '').trim();

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(cleanUid);

      await userRef.set({
        'fcmTokenActive': false,
        'fcmTokenDeactivatedAt': FieldValue.serverTimestamp(),
        'fcmTokenDeactivatedAtIso': DateTime.now().toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (cleanToken.isEmpty) {
        debugPrint('RX_41I_TOKEN_DEACTIVATE_NO_TOKEN uid=$cleanUid');
        return;
      }

      final rawTokenDocRef = userRef.collection('fcmTokens').doc(cleanToken);
      final safeTokenDocRef = userRef
          .collection('fcmTokens')
          .doc(_tokenDocId(cleanToken));

      final inactiveData = {
        'token': cleanToken,
        'ownerUid': cleanUid,
        'active': false,
        'deactivatedAt': FieldValue.serverTimestamp(),
        'deactivatedAtIso': DateTime.now().toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await rawTokenDocRef.set(inactiveData, SetOptions(merge: true));
      await safeTokenDocRef.set(inactiveData, SetOptions(merge: true));

      final sameTokenSnap = await userRef
          .collection('fcmTokens')
          .where('token', isEqualTo: cleanToken)
          .limit(20)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      var count = 0;

      for (final doc in sameTokenSnap.docs) {
        batch.set(doc.reference, inactiveData, SetOptions(merge: true));
        count++;
      }

      if (count > 0) {
        await batch.commit();
      }

      debugPrint(
        'RX_41I_TOKEN_DEACTIVATED uid=$cleanUid tokenTail=${_tokenTail(cleanToken)} count=$count',
      );
    } catch (e) {
      debugPrint('RX_41I_TOKEN_DEACTIVATE_ERROR uid=$cleanUid error=$e');
    }
  }

  String _stringFromData(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = (data[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  bool _dataBelongsToCurrentSession(Map<String, dynamic> data) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final targetScope = _stringFromData(data, [
      'targetScope',
    ]).toLowerCase().trim();

    final recipientUid = _stringFromData(data, [
      'recipientUid',
      'targetUid',
      'userId',
      'customerUid',
      'receiverUid',
      'clientUid',
    ]);

    if (recipientUid.isNotEmpty && recipientUid != user.uid) {
      return false;
    }

    if (targetScope == 'user' || targetScope == 'customer') {
      return recipientUid == user.uid;
    }

    if (targetScope == 'business') {
      if (recipientUid.isNotEmpty) return recipientUid == user.uid;
      return true;
    }

    return recipientUid.isEmpty || recipientUid == user.uid;
  }

  Future<bool> _messageBelongsToCurrentSession(RemoteMessage message) async {
    return _dataBelongsToCurrentSessionAsync(message.data);
  }

  Future<bool> _dataBelongsToCurrentSessionAsync(
    Map<String, dynamic> data,
  ) async {
    if (!_dataBelongsToCurrentSession(data)) return false;

    final targetScope = _stringFromData(data, [
      'targetScope',
    ]).toLowerCase().trim();

    if (targetScope != 'business') return true;

    final recipientUid = _stringFromData(data, [
      'recipientUid',
      'targetUid',
      'userId',
      'customerUid',
      'receiverUid',
      'clientUid',
    ]);

    if (recipientUid.isNotEmpty) return true;

    final businessId = _stringFromData(data, ['businessId']);
    if (businessId.isEmpty) return false;

    return _businessNotificationBelongsToCurrentUser(businessId);
  }

  Future<bool> _businessNotificationBelongsToCurrentUser(
    String businessId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid.trim() ?? '';
    final rawBusinessId = businessId.trim();
    if (uid.isEmpty || rawBusinessId.isEmpty) return false;

    final businessCandidates = <String>{
      rawBusinessId,
      if (rawBusinessId.startsWith('business_'))
        rawBusinessId.replaceFirst(RegExp(r'^business_'), '').trim(),
    }.where((value) => value.isNotEmpty).toSet();

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 3));
      final userData = userDoc.data() ?? <String, dynamic>{};
      final userBusinessIds = <String>[
        'businessId',
        'ownedBusinessId',
        'activeBusinessId',
        'selectedBusinessId',
        'staffBusinessId',
        'linkedBusinessId',
      ]
          .map((field) => (userData[field] ?? '').toString().trim())
          .where((value) => value.isNotEmpty)
          .toSet();

      if (userBusinessIds.any(businessCandidates.contains)) return true;
    } catch (e) {
      debugPrint('RX_PUSH_BUSINESS_USER_SCOPE_CHECK_SKIPPED $e');
    }

    for (final candidate in businessCandidates) {
      try {
        final businessDoc = await FirebaseFirestore.instance
            .collection('businesses')
            .doc(candidate)
            .get()
            .timeout(const Duration(seconds: 3));
        final data = businessDoc.data() ?? <String, dynamic>{};

        final directOwners = <String>[
          'ownerUid',
          'ownerId',
          'businessOwnerUid',
          'userId',
          'uid',
          'createdBy',
          'createdByUid',
          'adminUid',
          'managerUid',
        ].map((field) => (data[field] ?? '').toString().trim());

        if (directOwners.any((ownerUid) => ownerUid == uid)) return true;
        if (_ownerContainerContainsUid(data['ownerUids'], uid)) return true;
        if (_ownerContainerContainsUid(data['owners'], uid)) return true;
      } catch (e) {
        debugPrint('RX_PUSH_BUSINESS_DOC_SCOPE_CHECK_SKIPPED $e');
      }
    }

    return false;
  }

  bool _ownerContainerContainsUid(Object? value, String uid) {
    if (value == null || uid.trim().isEmpty) return false;
    if (value is String) return value.trim() == uid;
    if (value is Iterable) {
      return value.any((item) => _ownerContainerContainsUid(item, uid));
    }
    if (value is Map) {
      return value.entries.any((entry) {
        if (entry.value == true) {
          return entry.key.toString().trim() == uid;
        }
        return _ownerContainerContainsUid(entry.value, uid);
      });
    }
    return value.toString().trim() == uid;
  }

  Future<void> _showForegroundNativeNotification(RemoteMessage message) async {
    if (!await _messageBelongsToCurrentSession(message)) return;

    final title =
        message.notification?.title ?? message.data['title'] ?? 'fi';

    final body =
        message.notification?.body ??
        message.data['body'] ??
        'Yeni bildiriminiz var.';

    try {
      await _nativeNotifications.invokeMethod('showNotification', {
        'notificationId': (message.data['notificationId'] ?? '').toString(),
        'title': title.toString(),
        'body': body.toString(),
        'type': (message.data['type'] ?? '').toString(),
        'route': (message.data['route'] ?? '').toString(),
        'businessId': (message.data['businessId'] ?? '').toString(),
        'businessName': (message.data['businessName'] ?? '').toString(),
        'appointmentId': (message.data['appointmentId'] ?? '').toString(),
        'targetScope': (message.data['targetScope'] ?? '').toString(),
        'recipientUid': _stringFromData(message.data, [
          'recipientUid',
          'targetUid',
          'userId',
          'customerUid',
          'receiverUid',
          'clientUid',
        ]),
      });
    } catch (e) {
      debugPrint('RX_41I_NATIVE_NOTIFICATION_ERROR $e');
    }
  }

  Future<void> _openFromData(Map<String, dynamic> data) async {
    if (!await _dataBelongsToCurrentSessionAsync(data)) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final route = (data['route'] ?? '').toString().toLowerCase();
    final type = (data['type'] ?? '').toString().toLowerCase();
    final businessId = (data['businessId'] ?? '').toString().trim();
    final businessName = (data['businessName'] ?? '').toString().trim();

    final isAppointment =
        route == 'customerappointments' ||
        route == 'customer_appointments' ||
        route == 'appointment' ||
        type.contains('appointment');

    if (isAppointment && !route.contains('business')) {
      navigator.push(
        MaterialPageRoute(builder: (_) => const CustomerAppointmentsPage()),
      );
      return;
    }

    navigator.push(
      MaterialPageRoute(
        builder: (_) => NotificationCenterPage(
          businessId: businessId.isEmpty ? null : businessId,
          businessName: businessName.isEmpty ? null : businessName,
        ),
      ),
    );
  }
}
