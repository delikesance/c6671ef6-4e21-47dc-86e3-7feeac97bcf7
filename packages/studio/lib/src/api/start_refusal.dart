import 'package:bot_creator_ui/bot_creator_ui.dart';

import '../l10n_ext.dart';
import 'studio_api.dart';

/// Pourquoi le serveur a refusé de lancer un bot. Même table que
/// `planLimitRefusalFromError` de l'app : le CODE applicatif fait foi, la
/// phrase n'est qu'un repli pour les serveurs plus anciens. Les textes sont
/// ceux de l'app (`plan_limit_*`), dans la langue de l'écran.
enum StartRefusal {
  excludesOwnBots,
  botQuotaReached,
  excludesTurnkey,
  turnkeyQuotaReached,
  noFreeTime;

  String title(StudioLocalizations l, AppLocalizations tr) => switch (this) {
    excludesOwnBots => tr.plan_limit_own_bots_title,
    botQuotaReached => tr.plan_limit_bot_quota_title,
    excludesTurnkey => tr.plan_limit_turnkey_title,
    turnkeyQuotaReached => tr.plan_limit_turnkey_quota_title,
    noFreeTime => l.refusalNoFreeTimeTitle,
  };

  String body(StudioLocalizations l, AppLocalizations tr) => switch (this) {
    excludesOwnBots => tr.plan_limit_own_bots_desc,
    botQuotaReached => tr.plan_limit_bot_quota_desc,
    excludesTurnkey => tr.plan_limit_turnkey_desc,
    turnkeyQuotaReached => tr.plan_limit_turnkey_quota_desc,
    noFreeTime => l.refusalNoFreeTimeBody,
  };

  static StartRefusal? fromError(Object error) {
    if (error is! StudioApiException) return null;
    final code = (error.code ?? '').toLowerCase();
    final message = error.message.toLowerCase();
    bool has(String c, String phrase) => code == c || message.contains(phrase);
    if (has('own_bots_not_allowed', 'does not include personal bots')) {
      return excludesOwnBots;
    }
    if (has('bot_quota_reached', 'personal bot limit reached')) {
      return botQuotaReached;
    }
    if (has('turnkey_not_allowed', 'does not include turnkey apps')) {
      return excludesTurnkey;
    }
    if (has('turnkey_quota_reached', 'turnkey app limit reached')) {
      return turnkeyQuotaReached;
    }
    if (error.isTransientStartRefusal && code == 'bot_free_time_required') {
      return noFreeTime;
    }
    return null;
  }
}
