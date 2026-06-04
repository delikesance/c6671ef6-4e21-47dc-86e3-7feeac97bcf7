import 'dart:async';
import 'dart:io';

import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:gma_mediation_ironsource/gma_mediation_ironsource.dart';
import 'package:gma_mediation_unity/gma_mediation_unity.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdConsentService {
  AdConsentService._();

  static Future<bool>? _inFlightRequest;
  static const Duration _consentInfoTimeout = Duration(seconds: 15);
  static const Duration _consentFormTimeout = Duration(seconds: 20);
  static const Duration _privacyOptionsTimeout = Duration(seconds: 20);

  static bool get _isSupportedPlatform {
    if (kIsWeb) {
      return false;
    }
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Triggers Google's UMP consent flow when required and returns whether ads
  /// can be requested after the flow completes.
  static Future<bool> ensureCanRequestAds({
    bool requestTrackingTransparency = true,
  }) async {
    if (!_isSupportedPlatform) {
      return false;
    }

    final pending = _inFlightRequest;
    if (pending != null) {
      return pending;
    }

    final completer = Completer<bool>();
    _inFlightRequest = completer.future;

    try {
      if (requestTrackingTransparency) {
        await requestTrackingTransparencyIfNeeded();
      }
      await _requestConsentInfoUpdate();
      await _loadAndShowConsentFormIfRequired();

      final canRequestAds = await ConsentInformation.instance.canRequestAds();
      await forwardConsentToMediationPartners(canRequestAds);
      unawaited(
        AppDiagnostics.logInfo(
          'UMP consent completed',
          data: {'canRequestAds': canRequestAds},
        ),
      );
      completer.complete(canRequestAds);
      return canRequestAds;
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'UMP consent flow failed',
          error,
          stack,
          fatal: false,
        ),
      );

      try {
        final canRequestAds = await ConsentInformation.instance.canRequestAds();
        await forwardConsentToMediationPartners(canRequestAds);
        completer.complete(canRequestAds);
        return canRequestAds;
      } catch (_) {
        await forwardConsentToMediationPartners(false);
        completer.complete(false);
        return false;
      }
    } finally {
      _inFlightRequest = null;
    }
  }

  static Future<void> requestTrackingTransparencyIfNeeded() async {
    if (!Platform.isIOS) {
      return;
    }

    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        final updatedStatus =
            await AppTrackingTransparency.requestTrackingAuthorization();
        unawaited(
          AppDiagnostics.logInfo(
            'ATT authorization requested',
            data: {
              'initialStatus': status.name,
              'updatedStatus': updatedStatus.name,
            },
          ),
        );
      }
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'ATT authorization request failed',
          error,
          stack,
          fatal: false,
        ),
      );
    }
  }

  static Future<void> _requestConsentInfoUpdate() {
    final completer = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(
        tagForUnderAgeOfConsent: false,
        consentDebugSettings:
            kReleaseMode
                ? null
                : ConsentDebugSettings(
                  debugGeography: DebugGeography.debugGeographyEea,
                  testIdentifiers: const ['2214CFDBCFAD5ACC7D062BE23959B7B1'],
                ),
      ),
      () {
        if (!completer.isCompleted) completer.complete();
      },
      (formError) {
        // Log error but don't fail hard - allow app to continue with default consent.
        // Use logInfo (NOT logError) — UMP SDK errors are expected on some devices.
        unawaited(
          AppDiagnostics.logInfo(
            'requestConsentInfoUpdate SDK error (${formError.errorCode}): ${formError.message}',
            data: {'errorCode': formError.errorCode, 'message': formError.message},
          ),
        );
        if (!completer.isCompleted) completer.complete();
      },
    );

    return completer.future.timeout(
      _consentInfoTimeout,
      onTimeout: () {
        // Log timeout but complete successfully to allow app to continue.
        // Use logInfo (NOT logError) — slow networks are expected, not crashes.
        unawaited(
          AppDiagnostics.logInfo(
            'requestConsentInfoUpdate did not complete within ${_consentInfoTimeout.inSeconds}s',
            data: {'timeoutSeconds': _consentInfoTimeout.inSeconds},
          ),
        );
        if (!completer.isCompleted) completer.complete();
      },
    );
  }

  static Future<void> _loadAndShowConsentFormIfRequired() {
    final completer = Completer<void>();

    ConsentForm.loadAndShowConsentFormIfRequired((formError) {
      if (formError != null) {
        unawaited(
          AppDiagnostics.logInfo(
            'UMP form dismissed with error',
            data: {'code': formError.errorCode, 'message': formError.message},
          ),
        );
      }
      if (!completer.isCompleted) completer.complete();
    });

    return completer.future.timeout(
      _consentFormTimeout,
      onTimeout: () {
        // Log timeout but complete successfully to allow app to continue.
        // Use logInfo (NOT logError) — slow networks are expected, not crashes.
        unawaited(
          AppDiagnostics.logInfo(
            'loadAndShowConsentFormIfRequired did not complete within ${_consentFormTimeout.inSeconds}s',
            data: {'timeoutSeconds': _consentFormTimeout.inSeconds},
          ),
        );
        if (!completer.isCompleted) completer.complete();
      },
    );
  }

  static Future<PrivacyOptionsRequirementStatus>
  getPrivacyOptionsRequirementStatus() async {
    if (!_isSupportedPlatform) {
      return PrivacyOptionsRequirementStatus.notRequired;
    }

    try {
      await _requestConsentInfoUpdate();
      return ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'Failed to fetch UMP privacy options requirement status',
          error,
          stack,
          fatal: false,
        ),
      );
      return PrivacyOptionsRequirementStatus.unknown;
    }
  }

  static Future<bool> isPrivacyOptionsRequired() async {
    final status = await getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }

  static Future<bool> showPrivacyOptionsForm() async {
    if (!_isSupportedPlatform) {
      return false;
    }

    final completer = Completer<bool>();
    ConsentForm.showPrivacyOptionsForm((formError) {
      if (formError != null) {
        unawaited(
          AppDiagnostics.logInfo(
            'UMP privacy options dismissed with error',
            data: {'code': formError.errorCode, 'message': formError.message},
          ),
        );
        completer.complete(false);
        return;
      }
      completer.complete(true);
    });
    return completer.future.timeout(
      _privacyOptionsTimeout,
      onTimeout: () {
        unawaited(
          AppDiagnostics.logInfo(
            'UMP privacy options form timed out',
            data: {'timeoutSeconds': _privacyOptionsTimeout.inSeconds},
          ),
        );
        return false;
      },
    );
  }

  /// Forwards the user's consent status to mediation partner SDKs.
  ///
  /// Must be called **before** [MobileAds.instance.initialize] so that the
  /// buyer-generated data (GDPR / CCPA signals) is included in bid requests.
  static Future<void> forwardConsentToMediationPartners(bool hasConsent) async {
    try {
      final unity = GmaMediationUnity();
      await unity.setGDPRConsent(hasConsent);
      await unity.setCCPAConsent(hasConsent);
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'Failed to forward consent to Unity Ads',
          error,
          stack,
          fatal: false,
        ),
      );
    }

    try {
      final ironSource = GmaMediationIronsource();
      await ironSource.setConsent(hasConsent);
      await ironSource.setDoNotSell(!hasConsent);
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'Failed to forward consent to ironSource',
          error,
          stack,
          fatal: false,
        ),
      );
    }
  }
}
