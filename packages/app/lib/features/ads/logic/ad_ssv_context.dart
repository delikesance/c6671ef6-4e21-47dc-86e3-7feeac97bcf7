// Source unique des contextes SSV (Server-Side Verification) des annonces
// récompensées.
//
// Sans `custom_data`, le callback AdMob arrive au Manager sans mapping
// (`ignored missing bot mapping`) et la récompense est perdue sans trace : la
// construction du texte SSV est donc centralisée ici, pour qu'il n'existe
// qu'une seule copie partagée par l'accueil et l'éditeur de bot.

/// Placement du flux « bot » (démarrage / temps d'exécution), celui que le
/// Manager attend par défaut.
const String mainApiAdSsvPlacement = 'admob_rewarded';

/// Placement du flux « application hébergée » (minutes d'hébergement).
const String hostedAppAdSsvPlacement = 'hosted_app_topup';

/// Contexte de vérification serveur d'une annonce récompensée.
///
/// Il est exigé par `AdRewardService.showRewardedAd` : sans `userId` ni
/// `customData`, le callback AdMob ne peut être rattaché à un compte et la
/// récompense est jetée côté serveur.
class AdRewardSsvContext {
  const AdRewardSsvContext({this.userId, this.customData});

  final String? userId;
  final String? customData;

  bool get hasValues {
    final user = userId?.trim() ?? '';
    final custom = customData?.trim() ?? '';
    return user.isNotEmpty || custom.isNotEmpty;
  }
}

/// Identifiants propriétaire résolus par un écran avant de construire le
/// contexte du flux « bot ».
///
/// La résolution (session Manager seule, ou session + métadonnées Discord de
/// l'application) reste propre à chaque écran ; seule la composition du
/// contexte est partagée.
class BotAdSsvOwnerIds {
  const BotAdSsvOwnerIds({required this.ownerId, this.discordOwnerId});

  final String ownerId;
  final String? discordOwnerId;
}

/// Décision, volontairement pure, « peut-on monter cette annonce ? ».
///
/// Sans contexte SSV exploitable, l'annonce ne doit PAS être montrée : le
/// callback AdMob arriverait sans mapping côté Manager et la récompense de
/// l'utilisateur serait perdue sans trace. `AdRewardService._applySsvContext`
/// s'appuie sur cette fonction, donc la règle est couverte par les tests.
bool canShowRewardedAdWithSsv(AdRewardSsvContext? ssvContext) =>
    ssvContext != null && ssvContext.hasValues;

/// Contexte SSV du flux « bot » : `owner_id` + `bot_id` + `placement`, plus
/// `discord_owner_id` quand l'appelant sait le résoudre.
///
/// Renvoie `null` quand un identifiant indispensable manque : l'annonce ne
/// doit alors PAS être montrée, sinon la récompense est perdue.
AdRewardSsvContext? buildBotAdSsvContext({
  required String ownerId,
  required String botId,
  String? discordOwnerId,
  String placement = mainApiAdSsvPlacement,
}) {
  final owner = ownerId.trim();
  final bot = botId.trim();
  if (owner.isEmpty || bot.isEmpty) {
    return null;
  }

  final resolvedPlacement = placement.trim().isEmpty
      ? mainApiAdSsvPlacement
      : placement.trim();
  final discordOwner = (discordOwnerId ?? '').trim();

  return AdRewardSsvContext(
    userId: owner,
    customData: Uri(
      queryParameters: <String, String>{
        'owner_id': owner,
        'bot_id': bot,
        'placement': resolvedPlacement,
        if (discordOwner.isNotEmpty) 'discord_owner_id': discordOwner,
      },
    ).query,
  );
}

/// Construit, à partir des identifiants d'un bot, le contexte SSV partagé par
/// l'accueil et l'éditeur de bot.
///
/// Le flux est asynchrone parce que [resolveOwnerIds] interroge la session
/// Manager (et, pour l'éditeur, les métadonnées Discord de l'application).
/// Renvoie `null` — et donc « ne pas montrer l'annonce » — dès qu'un token,
/// une session ou un identifiant manque.
Future<AdRewardSsvContext?> buildMainApiAdSsvContext({
  required String botId,
  required Future<BotAdSsvOwnerIds?> Function() resolveOwnerIds,
}) async {
  if (botId.trim().isEmpty) {
    return null;
  }

  final ids = await resolveOwnerIds();
  if (ids == null) {
    return null;
  }

  return buildBotAdSsvContext(
    ownerId: ids.ownerId,
    botId: botId,
    discordOwnerId: ids.discordOwnerId,
  );
}

/// Contexte SSV du flux « application hébergée » : `owner_id` + `placement`
/// (+ `container_id` quand il est connu).
///
/// Ce flux n'a pas de bot : `bot_id` est volontairement absent, et le crédit
/// réel des minutes reste fait par `MainApiClient.claimHostedAppAd`. Le
/// `custom_data` sert ici à ce que le callback AdMob soit rattachable à un
/// compte et à un conteneur au lieu d'arriver anonyme.
AdRewardSsvContext? buildHostedAppAdSsvContext({
  required String ownerId,
  required String placement,
  String? containerId,
}) {
  final owner = ownerId.trim();
  if (owner.isEmpty) {
    return null;
  }

  final resolvedPlacement = placement.trim().isEmpty
      ? hostedAppAdSsvPlacement
      : placement.trim();
  final container = (containerId ?? '').trim();

  return AdRewardSsvContext(
    userId: owner,
    customData: Uri(
      queryParameters: <String, String>{
        'owner_id': owner,
        'placement': resolvedPlacement,
        if (container.isNotEmpty) 'container_id': container,
      },
    ).query,
  );
}
