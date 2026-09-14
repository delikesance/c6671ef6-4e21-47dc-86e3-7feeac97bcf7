import 'package:flutter/foundation.dart';

import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/core/i18n/locale_provider.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';

/// The user properties every activation-funnel event is read through.
///
/// One refresh point, one call at startup: the values are gathered here and
/// handed to [AppAnalytics.setUserProperties], which publishes them. Nothing
/// else in the app sets a user property, and this never polls — a value that
/// changed is pushed again by its own flow.
///
/// Every value is a bucket or an enumerated label. A bot id, a guild count or
/// a duration must never reach a user property: unlike an event parameter, a
/// high-cardinality value stays in the console's user-property list forever.
class AppUserProperties {
  AppUserProperties._();

  /// Closed values of `platform`.
  ///
  /// `unknown` covers the platforms the app never targets (`fuchsia`): the
  /// property is always published, so the console sees a bounded label rather
  /// than a missing dimension.
  static const List<String> platforms = <String>[
    'android',
    'ios',
    'windows',
    'macos',
    'linux',
    'web',
    'unknown',
  ];

  /// Closed values of `bot_count_bucket`.
  static const List<String> botCountBuckets = <String>['0', '1', '2-5', '6+'];

  /// Closed values of `premium_tier`.
  static const List<String> premiumTiers = <String>['free', 'premium'];

  /// The language code the app runs in when it cannot be read: the ARB
  /// fallback locale, and the first value of the closed list.
  static const String fallbackLocale = 'en';

  /// The platform the app is running on.
  static String platformName() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'unknown';
    }
  }

  /// Reduces a bot count to one of [botCountBuckets].
  static String botCountBucket(int botCount) {
    if (botCount <= 0) return botCountBuckets[0];
    if (botCount == 1) return botCountBuckets[1];
    if (botCount <= 5) return botCountBuckets[2];
    return botCountBuckets[3];
  }

  /// Reduces the subscription state to one of [premiumTiers].
  static String premiumTier(bool isSubscribed) =>
      isSubscribed ? premiumTiers[1] : premiumTiers[0];

  /// Where the values come from, as function fields: a unit test replaces them
  /// with fakes, the app runs on the real sources.
  static Future<int> Function() _botCountSource = _liveBotCount;
  static bool Function() _premiumSource = _livePremium;
  static Future<String> Function() _localeSource = _liveLanguageCode;

  /// Publishes the four properties.
  ///
  /// Never throws: it runs inside the startup warm-up, where a missing store
  /// or a preferences failure must not become a startup failure. A source that
  /// fails contributes its first (bounded) value instead.
  static Future<void> refresh() async {
    final botCount = await _readBotCount();
    final locale = await _readLocale();
    final premium = _readPremium();

    await AppAnalytics.setUserProperties(
      platform: platformName(),
      premiumTier: premiumTier(premium),
      botCountBucket: botCountBucket(botCount),
      locale: locale,
    );
  }

  static Future<int> _readBotCount() async {
    try {
      return await _botCountSource();
    } catch (_) {
      return 0;
    }
  }

  static Future<String> _readLocale() async {
    try {
      final code = (await _localeSource()).trim().toLowerCase();
      return code.isEmpty ? fallbackLocale : code;
    } catch (_) {
      return fallbackLocale;
    }
  }

  static bool _readPremium() {
    try {
      return _premiumSource();
    } catch (_) {
      return false;
    }
  }

  /// Replaces the sources. Test-only: the app always runs on the real ones.
  @visibleForTesting
  static void debugSetSources({
    Future<int> Function()? botCount,
    bool Function()? isPremium,
    Future<String> Function()? languageCode,
  }) {
    _botCountSource = botCount ?? _liveBotCount;
    _premiumSource = isPremium ?? _livePremium;
    _localeSource = languageCode ?? _liveLanguageCode;
  }

  /// Restores the real sources, so one test cannot leak its fakes into the
  /// next one.
  @visibleForTesting
  static void debugResetSources() {
    _botCountSource = _liveBotCount;
    _premiumSource = _livePremium;
    _localeSource = _liveLanguageCode;
  }

  static Future<int> _liveBotCount() async =>
      (await AppManager().getAllApps()).length;
  static bool _livePremium() => SubscriptionService.isSubscribed;
  static Future<String> _liveLanguageCode() =>
      LocaleProvider.currentLanguageCode();
}
