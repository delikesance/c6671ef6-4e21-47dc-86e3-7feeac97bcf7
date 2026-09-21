import 'dart:async';
import 'dart:io';

import 'package:bot_creator/features/ads/logic/ad_mediation_debug.dart';
import 'package:bot_creator/features/ads/logic/ad_ssv_context.dart';
import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Les appelants historiques importent ce fichier pour `AdRewardSsvContext` ;
// le type vit désormais dans `ad_ssv_context.dart` avec les constructeurs
// partagés, et reste ré-exporté ici.
export 'package:bot_creator/features/ads/logic/ad_ssv_context.dart'
    show AdRewardSsvContext, BotAdSsvOwnerIds;

class AdRewardService {
  AdRewardService._();

  static const String _androidRewardedUnitId =
      'ca-app-pub-9146609240142753/1438617123';
  static const String _iosRewardedUnitId =
      'ca-app-pub-9146609240142753/2977961908';

  static const String _testRewardedUnitId =
      'ca-app-pub-9146609240142753/6223806805';

  static bool _initialized = false;
  static bool _isLoading = false;
  static bool _isShowing = false;
  static RewardedAd? _rewardedAd;

  /// Keep a short cooldown to prevent accidental rapid double taps.
  static const Duration _cooldown = Duration(seconds: 15);
  static DateTime? _lastShownAt;

  static bool get _isSupportedPlatform {
    if (kIsWeb) {
      return false;
    }
    return Platform.isAndroid || Platform.isIOS;
  }

  static bool get hasReadyRewardedAd => _rewardedAd != null;

  static String get _rewardedUnitId {
    if (!kReleaseMode) {
      return _testRewardedUnitId;
    }
    if (Platform.isAndroid) {
      return _androidRewardedUnitId;
    }
    return _iosRewardedUnitId;
  }

  static Future<void> initialize() async {
    if (_initialized || !_isSupportedPlatform) {
      return;
    }

    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      unawaited(
        AppDiagnostics.logInfo(
          'Rewarded ads initialized',
          data: {'platform': Platform.operatingSystem, 'release': kReleaseMode},
        ),
      );
      _preloadRewardedAd();
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'Failed to initialize rewarded ads',
          error,
          stack,
          fatal: false,
        ),
      );
    }
  }

  static Future<bool> shouldOfferRewardedAd({
    bool checkPremiumCapability = true,
  }) async {
    if (!_initialized || !_isSupportedPlatform) return false;
    if (checkPremiumCapability &&
        PremiumCapabilities.hasCapability(PremiumCapability.noAds)) {
      return false;
    }
    if (_lastShownAt != null &&
        DateTime.now().difference(_lastShownAt!) < _cooldown) {
      return false;
    }
    return true;
  }

  /// Shows the rewarded ad and returns a [Future] that completes when the ad
  /// is dismissed or fails to show. Returns `true` if the ad was shown
  /// successfully, `false` otherwise (no ad ready, already showing, failed).
  static Future<bool> showRewardedAd({
    AdRewardSsvContext? ssvContext,
    Future<void> Function()? onRewardEarned,
  }) async {
    if (!_initialized || !_isSupportedPlatform) {
      return false;
    }

    if (_isShowing) {
      return false;
    }

    final ad = _rewardedAd;
    if (ad == null) {
      _preloadRewardedAd();
      return false;
    }

    final ssvConfigured = await _applySsvContext(ad, ssvContext);
    if (!ssvConfigured) {
      _rewardedAd = null;
      ad.dispose();
      _preloadRewardedAd();
      return false;
    }

    _rewardedAd = null;
    _isShowing = true;
    _lastShownAt = DateTime.now();

    final completer = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        unawaited(AppDiagnostics.logInfo('Rewarded ad displayed'));
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isShowing = false;
        _preloadRewardedAd();
        if (!completer.isCompleted) completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isShowing = false;
        unawaited(
          AppDiagnostics.logInfo(
            'Rewarded ad failed to show',
            data: {'error': error.message, 'code': error.code},
          ),
        );
        _preloadRewardedAd();
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    ad.show(
      onUserEarnedReward: (_, reward) {
        _notifyRewardEarned(onRewardEarned);
        unawaited(
          AppDiagnostics.logInfo(
            'Reward earned from rewarded ad',
            data: {'amount': reward.amount, 'type': reward.type},
          ),
        );
      },
    );

    // Safety timeout so we never block forever.
    return completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        _isShowing = false;
        return false;
      },
    );
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  /// Applique le contexte SSV à l'annonce chargée.
  ///
  /// Renvoie `false` — et donc refuse de montrer l'annonce — quand aucun
  /// contexte exploitable n'est fourni : sans lui, le callback AdMob arrive
  /// sans mapping côté Manager et la récompense de l'utilisateur est perdue
  /// (c'est exactement le bug « ignored missing bot mapping » observé en prod,
  /// où l'annonce était montée sans aucune option de vérification serveur).
  static Future<bool> _applySsvContext(
    RewardedAd ad,
    AdRewardSsvContext? ssvContext,
  ) async {
    final context = ssvContext;
    if (context == null || !canShowRewardedAdWithSsv(context)) {
      unawaited(
        AppDiagnostics.logError(
          'Rewarded ad refused: no server-side verification context',
          StateError('missing_ssv_context'),
          StackTrace.current,
          fatal: false,
          reason:
              'userId/customData absents : montrer l\'annonce perdrait la récompense.',
        ),
      );
      return false;
    }

    try {
      await ad.setServerSideOptions(
        ServerSideVerificationOptions(
          userId: _nonEmpty(context.userId),
          customData: _nonEmpty(context.customData),
        ),
      );
      return true;
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'Failed to configure rewarded ad server-side verification',
          error,
          stack,
          fatal: false,
        ),
      );
      return false;
    }
  }

  static void _notifyRewardEarned(Future<void> Function()? callback) {
    if (callback == null) {
      return;
    }
    try {
      unawaited(callback());
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'Reward callback failed',
          error,
          stack,
          fatal: false,
        ),
      );
    }
  }

  static void preload() {
    _preloadRewardedAd();
  }

  static Future<bool> ensureAdLoaded({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!_initialized || !_isSupportedPlatform) return false;
    if (hasReadyRewardedAd) return true;
    _preloadRewardedAd();

    final completer = Completer<bool>();
    final timer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      if (hasReadyRewardedAd) {
        t.cancel();
        if (!completer.isCompleted) completer.complete(true);
      }
    });

    try {
      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          timer.cancel();
          return hasReadyRewardedAd;
        },
      );
    } catch (_) {
      timer.cancel();
      return hasReadyRewardedAd;
    }
  }

  static void _preloadRewardedAd() {
    if (!_initialized || _isLoading || _rewardedAd != null) {
      return;
    }

    _isLoading = true;
    RewardedAd.load(
      adUnitId: _rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _rewardedAd = ad;
          AdMediationDebug.logResponseInfo(
            format: 'rewarded',
            placement: 'bot_start',
            responseInfo: ad.responseInfo,
          );
          unawaited(AppDiagnostics.logInfo('Rewarded ad loaded'));
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          unawaited(
            AppDiagnostics.logInfo(
              'Rewarded ad load failed',
              data: {'error': error.message, 'code': error.code},
            ),
          );
          // Auto-retry in 15 seconds to ensure we recover from transient failures
          Future<void>.delayed(const Duration(seconds: 15), () {
            _preloadRewardedAd();
          });
        },
      ),
    );
  }
}
