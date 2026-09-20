import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/utils/discord_invite.dart';
import 'package:bot_creator/core/utils/external_link.dart';

/// Issue d'une tentative d'invitation du bot d'un conteneur hébergé.
enum BotInviteOutcome {
  /// L'URL d'invitation a été ouverte : rien à dire à l'utilisateur.
  opened,

  /// Le serveur n'a pas su identifier le bot (`409 discord_identity_unavailable`) :
  /// son token est absent ou révoqué. Réessayer ne sert à rien — seul un
  /// redéploiement rend une identité exploitable.
  unavailable,

  /// Le serveur n'a pas répondu (réseau coupé, 5xx) : réessayer peut suffire.
  networkError,

  /// Le lien est prêt mais le navigateur n'a pas voulu l'ouvrir.
  openFailed,

  /// Une invitation était déjà en cours : le tap est ignoré (anti double clic).
  busy,
}

/// Parcours d'invitation du bot que fait tourner un conteneur clé en main.
///
/// L'utilisateur n'a rien à saisir : soit le conteneur connaît déjà son
/// application Discord (`discord_application_id`) et l'URL est ouverte
/// DIRECTEMENT, sans requête ; soit — conteneurs déployés avant cette
/// fonctionnalité — le serveur est seul à savoir quel bot tourne, et
/// `POST /containers/{id}/discord-identity` rend l'URL d'invitation à ouvrir.
class TurnkeyBotInviteService {
  TurnkeyBotInviteService({
    required MainApiClient? client,
    DiscordUrlOpener? openUrl,
    // Le champ reste privé : `this._client` est illégal en paramètre nommé,
    // donc une initialisation explicite est ici la seule écriture possible.
    // ignore: prefer_initializing_formals
  }) : _client = client,
       _openUrl = openUrl ?? openExternalUrl;

  /// Client du manager. `null` (compte non configuré) laisse intact le chemin
  /// direct : un conteneur dont l'application est connue s'invite quand même.
  final MainApiClient? _client;

  final DiscordUrlOpener _openUrl;

  bool _inviting = false;

  /// Vrai pendant une invitation : le bouton est verrouillé et tout second tap
  /// est ignoré, donc aucun second appel réseau.
  bool get inviting => _inviting;

  /// Ouvre l'invitation du bot de [container], en résolvant son identité par le
  /// serveur seulement quand le conteneur ne la connaît pas déjà.
  Future<BotInviteOutcome> invite(ContainerInfo container) async {
    // Garde de réentrance : c'est elle qui rend le double clic inoffensif, même
    // si deux gestes partent dans la même frame.
    if (_inviting) return BotInviteOutcome.busy;
    _inviting = true;
    try {
      final knownId = container.discordApplicationId ?? '';
      if (knownId.isNotEmpty) {
        return _open(
          discordInviteUri(knownId),
          containerId: container.id,
          botId: knownId,
        );
      }

      final client = _client;
      if (client == null) return BotInviteOutcome.networkError;

      final DiscordBotIdentity identity;
      try {
        identity = await client.fetchContainerDiscordIdentity(container.id);
      } on MainApiClientException catch (error) {
        return error.statusCode == 409
            ? BotInviteOutcome.unavailable
            : BotInviteOutcome.networkError;
      } catch (_) {
        // Panne réseau, réponse illisible : jamais de crash, un message.
        return BotInviteOutcome.networkError;
      }

      // L'URL vient du serveur ; à défaut, on la reconstruit depuis l'ID du bot
      // plutôt que d'abandonner avec un identifiant sous la main.
      final rawUrl = identity.inviteUrl.isNotEmpty
          ? identity.inviteUrl
          : buildDiscordInviteUrl(identity.botId);
      if (rawUrl.isEmpty) return BotInviteOutcome.unavailable;
      return _open(
        Uri.tryParse(rawUrl),
        containerId: container.id,
        botId: identity.botId,
      );
    } finally {
      _inviting = false;
    }
  }

  /// Ouvre [uri] et journalise l'invitation, comme le fait le chemin des bots
  /// locaux (`invite_bot`), une fois le lien réellement remis au navigateur.
  Future<BotInviteOutcome> _open(
    Uri? uri, {
    required String containerId,
    required String botId,
  }) async {
    if (uri == null) return BotInviteOutcome.unavailable;
    final opened = await _openUrl(uri);
    if (!opened) return BotInviteOutcome.openFailed;
    await AppAnalytics.logEvent(
      name: 'invite_bot',
      parameters: <String, Object>{
        'bot_id': botId,
        'container_id': containerId,
        'source': 'turnkey_container',
      },
    );
    return BotInviteOutcome.opened;
  }
}

/// Message à montrer pour [outcome], ou chaîne vide quand il n'y a rien à dire
/// (invitation ouverte, ou tap ignoré pendant une invitation en cours).
///
/// Toute issue d'échec a donc un texte : c'est ce qui interdit un dialogue vide
/// ou un échec silencieux devant un bouton qui ne réagit pas.
String botInviteOutcomeMessage(BotInviteOutcome outcome, AppLocalizations tr) {
  switch (outcome) {
    case BotInviteOutcome.unavailable:
      return tr.container_invite_unavailable;
    case BotInviteOutcome.networkError:
      return tr.container_invite_failed;
    case BotInviteOutcome.openFailed:
      return tr.container_invite_open_failed;
    case BotInviteOutcome.opened:
    case BotInviteOutcome.busy:
      return '';
  }
}
