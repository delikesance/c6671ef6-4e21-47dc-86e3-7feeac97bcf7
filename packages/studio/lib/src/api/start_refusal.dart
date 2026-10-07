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
  noFreeTime,
  runnerCapacity,
  runnerUpdating,
  invalidConfig;

  String title(StudioLocalizations l, AppLocalizations tr) => switch (this) {
    excludesOwnBots => tr.plan_limit_own_bots_title,
    botQuotaReached => tr.plan_limit_bot_quota_title,
    excludesTurnkey => tr.plan_limit_turnkey_title,
    turnkeyQuotaReached => tr.plan_limit_turnkey_quota_title,
    noFreeTime => l.refusalNoFreeTimeTitle,
    runnerCapacity || runnerUpdating => l.botStartFailed,
    invalidConfig => l.botStartFailed,
  };

  String body(StudioLocalizations l, AppLocalizations tr) => switch (this) {
    excludesOwnBots => tr.plan_limit_own_bots_desc,
    botQuotaReached => tr.plan_limit_bot_quota_desc,
    excludesTurnkey => tr.plan_limit_turnkey_desc,
    turnkeyQuotaReached => tr.plan_limit_turnkey_quota_desc,
    noFreeTime => l.refusalNoFreeTimeBody,
    runnerCapacity => tr.runtime_runner_capacity,
    runnerUpdating => tr.runtime_runner_updating,
    // Le détail précis vient du serveur : voir [bodyFor].
    invalidConfig => tr.runtime_invalid_bot_config(''),
  };

  /// Le même refus dans la boîte de l'app (`PlanLimitDialog`, avec son bouton
  /// « Voir les offres »). `null` : le manque de temps gratuit n'est pas un
  /// quota de formule, il garde le texte propre au Studio.
  PlanLimitBlock? get planLimit => switch (this) {
    excludesOwnBots => PlanLimitBlock.planExcludesOwnBots,
    botQuotaReached => PlanLimitBlock.planBotQuotaReached,
    excludesTurnkey => PlanLimitBlock.planExcludesTurnkey,
    turnkeyQuotaReached => PlanLimitBlock.planTurnkeyQuotaReached,
    noFreeTime || runnerCapacity || runnerUpdating || invalidConfig => null,
  };

  /// Le texte à montrer : pour une config refusée, le détail du serveur
  /// (« commands[1].script: Required ») est intercalé dans la phrase.
  String bodyFor(StudioLocalizations l, AppLocalizations tr, Object error) {
    if (this == invalidConfig && error is StudioApiException) {
      final marker = error.message.toLowerCase().indexOf('invalid config:');
      final detail = marker >= 0
          ? error.message.substring(marker + 'invalid config:'.length)
          : error.message;
      return tr.runtime_invalid_bot_config(detail.trim());
    }
    return body(l, tr);
  }

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
    if (code == 'runner_capacity') return runnerCapacity;
    if (code == 'runner_updating') return runnerUpdating;
    if (code == 'invalid_bot_config' || message.contains('invalid config:')) {
      return invalidConfig;
    }
    if (error.isTransientStartRefusal && code == 'bot_free_time_required') {
      return noFreeTime;
    }
    return null;
  }
}
