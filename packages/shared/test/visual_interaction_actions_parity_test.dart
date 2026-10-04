import 'dart:convert';

import 'package:bot_creator_shared/engine/bdfd/visual/action_translator.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

import 'helpers/visual_message_gateway.dart';
import 'helpers/visual_parity_harness.dart' show visualAction;

/// Parity of the interaction blocks (wave 3, lot c) between the historical
/// executors and `bc_<type>` on the native engine: deferInteraction,
/// respondWithMessage and editInteractionMessage, over a recording
/// interaction, plus the host-script draft and the auto-defer facts the
/// workflow executor derives from the translator.

Action _a(
  BotCreatorActionType type,
  Map<String, dynamic> payload, {
  String? key,
  Map<String, String> error = const {},
}) => visualAction(type, key: key, payload: payload, error: error);

const _defer = BotCreatorActionType.deferInteraction;
const _respond = BotCreatorActionType.respondWithMessage;
const _editResponse = BotCreatorActionType.editInteractionMessage;

final _embed = {
  'title': 'Hello ((name))',
  'description': 'Body',
  'fields': [
    {'name': 'a', 'value': '((name))'},
  ],
};

final _buttons = {
  'components': [
    {
      'type': 'actionRow',
      'components': [
        {'type': 'button', 'label': 'Go', 'style': 'primary', 'customId': 'go'},
      ],
    },
  ],
};

Future<MessageOutcome> _parity(
  List<Action> actions, {
  bool acknowledged = false,
  Map<String, String>? variables,
  bool interaction = true,
  Snowflake? fallbackChannelId,
  int? nativePrograms,
  bool failAcknowledge = false,
  bool throwOnError = false,
}) => messageParity(
  actions,
  makeInteraction: interaction
      ? () =>
            FakeInteraction(acknowledged: acknowledged)
              ..failAcknowledge = failAcknowledge
      : null,
  variables: variables,
  fallbackChannelId: fallbackChannelId,
  nativePrograms: nativePrograms,
  throwOnError: throwOnError,
);

