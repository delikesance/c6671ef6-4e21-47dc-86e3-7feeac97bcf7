import 'studio_api.dart';

/// Pourquoi le serveur a refusé de lancer un bot. Même table que
/// `planLimitRefusalFromError` de l'app : le CODE applicatif fait foi, la
/// phrase n'est qu'un repli pour les serveurs plus anciens.
enum StartRefusal {
  excludesOwnBots(
    'Bots perso non inclus dans votre formule',
    "Votre formule donne accès aux bots clé en main uniquement. Passez à une formule qui inclut les bots perso pour démarrer celui-ci.",
  ),
  botQuotaReached(
    'Limite de bots en marche atteinte',
    "Votre formule limite le nombre de bots en marche en même temps. Arrêtez un bot, ou passez à une formule supérieure.",
  ),
  excludesTurnkey(
    'Bots clé en main non inclus dans votre formule',
    "Votre formule ne donne pas accès aux bots clé en main ni aux applications hébergées. Choisissez une formule qui les inclut.",
  ),
  turnkeyQuotaReached(
    'Limite de bots clé en main atteinte',
    "Votre formule limite le nombre de bots clé en main en marche en même temps. Arrêtez-en un, ou passez à une formule supérieure.",
  ),
  noFreeTime(
    "Temps d'hébergement épuisé",
    "Ce bot n'a plus de temps d'hébergement gratuit. Regardez une publicité depuis l'application mobile pour en gagner, ou passez Premium. Le Studio ne propose ni publicité ni achat.",
  );

  const StartRefusal(this.title, this.body);

  final String title;
  final String body;

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
