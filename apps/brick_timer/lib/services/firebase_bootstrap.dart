import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Configures Firebase services used by the application.
final class FirebaseBootstrap {
  static FirebaseAnalyticsObserver? _analyticsObserver;

  static const String _enabledDefine = 'FIREBASE_ENABLED';
  static const String _webRecaptchaDefine =
      'FIREBASE_APPCHECK_RECAPTCHA_SITE_KEY';

  /// Navigator observers backed by Firebase Analytics when available.
  static List<NavigatorObserver> get navigatorObservers {
    final observer = _analyticsObserver;
    return observer == null
        ? const <NavigatorObserver>[]
        : <NavigatorObserver>[observer];
  }

  /// Initializes Firebase and related telemetry/integrity services.
  static Future<void> initialize() async {
    if (!const bool.fromEnvironment(_enabledDefine)) {
      return;
    }

    try {
      await Firebase.initializeApp();
    } on Object catch (error, stackTrace) {
      debugPrint('Firebase initialization skipped: $error\n$stackTrace');
      return;
    }

    await _configureCrashlytics();
    await _configureAppCheck();
    _configureAnalytics();
  }

  static Future<void> _configureCrashlytics() async {
    final crashlytics = FirebaseCrashlytics.instance;
    const collectReports = !kDebugMode;

    await crashlytics.setCrashlyticsCollectionEnabled(collectReports);

    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      previousOnError?.call(details);
      unawaited(crashlytics.recordFlutterFatalError(details));
    };

    final previousPlatformError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      unawaited(crashlytics.recordError(error, stackTrace, fatal: true));
      return previousPlatformError?.call(error, stackTrace) ?? true;
    };
  }

  static Future<void> _configureAppCheck() async {
    final webRecaptchaSiteKey = const String.fromEnvironment(
      _webRecaptchaDefine,
    ).trim();

    final webProvider = kIsWeb && webRecaptchaSiteKey.isNotEmpty
        ? ReCaptchaV3Provider(webRecaptchaSiteKey)
        : null;

    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleAppAttestWithDeviceCheckFallbackProvider(),
        providerWeb: webProvider,
      );
    } on Object catch (error, stackTrace) {
      debugPrint('Firebase App Check activation skipped: $error\n$stackTrace');
    }
  }

  static void _configureAnalytics() {
    final analytics = FirebaseAnalytics.instance;
    _analyticsObserver ??= FirebaseAnalyticsObserver(analytics: analytics);
  }
}