void main() {
  group('deferInteraction parity', () {
    test('acknowledges immediately, ephemeral or not', () async {
      for (final ephemeral in [null, false, true, 'true', '((e))']) {
        final outcome = await _parity(
          [
            _a(_defer, {'ephemeral': ?ephemeral}, key: 'd'),
          ],
          variables: {'e': 'true'},
        );
        expect(outcome.results, {'d': 'deferred'});
        expect(outcome.variables['action.d.status'], 'deferred');
        expect(outcome.interaction!.calls.single['op'], 'acknowledge');
      }
    });

    test('ephemeral flag reaches the acknowledgement', () async {
      final outcome = await _parity(
        [
          _a(_defer, {'ephemeral': '((e))'}, key: 'd'),
        ],
        variables: {'e': 'true'},
      );
      expect(outcome.interaction!.calls.single['ephemeral'], isTrue);
    });

    test('without an interaction, or when it already answered', () async {
      final none = await _parity([
        _a(_defer, {}, key: 'd'),
      ], interaction: false);
      expect(none.results, {'d': 'skipped'});
      final failed = await _parity([
        _a(_defer, {}, key: 'd'),
      ], failAcknowledge: true);
      expect(failed.results, {'d': 'skipped'});
      expect(failed.variables['action.d.status'], 'skipped');
    });

    test('nested in a block it still acknowledges first', () async {
      await _parity(
        [
          _a(BotCreatorActionType.ifBlock, {
            'variable': 'x',
            'operator': 'equals',
            'value': '1',
            'thenActions': [
              _a(_defer, {'ephemeral': true}, key: 'd').toJson(),
            ],
          }, key: 'cond'),
          _a(_respond, {'content': 'done', 'ephemeral': true}, key: 'r'),
        ],
        variables: {'x': '1'},
        nativePrograms: 2,
      );
    });
  });

  group('respondWithMessage parity', () {
    test('first response, then edits the original / follows up', () async {
      final outcome = await _parity(
        [
          _a(_respond, {'content': 'one ((name))'}, key: 'a'),
          _a(_respond, {'content': 'two'}, key: 'b'),
          _a(_respond, {'content': 'three', 'ephemeral': true}, key: 'c'),
        ],
        variables: {'name': 'Ana'},
      );
      expect(outcome.interaction!.calls.map((c) => c['op']), [
        'respond',
        'fetchOriginal',
        'updateOriginal',
        'followup',
      ]);
      expect(outcome.variables['last.response.id'], isNotEmpty);
      expect(outcome.context.response.originalResponseCompleted, isTrue);
      expect(outcome.context.response.acknowledged, isTrue);
    });

    test('after a defer: edit original, or follow-up when ephemeral', () async {
      final outcome = await _parity([
        _a(_defer, {}, key: 'd'),
        _a(_respond, {'content': 'edit'}, key: 'a'),
        _a(_respond, {'content': 'hidden', 'ephemeral': true}, key: 'b'),
      ]);
      expect(outcome.interaction!.calls.map((c) => c['op']), [
        'acknowledge',
        'updateOriginal',
        'followup',
      ]);
      expect(outcome.results!['a'], isNot('responded'));
    });

    test('an already acknowledged interaction (auto-defer)', () async {
      final outcome = await _parity([
        _a(_respond, {'content': 'x'}, key: 'a'),
      ], acknowledged: true);
      expect(outcome.interaction!.calls.single['op'], 'updateOriginal');
    });

    test('embeds, legacy embed, components, allowed mentions', () async {
      await _parity(
        [
          _a(_respond, {
            'content': 'c',
            'embeds': [_embed],
            'components': _buttons,
            'allowedMentions': {'parse': <String>[]},
          }, key: 'a'),
          _a(_respond, {'embed': _embed}, key: 'b'),
        ],
        variables: {'name': 'Ana'},
      );
    });

    test('canvas attachments force a follow-up once acknowledged', () async {
      final outcome = await _parity(
        [
          _a(_respond, {'content': ''}, key: 'a'),
          _a(_respond, {'content': 'later'}, key: 'b'),
        ],
        acknowledged: true,
        variables: {
          'temp._canvasAttachment_card': base64Encode([1, 2, 3]),
        },
      );
      expect(outcome.interaction!.calls.first['op'], 'followup');
      expect(outcome.interaction!.calls.last['op'], 'updateOriginal');
    });

    test('empty responses are skipped; rich V2 components refused', () async {
      final skipped = await _parity([
        _a(_respond, {'content': ''}, key: 'a'),
      ]);
      expect(skipped.results, {'a': ''});
      expect(skipped.interaction!.calls, isEmpty);
      final rich = await _parity([
        _a(_respond, {
          'content': 'x',
          'components': {
            'components': [
              {'type': 'textDisplay', 'content': 'v2'},
            ],
          },
        }),
      ]);
      expect(rich.errorText, contains('supports only normal components'));
    });

    test('without an interaction: fallback channel and reply', () async {
      final outcome = await _parity(
        [
          _a(_respond, {'content': 'hi', 'replyToMessage': true}, key: 'a'),
        ],
        interaction: false,
        fallbackChannelId: Snowflake(30),
        variables: {'message.id': '41'},
      );
      expect(outcome.writes.single['channel'], '30');
      expect(outcome.variables['last.response.id'], '9000');
      final explicit = await _parity(
        [
          _a(_respond, {'channelId': '((c))', 'content': 'x'}, key: 'a'),
        ],
        interaction: false,
        variables: {'c': '35'},
      );
      expect(explicit.writes.single['channel'], '35');
      final nowhere = await _parity([
        _a(_respond, {'content': 'x'}),
      ], interaction: false);
      expect(nowhere.errorText, contains('No channelId available'));
    });

    test('empty fallback response keeps the host state untouched', () async {
      final outcome = await _parity(
        [
          _a(_respond, {'content': 'x'}),
        ],
        interaction: false,
        fallbackChannelId: Snowflake(30),
      );
      expect(outcome.context.response.acknowledged, isFalse);
    });

    test('a failure surfaces and applies the error mode', () async {
      final outcome = await _parity([
        _a(_respond, {'content': 'x', 'channelId': 'bad'}, error: {'mode': 'continue'}),
        _a(_respond, {'content': 'after', 'channelId': '30'}, key: 'after'),
      ], interaction: false);
      expect(outcome.error, isNull);
    });

    test('inside a loop, try/catch and with throwOnError', () async {
      await _parity([
        _a(BotCreatorActionType.forLoop, {
          'mode': 'simple',
          'iterations': '3',
          'bodyActions': [
            _a(_respond, {
              'content': 'i=((_loop.index))',
              'components': _buttons,
            }, key: 'r').toJson(),
          ],
        }, key: 'loop'),
      ], nativePrograms: 1);
      await _parity(
        [
          _a(BotCreatorActionType.ifBlock, {
            'tryCatch': true,
            'thenActions': [
              _a(_respond, {'content': 'x'}, key: 'r').toJson(),
            ],
            'elseActions': [
              _a(_respond, {
                'content': 'caught ((error.message))',
              }, key: 'c').toJson(),
            ],
          }, key: 'try'),
        ],
        interaction: false,
        fallbackChannelId: null,
      );
    });
  });

  group('editInteractionMessage parity', () {
    test('edits the response: content, embeds, components, clearing', () async {
      final outcome = await _parity(
        [
          _a(_editResponse, {'content': 'edited ((name))'}, key: 'a'),
          _a(_editResponse, {
            'embeds': [_embed],
            'components': _buttons,
          }, key: 'b'),
          _a(_editResponse, {
            'clearEmbeds': true,
            'clearComponents': true,
          }, key: 'c'),
        ],
        acknowledged: true,
        variables: {'name': 'Ana'},
      );
      expect(outcome.results!.keys, ['a', 'b', 'c']);
    });

    test('acknowledges first when the interaction was not answered', () async {
      await _parity([
        _a(_editResponse, {'content': 'x'}, key: 'a'),
      ]);
    });

    test('without an interaction the result carries the error text', () async {
      final outcome = await _parity([
        _a(_editResponse, {'content': 'x'}, key: 'a'),
      ], interaction: false);
      expect(outcome.results, {
        'a': 'Error: editInteractionMessage requires an interaction context',
      });
    });
  });

  group('host script draft', () {
    test('blocks send immediately and never touch the draft', () async {
      final draft = DraftSpy();
      final outcome = await runWithDraft(
        [
          _a(BotCreatorActionType.sendMessage, {
            'channelId': '30',
            'content': 'now',
          }, key: 's'),
          _a(_respond, {'content': 'resp'}, key: 'r'),
          _a(BotCreatorActionType.ifBlock, {
            'variable': 'x',
            'operator': 'equals',
            'value': '1',
            'thenActions': [
              _a(BotCreatorActionType.sendMessage, {
                'channelId': '30',
                'content': 'nested',
              }, key: 'n').toJson(),
            ],
          }, key: 'cond'),
        ],
        draft,
        makeInteraction: FakeInteraction.new,
        variables: {'x': '1'},
      );
      expect(outcome.error, isNull);
      expect(outcome.writes.map((w) => (w['payload'] as Map)['content']), [
        'now',
        'nested',
      ]);
      expect(draft.appended, isEmpty);
      expect(draft.flushes, 0);
      expect(draft.discards, 0);
      // The draft is still the context's output, ready for the host's flush.
      expect(outcome.context.output, same(draft));
    });

    test('a failing block leaves the draft in place too', () async {
      final draft = DraftSpy();
      final outcome = await runWithDraft([
        _a(BotCreatorActionType.sendMessage, {
          'channelId': '31',
          'content': 'x',
        }),
      ], draft);
      expect(outcome.error, isNotNull);
      expect(outcome.context.output, same(draft));
      expect(draft.flushes, 0);
    });
  });

  group('auto-defer facts of the translator', () {
    BdfdActionProgram translate(List<Action> actions) =>
        const ActionTranslator().translate(actions);

    test('plain messaging actions leave the auto-defer on', () {
      final program = translate([
        _a(BotCreatorActionType.sendMessage, {'content': 'x'}),
        _a(_respond, {'content': 'x'}),
      ]);
      expect(program.shouldAutoDefer, isTrue);
      expect(program.hasDefer, isFalse);
      expect(program.ephemeralHint, isFalse);
    });

    test('deferInteraction replaces the auto-defer', () {
      final program = translate([
        _a(_defer, {}),
        _a(_respond, {'content': 'x'}),
      ]);
      expect(program.hasDefer, isTrue);
      expect(program.shouldAutoDefer, isFalse);
    });

    test('an ephemeral respondWithMessage makes the auto-defer ephemeral', () {
      final program = translate([
        _a(_respond, {'content': 'x', 'ephemeral': true}),
      ]);
      expect(program.ephemeralHint, isTrue);
      expect(program.shouldAutoDefer, isTrue);
    });

    test('every wave-3 type is native, also inside blocks', () {
      const translator = ActionTranslator();
      for (final type in [
        BotCreatorActionType.sendMessage,
        BotCreatorActionType.editMessage,
        BotCreatorActionType.getMessage,
        BotCreatorActionType.deleteMessages,
        BotCreatorActionType.deleteTrigger,
        BotCreatorActionType.sendDm,
        BotCreatorActionType.pinMessage,
        BotCreatorActionType.unpinMessage,
        BotCreatorActionType.deferInteraction,
        BotCreatorActionType.respondWithMessage,
        BotCreatorActionType.editInteractionMessage,
        BotCreatorActionType.addReaction,
        BotCreatorActionType.removeReaction,
        BotCreatorActionType.clearAllReactions,
      ]) {
        expect(translator.supports(_a(type, {})), isTrue, reason: type.name);
        expect(
          translator.supports(
            _a(BotCreatorActionType.ifBlock, {
              'thenActions': [_a(type, {}).toJson()],
            }),
          ),
          isTrue,
          reason: 'ifBlock > ${type.name}',
        );
        expect(const ActionTranslator.none().supports(_a(type, {})), isFalse);
      }
    });
  });
}
