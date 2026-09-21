// Ce test verrouille la DÉCISION qui dit OÙ le bot a réellement démarré, et la phrase
// exacte que l'utilisateur lira dans la console de `flutter run`.
//
// Contexte : l'utilisateur choisit « Démarrer sur Bot Creator Server » et constate un
// démarrage local. Pour trancher, il faut deux états lus APRÈS coup — l'état local et
// l'état du serveur (`GET /gateway/bots` : `desired_state` / `runtime_state`) — et une
// issue NOMMÉE. Deux réalités différentes ne peuvent pas partager une phrase, sinon le
// diagnostic est faux : c'est exactement ce que ces cas verrouillent.
//
// Aucun réseau, aucun transport : la fonction testée est celle que le contrôle de
// production emprunte (`formatBotStartRealityLog` -> `resolveBotStartOutcome`), pas une
// copie.
import 'package:bot_creator/features/home/logic/bot_start_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

/// Entrée telle que `GET /gateway/bots` la rend pour un bot du compte.
Map<String, dynamic> _entree({
  String desired = 'STOPPED',
  String runtime = 'stopped',
}) => <String, dynamic>{
  'bot_id': 'bot-1',
  'desired_state': desired,
  'runtime_state': runtime,
};

void main() {
  group('où le bot a réellement démarré', () {
    test('seul le local tourne -> demarre sur ce poste', () {
      expect(
        resolveBotStartOutcome(localRunning: true, serverRunning: false),
        BotStartOutcome.onThisMachine,
      );
      expect(
        describeBotStartOutcome(BotStartOutcome.onThisMachine),
        'demarre sur ce poste',
      );
    });

    test('seul le serveur tourne -> demarre sur les serveurs Bot Creator', () {
      expect(
        resolveBotStartOutcome(localRunning: false, serverRunning: true),
        BotStartOutcome.onServers,
      );
      expect(
        describeBotStartOutcome(BotStartOutcome.onServers),
        'demarre sur les serveurs Bot Creator',
      );
    });

    test('ni l\'un ni l\'autre -> demarre nulle part (echec)', () {
      expect(
        resolveBotStartOutcome(localRunning: false, serverRunning: false),
        BotStartOutcome.nowhere,
      );
      expect(
        describeBotStartOutcome(BotStartOutcome.nowhere),
        'demarre nulle part (echec)',
      );
    });

    test('les deux tournent -> les deux sont nommés', () {
      expect(
        resolveBotStartOutcome(localRunning: true, serverRunning: true),
        BotStartOutcome.onBoth,
      );
      expect(
        describeBotStartOutcome(BotStartOutcome.onBoth),
        'demarre sur ce poste ET sur les serveurs Bot Creator',
      );
    });

    test('les quatre issues portent quatre phrases distinctes', () {
      final phrases = BotStartOutcome.values.map(describeBotStartOutcome).toSet();
      expect(phrases.length, BotStartOutcome.values.length);
    });

    test('etat serveur illisible -> issue indecidable, pas un echec annonce', () {
      expect(
        resolveBotStartOutcome(localRunning: false, serverRunning: null),
        BotStartOutcome.serverStateUnreadable,
      );
    });
  });

  group('etat serveur lu depuis GET /gateway/bots', () {
    test('runtime running -> le serveur l\'execute', () {
      expect(
        serverBotIsRunning(_entree(desired: 'RUNNING', runtime: 'running')),
        isTrue,
      );
    });

    test('desire RUNNING mais runtime stopped -> le serveur ne l\'execute pas', () {
      expect(
        serverBotIsRunning(_entree(desired: 'RUNNING', runtime: 'stopped')),
        isFalse,
      );
    });

    test('bot absent de la liste du compte -> pas execute cote serveur', () {
      expect(serverBotIsRunning(null), isFalse);
    });
  });

  group('la ligne de journal', () {
    test('serveur seul : les deux etats et l\'issue, sans ambiguite', () {
      expect(
        formatBotStartRealityLog(
          moment: '+10s',
          localRunning: false,
          serverRunning: true,
          serverBotEntry: _entree(desired: 'RUNNING', runtime: 'running'),
        ),
        '+10s : LOCAL=arrete SERVEUR=desired=RUNNING runtime=running '
        '-> demarre sur les serveurs Bot Creator',
      );
    });

    test('local seul : le poste est nomme', () {
      expect(
        formatBotStartRealityLog(
          moment: '+5s',
          localRunning: true,
          serverRunning: false,
          serverBotEntry: _entree(),
        ),
        '+5s : LOCAL=enMarche SERVEUR=desired=STOPPED runtime=stopped '
        '-> demarre sur ce poste',
      );
    });

    test('les deux sources ne sont jamais repliees sur un seul mot', () {
      expect(
        formatBotStartRealityLog(
          moment: '+5s',
          localRunning: true,
          serverRunning: true,
          serverBotEntry: _entree(desired: 'RUNNING', runtime: 'running'),
        ),
        contains('-> demarre sur ce poste ET sur les serveurs Bot Creator'),
      );
      expect(
        formatBotStartRealityLog(
          moment: '+5s',
          localRunning: false,
          serverRunning: false,
          serverBotEntry: _entree(),
        ),
        contains('-> demarre nulle part (echec)'),
      );
    });

    test('etat serveur non lu : la ligne le DIT au lieu de deviner', () {
      expect(
        formatBotStartRealityLog(
          moment: '+10s',
          localRunning: false,
          serverRunning: null,
        ),
        contains('SERVEUR=inconnu (etat non lu)'),
      );
    });

    test('la ligne ne recopie jamais un jeton de bot', () {
      final ligne = formatBotStartRealityLog(
        moment: '+10s',
        localRunning: false,
        serverRunning: true,
        serverBotEntry: <String, dynamic>{
          'bot_id': 'bot-1',
          'bot_token': 'jeton-qui-ne-doit-jamais-sortir',
          'desired_state': 'RUNNING',
          'runtime_state': 'running',
        },
      );
      expect(ligne.contains('jeton-qui-ne-doit-jamais-sortir'), isFalse);
    });
  });
}
