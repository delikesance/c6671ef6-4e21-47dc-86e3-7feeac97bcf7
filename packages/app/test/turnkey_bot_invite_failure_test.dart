// Les ÉCHECS d'invitation doivent tous être visibles et nommés — jamais un lien
// ouvert à tort, jamais un crash, jamais un tap sans réponse :
//   * `409 discord_identity_unavailable` → « relancez un déploiement » ;
//   * 500 / réseau → « réessayez » ;
//   * navigateur qui refuse → « impossible d'ouvrir le lien » ;
//   * second tap pendant une invitation → ignoré (`busy`), sans requête ajoutée.
import 'package:bot_creator/features/containers/logic/turnkey_bot_invite.dart';
import 'package:flutter_test/flutter_test.dart';

import 'turnkey_bot_invite_test_support.dart';

const String _containerId = '95d85ac8-bd42-41c6-9392-3a1f0c9b7d21';

void main() {
  test(
    '409 discord_identity_unavailable : résultat unavailable, aucun lien ouvert, message dédié',
    () async {
      final manager = FakeMainApiManager(
        baseUrl: 'https://manager-conflict.test',
        statusCode: 409,
        body: <String, dynamic>{'error': 'discord_identity_unavailable'},
      );
      final opened = <Uri>[];

      final outcome = await TurnkeyBotInviteService(
        client: manager.client(),
        openUrl: recordingOpener(opened),
      ).invite(turnkeyContainer(id: _containerId));

      expect(outcome, BotInviteOutcome.unavailable);
      expect(manager.requests, 1, reason: 'un 409 est définitif : aucun réessai');
      expect(opened, isEmpty, reason: 'l\'échec ne doit jamais ouvrir un lien');

      // Le texte attendu est celui de la CLÉ i18n, lu dans l'ARB français.
      expect(
        botInviteOutcomeMessage(outcome, tr),
        arbFrText('container_invite_unavailable'),
      );
      expect(arbFrText('container_invite_unavailable'), isNotEmpty);
    },
  );

  test('500 : résultat networkError, aucun lien ouvert', () async {
    final manager = FakeMainApiManager(
      baseUrl: 'https://manager-server-error.test',
      statusCode: 500,
      body: <String, dynamic>{'error': 'boom'},
    );
    final opened = <Uri>[];

    final outcome = await TurnkeyBotInviteService(
      client: manager.client(),
      openUrl: recordingOpener(opened),
    ).invite(turnkeyContainer(id: _containerId));

    expect(outcome, BotInviteOutcome.networkError);
    expect(opened, isEmpty);
    expect(
      botInviteOutcomeMessage(outcome, tr),
      arbFrText('container_invite_failed'),
    );
  });

  test('panne réseau : résultat networkError, aucun lien ouvert', () async {
    final manager = FakeMainApiManager(
      baseUrl: 'https://manager-network-down.test',
      networkFailure: true,
    );
    final opened = <Uri>[];

    final outcome = await TurnkeyBotInviteService(
      client: manager.client(),
      openUrl: recordingOpener(opened),
    ).invite(turnkeyContainer(id: _containerId));

    expect(outcome, BotInviteOutcome.networkError);
    expect(opened, isEmpty);
  });

  test(
    'double clic : le second appel rend busy et n\'ajoute AUCUNE requête',
    () async {
      final manager = FakeMainApiManager(
        baseUrl: 'https://manager-double-click.test',
        body: <String, dynamic>{
          'bot_id': '424242424242424242',
          'invite_url':
              'https://discord.com/api/oauth2/authorize'
              '?client_id=424242424242424242'
              '&scope=bot+applications.commands&permissions=8',
        },
        delay: const Duration(milliseconds: 40),
      );
      final opened = <Uri>[];
      final service = TurnkeyBotInviteService(
        client: manager.client(),
        openUrl: recordingOpener(opened),
      );

      // Premier tap : la requête part et reste en vol (le faux manager répond
      // après un délai), donc le second tap tombe PENDANT la première invitation.
      final first = service.invite(turnkeyContainer(id: _containerId));
      final second = await service.invite(
        turnkeyContainer(id: _containerId),
      );
      expect(second, BotInviteOutcome.busy);

      expect(await first, BotInviteOutcome.opened);
      expect(manager.requests, 1, reason: 'le second tap ne relance rien');
      expect(opened, hasLength(1));
    },
  );

  test('ouvreur qui renvoie false : résultat openFailed', () async {
    final manager = FakeMainApiManager(
      body: <String, dynamic>{
        'bot_id': '424242424242424242',
        'invite_url':
            'https://discord.com/api/oauth2/authorize'
            '?client_id=424242424242424242'
            '&scope=bot+applications.commands&permissions=8',
      },
    );
    final opened = <Uri>[];

    final outcome = await TurnkeyBotInviteService(
      client: manager.client(),
      openUrl: recordingOpener(opened, result: false),
    ).invite(turnkeyContainer(id: _containerId));

    expect(outcome, BotInviteOutcome.openFailed);
    // Le lien a bien été TENTÉ : l'échec vient du navigateur, pas du parcours.
    expect(opened, hasLength(1));
    expect(
      botInviteOutcomeMessage(outcome, tr),
      arbFrText('container_invite_open_failed'),
    );
  });
}
