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
}
