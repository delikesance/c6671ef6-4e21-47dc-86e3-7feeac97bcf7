import 'dart:async';
import 'dart:io';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/features/ads/logic/ad_reward_service.dart';
import 'package:uuid/uuid.dart';

/// Result of watching a rewarded ad for hosted-app hosting minutes.
class HostedAppAdTopUpResult {
  const HostedAppAdTopUpResult({
    required this.grantedMinutes,
    required this.hostingMinutesBalance,
    this.appliedToContainer = false,
  });

  final int grantedMinutes;
  final int hostingMinutesBalance;
  final bool appliedToContainer;
}

/// Shared ad + claim (+ optional TTL apply) flow for hosted Docker apps.
class HostedAppHostingActions {
  const HostedAppHostingActions._();

  static Future<String?> resolveOwnerId() async {
    final session = await MainApiSettingsStore.loadSession();
    if (session == null || session.isExpired) return null;
    return session.userId;
  }

  static Future<HostedAppAdTopUpResult?> watchAdAndClaim({
    required MainApiClient client,
    String? ownerId,
    String placement = 'hosted_app_topup',
    String? containerId,
    bool applyToContainer = false,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError('Rewarded ads are only available on mobile.');
    }

    final resolvedOwnerId = ownerId ?? await resolveOwnerId();

    if (!AdRewardService.hasReadyRewardedAd) {
      final loaded = await AdRewardService.ensureAdLoaded(
        timeout: const Duration(seconds: 6),
      );
      if (!loaded) {
        throw StateError('No ad available right now.');
      }
    }

    if (!await AdRewardService.shouldOfferRewardedAd(
      checkPremiumCapability: false,
    )) {
      throw StateError('Ad cooldown is active. Try again in a moment.');
    }

    var rewardEarned = false;
    final rewardId = const Uuid().v4();
    final adShown = await AdRewardService.showRewardedAd(
      ssvContext: AdRewardSsvContext(userId: resolvedOwnerId),
      onRewardEarned: () async {
        rewardEarned = true;
      },
    );
    if (!adShown || !rewardEarned) {
      throw StateError('Ad not completed — no minutes granted.');
    }

    final result = await client.claimHostedAppAd(
      placement: placement,
      rewardId: rewardId,
      idempotencyKey: rewardId,
    );

    var applied = false;
    if (applyToContainer &&
        containerId != null &&
        containerId.isNotEmpty &&
        result.grantedMinutes > 0) {
      await client.extendContainerTTL(containerId, result.grantedMinutes);
      applied = true;
    }

    return HostedAppAdTopUpResult(
      grantedMinutes: result.grantedMinutes,
      hostingMinutesBalance: result.hostingMinutesBalance,
      appliedToContainer: applied,
    );
  }
}
