import 'package:bot_creator_studio/src/api/studio_api.dart';
import 'package:bot_creator_studio/src/commands/action_list.dart';
import 'package:bot_creator_studio/src/commands/command_draft.dart';
import 'package:bot_creator_studio/src/commands/workflow_draft.dart';
import 'package:bot_creator_studio/src/widgets/actions_editor.dart';
import 'package:bot_creator_studio/src/widgets/options_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  optionsTests();
  group('CommandDraft', () {
    test('une commande neuve est à enregistrer et valide', () {
      final d = CommandDraft.blank(name: 'ping', description: 'Répond pong');
      expect(d.dirty, isTrue, reason: 'le serveur ne la connaît pas encore');
      expect(d.validate(), isNull);
      expect(d.id, matches(RegExp(r'^[0-9a-f-]{36}$')));
      final raw = d.toRaw();
      expect(raw['data']['executionMode'], 'workflow');
      expect(raw['data']['actions'], isEmpty);
    });

    test('nom invalide refusé', () {
      expect(
        CommandDraft.blank(name: 'Mon Ping', description: 'x').validate(),
        isNotNull,
      );
      expect(
        CommandDraft.blank(name: 'ping', description: '').validate(),
        isNotNull,
      );
    });

    test('ajout, remplacement, ordre et suppression de blocs', () {
      final d = CommandDraft.blank(name: 'ping', description: 'x');
      d.addAction(newAction('sendMessage'));
      d.addAction(newAction('addReaction'));
      expect(d.actions.map((a) => a['type']), ['sendMessage', 'addReaction']);
      expect(d.actions.first['payload'], {'content': ''});
      d.replaceAction(0, {
        ...d.actions.first,
        'payload': {'content': 'pong'},
      });
      d.moveAction(0, 1);
      expect(d.actions.last['payload'], {'content': 'pong'});
      d.toggleAction(0);
      expect(d.actions.first['enabled'], isFalse);
      d.removeAction(0);
      expect(d.actions, hasLength(1));
    });

    test('les champs inconnus sont conservés', () {
      final d = CommandDraft({
        'id': 'c1',
        'name': 'ping',
        'description': 'x',
        'discord_id': '123',
        'data': {'actions': [], 'secretField': 1},
      }, revision: 'r1');
      d.addAction(newAction('sendMessage'));
      final raw = d.toRaw();
      expect(raw['discord_id'], '123');
      expect(raw['data']['secretField'], 1);
    });
  });

  group('WorkflowDraft', () {
    test('un workflow événementiel porte son déclencheur', () {
      final w = WorkflowDraft.blank(name: 'bienvenue', type: 'event');
      expect(w.dirty, isTrue);
      expect(w.validate(), isNull);
      expect(w.eventTrigger['event'], 'messageCreate');
      w.addAction(newAction('sendMessage'));
      expect(w.toRaw()['actions'], hasLength(1));
      expect(w.toRaw()['entryPoint'], 'main');
    });

    test('nom requis, 80 blocs au plus', () {
      expect(WorkflowDraft.blank(name: ' ').validate(), isNotNull);
      final w = WorkflowDraft.blank(name: 'x');
      for (var i = 0; i < 81; i++) {
        w.addAction(newAction('sendMessage'));
      }
      expect(w.validate(), isNotNull);
    });

    test(
      'un workflow existant n\'est pas modifié tant qu\'on n\'y touche pas',
      () {
        final w = WorkflowDraft({
          'name': 'w',
          'actions': [],
          'arguments': [
            {'name': 'a'},
          ],
        });
        expect(w.dirty, isFalse);
        expect(w.toRaw()['arguments'], hasLength(1));
      },
    );
  });

  test('parseParamValue garde les types', () {
    expect(parseParamValue('true'), true);
    expect(parseParamValue('12', asNumber: true), 12);
    expect(parseParamValue('abc', asNumber: true), 'abc');
    expect(parseParamValue('x', asBool: false), false);
    expect(parseParamValue('hello'), 'hello');
  });

  test('flux SSE : événements, identifiants et charges utiles', () {
    final events = StudioApi.parseSse(
      'id: 1\nevent: delta\ndata: {"text":"Bon"}\n\n'
      'id: 2\nevent: delta\ndata: {"text":"jour"}\n\n'
      'id: 3\nevent: completed\ndata: {}\n\n',
    );
    expect(events.map((e) => e.kind), ['delta', 'delta', 'completed']);
    expect(events.map((e) => e.id), [1, 2, 3]);
    expect(events.take(2).map((e) => e.payload['text']).join(), 'Bonjour');
  });
}

void optionsTests() {
  group('options de commande', () {
    test('options valides', () {
      expect(
        validateOptions([
          {
            'type': 'user',
            'name': 'cible',
            'description': 'Qui',
            'required': true,
          },
          {'type': 'string', 'name': 'raison', 'description': 'Pourquoi'},
        ]),
        isNull,
      );
    });
    test('nom invalide, doublon, ordre et description', () {
      expect(
        validateOptions([
          {'name': 'Cible', 'description': 'x'},
        ]),
        isNotNull,
      );
      expect(
        validateOptions([
          {'name': 'a', 'description': 'x'},
          {'name': 'a', 'description': 'y'},
        ]),
        isNotNull,
      );
      expect(
        validateOptions([
          {'name': 'a', 'description': 'x'},
          {'name': 'b', 'description': 'y', 'required': true},
        ]),
        contains('obligatoires'),
      );
      expect(
        validateOptions([
          {'name': 'a', 'description': ''},
        ]),
        isNotNull,
      );
    });
    test(
      'les options sont écrites dans data.options sans toucher au reste',
      () {
        final d = CommandDraft({
          'id': 'c',
          'name': 'ban',
          'description': 'x',
          'data': {'actions': [], 'keep': 1},
        });
        d.options = [
          {
            'type': 'user',
            'name': 'cible',
            'description': 'Qui',
            'required': true,
          },
        ];
        expect(d.optionCount, 1);
        expect(d.toRaw()['data']['keep'], 1);
        expect(d.dirty, isTrue);
      },
    );
  });
}
