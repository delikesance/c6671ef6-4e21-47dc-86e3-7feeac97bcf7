import '../l10n/app_localizations.dart';
import '../utils/discord_invite.dart';
import '../utils/external_link.dart';
import 'hosted_containers_host.dart';
import 'hosted_models.dart';

/// Issue d'une tentative d'invitation du bot d'un conteneur hébergé.
enum BotInviteOutcome {
  /// L'URL d'invitation a été ouverte : rien à dire à l'utilisateur.
  opened,

  /// Le serveur n'a pas su identifier le bot (`409 discord_identity_unavailable`) :
  /// son token est absent ou révoqué. Réessayer ne sert à rien — seul un
  /// redéploiement rend une identité exploitable.
  unavailable,

  /// `404` de ROUTE ABSENTE (ou `501`) : ce serveur ne connaît pas encore la
  /// route qui rend l'identité du bot — un manager plus ancien que
  /// l'application. Rien à voir avec la connexion : il faut mettre le serveur à
  /// jour, et « vérifiez votre connexion » enverrait l'utilisateur chercher une
  /// panne inexistante (constaté sur dev).
  serverUnsupported,

  /// `404` AVEC code applicatif : le serveur a bel et bien répondu, il ne connaît
  /// pas ce conteneur pour ce compte (`{"error":"not_found"}`). Sa route existe
  /// donc — annoncer « vérifiez votre connexion » serait faux : ce qu'il faut,
  /// c'est recharger la liste des conteneurs.
  containerMissing,

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
    required HostedContainersHost? host,
    DiscordUrlOpener? openUrl,
    // Le champ reste privé : `this._host` est illégal en paramètre nommé,
    // donc une initialisation explicite est ici la seule écriture possible.
    // ignore: prefer_initializing_formals
  }) : _host = host,
       _openUrl = openUrl ?? openExternalUrl;

  /// Hôte (client du Manager). `null` (compte non configuré) laisse intact le
  /// chemin direct : un conteneur dont l'application est connue s'invite quand
  /// même.
  final HostedContainersHost? _host;

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

      final host = _host;
      if (host == null) return BotInviteOutcome.networkError;

      final DiscordBotIdentity identity;
      try {
        identity = await host.discordIdentity(container.id);
      } on HostedApiException catch (error) {
        return _classifyIdentityFailure(error);
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

  /// Traduit l'échec du serveur en issue visible.
  ///
  /// Le point qui coûte le plus cher à confondre : un `404` de ROUTE ABSENTE
  /// (manager plus ancien que l'application) n'est pas un problème de connexion.
  /// Quand la route n'existe pas, le routeur du manager rend sa page « 404 page
  /// not found » — le corps n'est pas du JSON, donc le client ne dispose que du
  /// libellé HTTP (« Not Found ») et aucun code applicatif n'arrive jusqu'ici.
  /// Un `409` reste, lui, la réponse MÉTIER du serveur : il connaît ce bot et ne
  /// sait pas l'identifier.
  BotInviteOutcome _classifyIdentityFailure(HostedApiException error) {
    final status = error.statusCode;
    if (status == 409) return BotInviteOutcome.unavailable;
    if (status == 501) return BotInviteOutcome.serverUnsupported;
    if (status == 404) {
      return _carriesApplicationCode(error.message)
          ? BotInviteOutcome.containerMissing
          : BotInviteOutcome.serverUnsupported;
    }
    return BotInviteOutcome.networkError;
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
    await _host?.logBotInvited(botId: botId, containerId: containerId);
    return BotInviteOutcome.opened;
  }
}

/// Vrai quand le message d'erreur portait un CODE APPLICATIF (`snake_case`,
/// tel `container_not_found`), c'est-à-dire une réponse MÉTIER du serveur.
///
/// Faux pour un libellé HTTP nu (« Not Found », « Unknown error ») : c'est le
/// signe que le corps n'était pas du JSON, donc que la route n'existe pas sur ce
/// serveur. C'est cette distinction, et elle seule, qui décide entre « mets ton
/// serveur à jour » et « vérifie ta connexion ».
bool _carriesApplicationCode(String message) =>
    RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(message.trim());

/// Message à montrer pour [outcome], ou chaîne vide quand il n'y a rien à dire
/// (invitation ouverte, ou tap ignoré pendant une invitation en cours).
///
/// Toute issue d'échec a donc un texte : c'est ce qui interdit un dialogue vide
/// ou un échec silencieux devant un bouton qui ne réagit pas.
String botInviteOutcomeMessage(BotInviteOutcome outcome, AppLocalizations tr) {
  switch (outcome) {
    case BotInviteOutcome.unavailable:
      return tr.container_invite_unavailable;
    case BotInviteOutcome.serverUnsupported:
      return tr.container_invite_server_unsupported;
    case BotInviteOutcome.containerMissing:
      return tr.container_invite_missing;
    case BotInviteOutcome.networkError:
      return tr.container_invite_failed;
    case BotInviteOutcome.openFailed:
      return tr.container_invite_open_failed;
    case BotInviteOutcome.opened:
    case BotInviteOutcome.busy:
      return '';
  }
}
