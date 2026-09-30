import 'dart:async';
import 'package:bot_creator/features/ads/logic/ad_reward_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Local completion only starts polling; the server alone awards the spin.
Future<bool> showAIRewardAd({
  required String adUnit,
  required String owner,
  required String ticket,
}) async {
  await AdRewardService.initialize();
  final loaded = Completer<RewardedAd>();
  RewardedAd.load(
    adUnitId: adUnit,
    request: const AdRequest(),
    rewardedAdLoadCallback: RewardedAdLoadCallback(
      onAdLoaded: (ad) {
        if (loaded.isCompleted) {
          ad.dispose();
        } else {
          loaded.complete(ad);
        }
      },
      onAdFailedToLoad: (error) {
        if (!loaded.isCompleted) loaded.completeError(error);
      },
    ),
  );
  final timeout = Timer(const Duration(seconds: 20), () {
    if (!loaded.isCompleted) {
      loaded.completeError(TimeoutException('Ad loading timed out'));
    }
  });
  late RewardedAd ad;
  try {
    ad = await loaded.future;
  } finally {
    timeout.cancel();
  }
  try {
    await ad.setServerSideOptions(
      ServerSideVerificationOptions(
        userId: owner,
        customData: 'ai_roulette:$ticket',
      ),
    );
    final dismissed = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) {
        if (!dismissed.isCompleted) dismissed.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (_, error) {
        if (!dismissed.isCompleted) dismissed.completeError(error);
      },
    );
    ad.show(onUserEarnedReward: (_, _) => earned = true);
    return await dismissed.future.timeout(const Duration(minutes: 3));
  } finally {
    ad.dispose();
  }
}
