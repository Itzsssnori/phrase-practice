import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Manages Firebase App Check activation and availability for Firebase AI Logic.
///
/// Must be initialized in `main.dart` right after `Firebase.initializeApp` and
/// BEFORE any other Firebase service is accessed.
class AppCheckService {
  AppCheckService._();

  /// Web reCAPTCHA Enterprise site key passed at build time via:
  /// `--dart-define=APP_CHECK_WEB_SITE_KEY=<your-site-key>`
  static const String webSiteKey = String.fromEnvironment(
    'APP_CHECK_WEB_SITE_KEY',
    defaultValue: '',
  );

  static bool _isTranslatorAvailable = false;

  /// Whether App Check is properly configured so the AI Translator can run.
  static bool get isTranslatorAvailable => _isTranslatorAvailable;

  @visibleForTesting
  static void setTranslatorAvailableForTesting(bool value) {
    _isTranslatorAvailable = value;
  }

  /// Pure helper determining whether App Check can be activated for the given environment.
  ///
  /// On web release builds, a non-empty `APP_CHECK_WEB_SITE_KEY` is required.
  static bool isConfiguredForEnvironment({
    required bool isWeb,
    required bool isDebug,
    required String siteKey,
  }) {
    if (isDebug) return true;
    if (isWeb && siteKey.trim().isEmpty) return false;
    return true;
  }

  /// Activates Firebase App Check using debug providers in debug builds and
  /// recommended platform providers in release builds.
  ///
  /// Failures are non-fatal for the rest of the app; they only mark the AI
  /// translator as unavailable.
  static Future<bool> initialize() async {
    final configured = isConfiguredForEnvironment(
      isWeb: kIsWeb,
      isDebug: kDebugMode,
      siteKey: webSiteKey,
    );

    if (!configured) {
      // Missing APP_CHECK_WEB_SITE_KEY in release web build:
      // do not activate a fake provider.
      _isTranslatorAvailable = false;
      return false;
    }

    try {
      await FirebaseAppCheck.instance.activate(
        providerWeb: kDebugMode
            ? WebDebugProvider()
            : ReCaptchaEnterpriseProvider(webSiteKey.trim()),
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );
      _isTranslatorAvailable = true;
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('App Check activation failed (non-fatal): $e');
      }
      _isTranslatorAvailable = false;
      return false;
    }
  }
}
