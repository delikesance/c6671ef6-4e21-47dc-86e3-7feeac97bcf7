// L'identité RÉELLE d'un bot ne peut venir que de Discord : ce module existe parce que
// personne ne l'interrogeait.
//
// Défaut constaté par le propriétaire : un bot s'affiche sous son ID (`1488275294…`) sur sa
// carte et en tête de sa page, et le manager a lui aussi `"bot_name": "1488275294295949504"`
// pour ce bot — ni l'app ni le serveur n'avaient jamais demandé son nom à Discord. Un nom qui
// vaut l'ID n'est pas un nom : c'est le symptôme que ce fichier répare, avec le seul jeton qui
// ait ce droit, celui du bot.
//
// Trois principes tenus par le code ci-dessous :
//   * on ne réécrit JAMAIS un nom qui est un nom : seul un nom VIDE ou ÉGAL À L'ID déclenche
//     la requête ; un nom choisi par l'utilisateur n'est pas touché ;
//   * au plus UNE tentative par bot et par lancement d'application — la comptabilité vit dans
//     le processus et meurt avec lui, donc aucune synchro répétée ne peut faire de rafale ni se
//     faire refuser en 429 par Discord ;
//   * un échec (hors ligne, jeton refusé, réponse illisible) ne casse rien et n'invente rien :
//     on garde le nom qu'on avait, et la prochaine session retentera — jamais de « Bot 1488… ».
//
// Le nom obtenu est écrit par le CHEMIN D'ÉCRITURE UNIQUE des fiches (`createOrUpdateApp`),
// après relecture de la fiche pour ne rien perdre (préfixe, intents, avatar, jeton — que
// `createOrUpdateApp` sait déjà ne pas effacer). Le jeton n'apparaît NULLE PART dans les
// journaux de ce fichier, ni en entier ni tronqué : on ne journalise que l'identifiant du bot,
// le nom obtenu et un code HTTP.
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/utils/global.dart' show discordUrl;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:nyxx/nyxx.dart' show Snowflake;

/// Identité d'un bot telle que Discord la rend sur `GET /users/@me`.
@immutable
class DiscordBotIdentity {
  const DiscordBotIdentity({
    required this.id,
    required this.username,
    this.avatarHash = '',
    this.discriminator = '',
    this.globalName = '',
    this.bannerHash = '',
    this.accentColor,
  });

  /// Identifiant Discord du bot : sert à VÉRIFIER que le jeton est bien le sien.
  final String id;

  /// Le nom du bot — la seule valeur dont l'app avait besoin ici.
  final String username;

  /// Empreinte d'avatar, ou chaîne vide quand le bot n'a pas d'avatar.
  final String avatarHash;

  /// « 0 » pour les bots migrés aux pseudonymes, sinon les quatre chiffres.
  final String discriminator;

  /// Nom d'affichage global, quand Discord en fournit un (`global_name`).
  final String globalName;

  /// Empreinte de bannière Discord.
  final String bannerHash;

  /// Couleur d'accentuation en entier (hex Discord).
  final int? accentColor;
}

/// Un nom qui vaut l'ID, ou pas de nom du tout, n'apprend rien à personne.
///
/// C'est LA condition du déclenchement, et elle est volontairement étroite : tout autre nom
/// (choisi par l'utilisateur, ou reçu du serveur) est un nom, donc on n'y touche pas.
bool botNameHidesIdentity(String? name, String botId) {
  final trimmedName = (name ?? '').trim();
  final trimmedId = botId.trim();
  if (trimmedName.isEmpty) return true;
  if (trimmedId.isEmpty) return false;
  return trimmedName == trimmedId;
}

/// Bots pour lesquels une tentative a déjà eu lieu dans ce lancement d'application.
///
/// C'est cet ensemble qui tient la promesse « au plus une tentative par bot et par
/// lancement » : il meurt avec le processus, donc un redémarrage rend la récupération
/// possible, mais aucune synchro répétée ne peut la rejouer. Une entrée est posée AVANT
/// l'appel réseau, pour qu'un second déclenchement qui se chevauche ne produise pas un
/// second appel.
final Set<String> _attemptedBotIdentityFetches = <String>{};

