// L'invitation d'un bot clé en main a DEUX chemins, et le bon doit être choisi :
//   * le conteneur connaît déjà son identité (`discord_application_id`) → le lien
//     est ouvert DIRECTEMENT, sans un seul appel réseau ;
//   * sinon (conteneurs déployés avant cette fonctionnalité) → le manager résout
//     l'identité (`POST /containers/{id}/discord-identity`) et c'est SON
//     `invite_url` qui est ouverte, pas une URL recomposée localement.
//
// Un `MockClient` compte les requêtes : c'est la mesure qui distingue vraiment
// les deux chemins.
import 'package:bot_creator/core/utils/discord_invite.dart';
import 'package:bot_creator/features/containers/logic/turnkey_bot_invite.dart';
import 'package:flutter_test/flutter_test.dart';

import 'turnkey_bot_invite_test_support.dart';

const String _containerId = '95d85ac8-bd42-41c6-9392-3a1f0c9b7d21';
const String _knownAppId = '123456789012345678';
const String _resolvedBotId = '424242424242424242';
const String _serverInviteUrl =
    'https://discord.com/api/oauth2/authorize'
    '?client_id=$_resolvedBotId'
    '&scope=bot+applications.commands'
    '&permissions=8';

void main() {
  test('identifiant déjà connu : le lien est ouvert sans AUCUNE requête', () async {
    final manager = FakeMainApiManager();
    final opened = <Uri>[];
    final analytics = AnalyticsRecorder()..install();
    addTearDown(analytics.uninstall);

    final outcome = await TurnkeyBotInviteService(
      client: manager.client(),
      openUrl: recordingOpener(opened),
    ).invite(turnkeyContainer(discordApplicationId: _knownAppId));

    expect(outcome, BotInviteOutcome.opened);
    expect(opened, hasLength(1));
    // L'URL est celle du bot du conteneur, avec les scopes d'invitation.
    expect(opened.single, discordInviteUri(_knownAppId));
    expect(opened.single.toString(), contains('client_id=$_knownAppId'));
    expect(opened.single.query, contains('applications.commands'));

    // Le cœur du test : aucun aller-retour serveur sur ce chemin.
    expect(manager.requests, 0);
    expect(manager.calls, isEmpty);

    // L'invitation est journalisée, une fois le lien remis au navigateur.
    expect(analytics.names, <String>['invite_bot']);
    expect(analytics.parameters.single?['source'], 'turnkey_container');
    expect(analytics.parameters.single?['bot_id'], _knownAppId);
    expect(analytics.parameters.single?['container_id'], _containerId);
  });

  test(
    'identifiant inconnu : un seul POST discord-identity, puis l\'invite_url du serveur est ouverte',
    () async {
      final manager = FakeMainApiManager(
        body: <String, dynamic>{
          'bot_id': _resolvedBotId,
          'username': 'BeatDock',
          'avatar': '',
          'invite_url': _serverInviteUrl,
        },
      );
      final opened = <Uri>[];

      final outcome = await TurnkeyBotInviteService(
        client: manager.client(),
        openUrl: recordingOpener(opened),
      ).invite(turnkeyContainer(id: _containerId));

      expect(outcome, BotInviteOutcome.opened);
      expect(manager.requests, 1);
      expect(manager.calls, <String>[
        'POST /containers/$_containerId/discord-identity',
      ]);
      // C'est bien l'URL du SERVEUR qui est ouverte, pas une autre.
      expect(opened, hasLength(1));
      expect(opened.single.toString(), _serverInviteUrl);
    },
  );

  test(
    'serveur sans invite_url : l\'URL est recomposée depuis l\'identifiant rendu',
    () async {
      final manager = FakeMainApiManager(
        body: <String, dynamic>{'bot_id': _resolvedBotId},
      );
      final opened = <Uri>[];

      final outcome = await TurnkeyBotInviteService(
        client: manager.client(),
        openUrl: recordingOpener(opened),
      ).invite(turnkeyContainer(id: _containerId));

      expect(outcome, BotInviteOutcome.opened);
      expect(manager.requests, 1);
      expect(opened, hasLength(1));
      expect(opened.single, discordInviteUri(_resolvedBotId));
    },
  );
}
