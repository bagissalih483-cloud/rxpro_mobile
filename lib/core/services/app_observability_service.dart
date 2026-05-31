import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppObservabilityService {
  AppObservabilityService._();

  static final AppObservabilityService instance = AppObservabilityService._();

  FirebaseAnalyticsObserver? _analyticsObserver;

  bool get _supportsCrashlytics {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return false;
    }
  }

  bool get _supportsAnalytics {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return false;
    }
  }

  List<NavigatorObserver> get navigatorObservers {
    if (!_supportsAnalytics) return const [];
    return [
      _analyticsObserver ??= FirebaseAnalyticsObserver(
        analytics: FirebaseAnalytics.instance,
      ),
    ];
  }

  Future<void> initialize() async {
    unawaited(_configureCrashlytics());

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(recordFlutterError(details));
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      unawaited(
        recordError(
          error,
          stackTrace,
          fatal: true,
          reason: 'Uncaught platform dispatcher error',
        ),
      );
      return true;
    };

    unawaited(logAppOpen());
  }

  Future<void> setUserId(String? userId) async {
    final normalizedUserId = userId?.trim();
    final analyticsUserId = normalizedUserId == null || normalizedUserId.isEmpty
        ? null
        : normalizedUserId;

    if (_supportsCrashlytics) {
      await _guardCrashlytics(
        () => FirebaseCrashlytics.instance.setUserIdentifier(
          normalizedUserId == null || normalizedUserId.isEmpty
              ? ''
              : normalizedUserId,
        ),
      );
    }

    if (_supportsAnalytics) {
      await _guardAnalytics(
        () => FirebaseAnalytics.instance.setUserId(id: analyticsUserId),
      );
    }
  }

  Future<void> logAppOpen() async {
    if (!_supportsAnalytics) return;
    await _guardAnalytics(() => FirebaseAnalytics.instance.logAppOpen());
  }

  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const <String, Object?>{},
  }) async {
    final cleanName = name.trim();
    if (!_supportsAnalytics || cleanName.isEmpty) return;

    await _guardAnalytics(
      () => FirebaseAnalytics.instance.logEvent(
        name: cleanName,
        parameters: _cleanAnalyticsParameters(parameters),
      ),
    );
  }

  Future<void> logRegistrationCompleted({required String accountType}) {
    return logEvent(
      AppAnalyticsEvents.registrationCompleted,
      parameters: <String, Object?>{'account_type': accountType},
    );
  }

  Future<void> logExploreBusinessOpen({
    required String businessId,
    required String category,
    required bool isMember,
  }) {
    return logEvent(
      AppAnalyticsEvents.exploreBusinessOpen,
      parameters: <String, Object?>{
        'business_id': businessId,
        'category': category,
        'is_member': isMember,
      },
    );
  }

  Future<void> logBusinessClaimSubmitted({
    required String placeId,
    required String category,
  }) {
    return logEvent(
      AppAnalyticsEvents.businessClaimSubmitted,
      parameters: <String, Object?>{'place_id': placeId, 'category': category},
    );
  }

  Future<void> logLocationPermissionResult({
    required String status,
    String source = 'discover',
  }) {
    return logEvent(
      AppAnalyticsEvents.locationPermissionResult,
      parameters: <String, Object?>{'status': status, 'source': source},
    );
  }

  Future<void> logAppointmentBookingCompleted({
    required String businessId,
    required String serviceId,
    required String staffId,
    required int durationMinutes,
  }) {
    return logEvent(
      AppAnalyticsEvents.appointmentBookingCompleted,
      parameters: <String, Object?>{
        'business_id': businessId,
        'service_id': serviceId,
        'staff_id': staffId,
        'duration_minutes': durationMinutes,
      },
    );
  }

  Future<void> logCampaignViewed({
    required String campaignId,
    required String businessId,
    required String category,
    required String sourceCollection,
  }) {
    return logEvent(
      AppAnalyticsEvents.campaignViewed,
      parameters: <String, Object?>{
        'campaign_id': campaignId,
        'business_id': businessId,
        'category': category,
        'source_collection': sourceCollection,
      },
    );
  }

  Future<void> logCampaignReportSubmitted({
    required String campaignId,
    required String businessId,
    required String reason,
    required String sourceCollection,
  }) {
    return logEvent(
      AppAnalyticsEvents.campaignReportSubmitted,
      parameters: <String, Object?>{
        'campaign_id': campaignId,
        'business_id': businessId,
        'reason': reason,
        'source_collection': sourceCollection,
      },
    );
  }

  Future<void> logCampaignCreated({
    required String campaignId,
    required String businessId,
    required String category,
  }) {
    return logEvent(
      AppAnalyticsEvents.campaignCreated,
      parameters: <String, Object?>{
        'campaign_id': campaignId,
        'business_id': businessId,
        'category': category,
      },
    );
  }

  Future<void> logMessageSent({
    required String threadId,
    required String senderRole,
    String businessId = '',
  }) {
    return logEvent(
      AppAnalyticsEvents.messageSent,
      parameters: <String, Object?>{
        'thread_id': threadId,
        'sender_role': senderRole,
        'business_id': businessId,
      },
    );
  }

  Future<void> logFinanceActionCompleted({
    required String actionType,
    required String businessId,
    int amountKurus = 0,
  }) {
    return logEvent(
      AppAnalyticsEvents.financeActionCompleted,
      parameters: <String, Object?>{
        'action_type': actionType,
        'business_id': businessId,
        'amount_kurus': amountKurus,
      },
    );
  }

  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  }) async {
    if (!_supportsCrashlytics) return;

    await _guardCrashlytics(() {
      if (fatal) {
        return FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
      return FirebaseCrashlytics.instance.recordFlutterError(details);
    });
  }

  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    String? reason,
  }) async {
    if (!_supportsCrashlytics) return;

    await _guardCrashlytics(
      () => FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: fatal,
        reason: reason,
      ),
    );
  }

  Future<void> _configureCrashlytics() async {
    if (!_supportsCrashlytics) return;

    await _guardCrashlytics(
      () => FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      ),
    );
  }

  Future<void> _guardCrashlytics(FutureOr<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      debugPrint('Crashlytics operation skipped: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> _guardAnalytics(FutureOr<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      debugPrint('Analytics operation skipped: $error');
      debugPrint('$stackTrace');
    }
  }

  Map<String, Object> _cleanAnalyticsParameters(
    Map<String, Object?> parameters,
  ) {
    final cleaned = <String, Object>{};
    for (final entry in parameters.entries) {
      final key = entry.key.trim();
      final value = entry.value;
      if (key.isEmpty || value == null) continue;
      if (value is String) {
        final text = value.trim();
        if (text.isNotEmpty) cleaned[key] = text;
      } else if (value is bool) {
        cleaned[key] = value ? 1 : 0;
      } else if (value is num) {
        cleaned[key] = value;
      } else {
        final text = value.toString().trim();
        if (text.isNotEmpty) cleaned[key] = text;
      }
    }
    return cleaned;
  }
}

abstract final class AppAnalyticsEvents {
  AppAnalyticsEvents._();

  static const registrationCompleted = 'registration_completed';
  static const locationPermissionResult = 'location_permission_result';
  static const exploreBusinessOpen = 'explore_business_open';
  static const businessClaimSubmitted = 'business_claim_submitted';
  static const appointmentBookingCompleted = 'appointment_booking_completed';
  static const appointmentCancelled = 'appointment_cancelled';
  static const campaignViewed = 'campaign_viewed';
  static const campaignCreated = 'campaign_created';
  static const campaignReportSubmitted = 'campaign_report_submitted';
  static const messageSent = 'message_sent';
  static const financeActionCompleted = 'finance_action_completed';
}