/// Vide la comptabilité des tentatives (tests uniquement).
@visibleForTesting
void resetBotIdentityFetchAttempts() => _attemptedBotIdentityFetches.clear();

/// Ce qui est arrivé à la fiche, pour journaliser sans jamais manipuler de jeton.
enum BotIdentitySyncOutcome {
  /// Le nom réel a été obtenu de Discord ET écrit sur ce poste.
  updated,

  /// Le nom local est un vrai nom : rien à faire, aucune requête émise.
  notNeeded,

  /// Une tentative a déjà eu lieu pour ce bot dans ce lancement d'application.
  alreadyAttempted,

  /// Aucun jeton utilisable : sans lui, Discord ne dira rien.
  noToken,

  /// Discord a refusé (jeton révoqué, bot supprimé) ou est injoignable : on garde le nom connu.
  refused,

  /// Écriture impossible : la fiche n'a pas changé, l'app ne ment pas sur ce qu'elle a lu.
  writeFailed,
}

/// Interroge Discord sur l'identité du bot porté par [token] (`GET /users/@me`).
///
/// Rend `null` à la moindre incertitude : statut hors 2xx, corps illisible, panne réseau,
/// délai dépassé. Aucune exception ne sort d'ici — un écran n'a rien à faire d'un crash
/// réseau — et le corps d'une réponse d'erreur n'est jamais journalisé (il peut contenir
/// une trace de la credential refusée).
Future<DiscordBotIdentity?> fetchDiscordBotIdentity({
  required String token,
  http.Client? httpClient,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final trimmedToken = token.trim();
  if (trimmedToken.isEmpty) return null;

  // Client fourni par l'appelant (tests, réutilisation) : on ne ferme que le nôtre.
  final client = httpClient ?? http.Client();
  final ownsClient = httpClient == null;
  try {
    final response = await client
        .get(
          Uri.parse('$discordUrl/users/@me'),
          headers: <String, String>{
            'Authorization': 'Bot $trimmedToken',
            'Accept': 'application/json',
          },
        )
        .timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      developer.log(
        'Discord refused the bot identity request (status=${response.statusCode}).',
        name: 'BotIdentitySync',
      );
      return null;
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map) return null;
    final body = Map<String, dynamic>.from(decoded.cast<dynamic, dynamic>());
    final username = (body['username'] ?? '').toString().trim();
    if (username.isEmpty) {
      // Un nom vide n'est pas un nom : l'écrire n'apprendrait rien et consommerait la
      // tentative, donc on traite ce cas comme un échec de lecture.
      return null;
    }

    return DiscordBotIdentity(
      id: (body['id'] ?? '').toString().trim(),
      username: username,
      avatarHash: (body['avatar'] ?? '').toString().trim(),
      discriminator: (body['discriminator'] ?? '').toString().trim(),
      globalName: (body['global_name'] ?? '').toString().trim(),
      bannerHash: (body['banner'] ?? '').toString().trim(),
      accentColor: body['accent_color'] is int
          ? body['accent_color'] as int
          : null,
    );
  } on TimeoutException {
    developer.log('Discord identity request timed out.', name: 'BotIdentitySync');
    return null;
  } catch (error) {
    // Jamais `error.toString()` seul : il peut recopier l'URL, donc rien de la credential,
    // mais on reste sobre — le détail sert au diagnostic, pas la valeur du jeton.
    developer.log('Discord identity request failed: $error', name: 'BotIdentitySync');
    return null;
  } finally {
    if (ownsClient) client.close();
  }
}

