import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/app_route_catalog.dart';
import '../../firebase_options.dart';
import 'rx_push_notification_session_repository.dart';

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
  final RxPushNotificationSessionRepository _sessionRepository =
      RxPushNotificationSessionRepository();

  StreamSubscription<String?>? _authSub;
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

    _authSub ??= _sessionRepository.watchUserIds().listen(
      (uid) async => _handleAuthChanged(uid),
    );

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

  Future<void> _handleAuthChanged(String? uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUid = prefs.getString(_lastUidKey);

      if (lastUid != null && lastUid.isNotEmpty && lastUid != uid) {
        await deactivateTokenForUid(lastUid);
        await prefs.remove(_lastUidKey);
      }

      if (uid == null || uid.trim().isEmpty) {
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
      final uid = _sessionRepository.currentUid;
      final lastUid = prefs.getString(_lastUidKey);

      if (lastUid != null && lastUid.isNotEmpty && lastUid != uid) {
        await deactivateTokenForUid(lastUid);
        await prefs.remove(_lastUidKey);
      }

      if (uid.isNotEmpty) {
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

  Future<void> syncTokenForCurrentUser() async {
    final uid = _sessionRepository.currentUid;
    if (uid.isEmpty) return;

    try {
      final token = await _messaging.getToken();
      if (token == null || token.trim().isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final lastUid = prefs.getString(_lastUidKey);

      if (lastUid != null && lastUid.isNotEmpty && lastUid != uid) {
        await deactivateTokenForUid(lastUid);
      }

      final cleanToken = token.trim();
      final tokenDocId = _tokenDocId(cleanToken);
      await _sessionRepository.upsertActiveToken(
        uid: uid,
        token: cleanToken,
        tokenDocId: tokenDocId,
        platform: Platform.operatingSystem,
        tokenTail: _tokenTail(cleanToken),
      );

      await prefs.setString(_lastUidKey, uid);
    } catch (e) {
      debugPrint('RX_41I_TOKEN_SYNC_ERROR $e');
    }
  }

  Future<void> deactivateTokenForCurrentUser() async {
    final uid = _sessionRepository.currentUid;
    if (uid.isEmpty) return;
    await deactivateTokenForUid(uid);
  }

  Future<void> deactivateTokenForUid(String uid) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return;

    try {
      final token = await _messaging.getToken();
      final cleanToken = (token ?? '').trim();
      await _sessionRepository.deactivateTokenForUid(
        uid: cleanUid,
        token: cleanToken,
        tokenDocId: _tokenDocId(cleanToken),
        tokenTail: _tokenTail(cleanToken),
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
    final uid = _sessionRepository.currentUid;
    if (uid.isEmpty) return false;

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

    if (recipientUid.isNotEmpty && recipientUid != uid) {
      return false;
    }

    if (targetScope == 'user' || targetScope == 'customer') {
      return recipientUid == uid;
    }

    if (targetScope == 'business') {
      if (recipientUid.isNotEmpty) return recipientUid == uid;
      return true;
    }

    return recipientUid.isEmpty || recipientUid == uid;
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

    return _sessionRepository.businessNotificationBelongsToCurrentUser(
      businessId,
    );
  }

  Future<void> _showForegroundNativeNotification(RemoteMessage message) async {
    if (!await _messageBelongsToCurrentSession(message)) return;

    final title = message.notification?.title ?? message.data['title'] ?? 'fi';

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
      navigator.pushNamed(AppRoutes.customerAppointments);
      return;
    }

    navigator.pushNamed(
      AppRoutes.notificationCenter,
      arguments: NotificationCenterRouteArgs(
        businessId: businessId.isEmpty ? null : businessId,
        businessName: businessName.isEmpty ? null : businessName,
      ),
    );
  }
}