/// Récupère le nom réel du bot [botId] auprès de Discord et l'écrit, quand — et seulement
/// quand — le nom local ne peut pas être un nom (vide ou égal à l'ID).
///
/// [token] : jeton à utiliser. Omis ou vide, on prend celui de la fiche locale — c'est le
/// cas de la synchro, qui n'a jamais le jeton en main (le manager le rédige). Pour un bot
/// HÉBERGÉ, cette fiche n'en a aucun : c'est le balayage (`bot_identity_scan.dart`) qui le
/// reprend par la route dédiée avant d'appeler ici.
///
/// Rend une issue, jamais une exception : l'appelant peut journaliser sans risquer l'écran.
Future<BotIdentitySyncOutcome> refreshBotIdentityFromDiscord({
  required String botId,
  String? token,
  http.Client? httpClient,
}) async {
  final trimmedBotId = botId.trim();
  if (trimmedBotId.isEmpty) return BotIdentitySyncOutcome.noToken;

  final manager = AppManager();
  final Map<String, dynamic> local;
  try {
    local = await manager.getApp(trimmedBotId);
  } catch (_) {
    return BotIdentitySyncOutcome.writeFailed;
  }

  // La condition est relue ICI, sur la fiche : un appelant ne peut pas déclencher la
  // requête pour un nom qui est déjà un nom, même par erreur.
  if (!botNameHidesIdentity(local['name']?.toString(), trimmedBotId)) {
    return BotIdentitySyncOutcome.notNeeded;
  }

  final providedToken = (token ?? '').trim();
  final effectiveToken = providedToken.isNotEmpty
      ? providedToken
      : (local['token'] ?? '').toString().trim();
  if (effectiveToken.isEmpty) return BotIdentitySyncOutcome.noToken;

  if (_attemptedBotIdentityFetches.contains(trimmedBotId)) {
    return BotIdentitySyncOutcome.alreadyAttempted;
  }
  // Réservé AVANT l'appel : deux déclenchements qui se chevauchent (une synchro et un
  // démarrage) ne peuvent pas produire deux appels.
  _attemptedBotIdentityFetches.add(trimmedBotId);

  final identity = await fetchDiscordBotIdentity(
    token: effectiveToken,
    httpClient: httpClient,
  );
  if (identity == null) return BotIdentitySyncOutcome.refused;
  // Le jeton doit être celui de CE bot : écrire le nom d'un autre sur cette fiche serait
  // pire que le symptôme qu'on répare.
  if (identity.id.isNotEmpty && identity.id != trimmedBotId) {
    developer.log(
      'Identity of bot $trimmedBotId came back for another bot: not written.',
      name: 'BotIdentitySync',
    );
    return BotIdentitySyncOutcome.refused;
  }

  final avatarHash = identity.avatarHash.trim();
  final hasAvatar = avatarHash.isNotEmpty;
  final guildCount = local['approximate_guild_count'];
  try {
    await manager.createOrUpdateApp(
      id: Snowflake.parse(trimmedBotId),
      username: identity.username,
      // Sans avatar chez Discord, on laisse les deux champs nuls : `createOrUpdateApp`
      // conserve alors l'avatar déjà connu au lieu de le remplacer par un avatar par défaut.
      avatarHash: hasAvatar ? avatarHash : null,
      discriminator: hasAvatar ? identity.discriminator : null,
      token: effectiveToken,
      prefix: local['prefix']?.toString(),
      intents: (local['intents'] as Map?)?.cast<String, bool>(),
      approximateGuildCount: guildCount is int ? guildCount : null,
    );
  } catch (error) {
    developer.log(
      'Failed to write the Discord identity of bot $trimmedBotId: $error',
      name: 'BotIdentitySync',
    );
    return BotIdentitySyncOutcome.writeFailed;
  }

  // Événement SANS jeton : l'identifiant obtenu par Discord et le nom écrit.
  developer.log(
    'Bot identity resolved: id=$trimmedBotId username=${identity.username}',
    name: 'BotIdentitySync',
  );
  return BotIdentitySyncOutcome.updated;
}

// Le BALAYAGE de tout le compte (`refreshBotIdentitiesFromDiscord`) vit dans
// `bot_identity_scan.dart` : c'est lui qui reprend au besoin le jeton d'un bot hébergé par
// la route dédiée avant d'appeler la fonction ci-dessus, faute de quoi il n'y a rien à
// présenter à Discord et le nom reste l'ID à l'écran.
