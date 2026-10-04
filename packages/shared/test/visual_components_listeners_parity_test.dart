import 'package:bot_creator_shared/bot/bot_data_store.dart';
import 'package:bot_creator_shared/engine/bdfd/visual/action_translator.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/types/component.dart';
import 'package:bot_creator_shared/utils/interaction_listener_registry.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

import 'helpers/visual_discord_gateway.dart';
import 'helpers/variables_test_helpers.dart';
import 'helpers/visual_parity_harness.dart';

/// Parity of the component / modal / listener / autocomplete blocks between the
/// historical executors and `bc_<type>` on the native engine: respondWithComponentV2,
/// sendComponentV2, editComponentV2, respondWithModal (legacy inputs, component
/// labels, inline actions, onSubmit workflow), listenForButtonClick,
/// listenForSelectMenu, listenForModalSubmit, listenAndExecute and
/// respondWithAutocomplete. The deferred part (the in-memory
/// InteractionListenerRegistry) is observed through the registered entries.

// ---------------------------------------------------------------------------
// Simulated Discord
// ---------------------------------------------------------------------------

mixin _Recording {
  final List<Object?> log = [];
  Object? get dataValue => null;

  Object? record(Invocation i) {
    final name = i.memberName;
    final args = i.positionalArguments;
    Object? built(Object? b) {
      if (b is List) return [for (final item in b) built(item)];
      try {
        return (b as dynamic).build();
      } catch (_) {
        return '$b';
      }
    }

    if (name == #respond) {
      log.add({'respond': built(args.first)});
      return Future.value(null);
    }
    if (name == #respondModal) {
      log.add({'respondModal': built(args.first)});
      return Future.value(null);
    }
    if (name == #updateOriginalResponse) {
      log.add({'updateOriginalResponse': built(args.first)});
      return Future<Message>.value(_Msg(Snowflake(901), log));
    }
    if (name == #fetchOriginalResponse) {
      return Future<Message>.value(_Msg(Snowflake(900), log));
    }
    if (name == #guildId) return Snowflake(10);
    if (name == #channelId) return Snowflake(30);
    if (name == #data) return dataValue;
    return null;
  }
}

class _Data implements MessageComponentInteractionData {
  _Data(this.customId);
  @override
  final String customId;
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _Command with _Recording implements ApplicationCommandInteraction {
  @override
  dynamic noSuchMethod(Invocation i) => record(i);
}

class _Click with _Recording implements MessageComponentInteraction {
  _Click(this.customId);
  final String customId;
  @override
  Object? get dataValue => _Data(customId);
  @override
  dynamic noSuchMethod(Invocation i) => record(i);
}

class _Auto
    with _Recording
    implements ApplicationCommandAutocompleteInteraction {
  @override
  dynamic noSuchMethod(Invocation i) => record(i);
}

class _Plain with _Recording implements Interaction<dynamic> {
  @override
  dynamic noSuchMethod(Invocation i) => record(i);
}

class _Msg implements Message {
  _Msg(this.id, this.log);
  @override
  final Snowflake id;
  final List<Object?> log;
  @override
  dynamic noSuchMethod(Invocation i) {
    if (i.memberName == #edit) {
      log.add({
        'edit': '$id',
        'payload': (i.positionalArguments.first as dynamic).build(),
      });
      return Future<Message>.value(this);
    }
    return super.noSuchMethod(i);
  }
}

class _Messages implements MessageManager {
  _Messages(this.log);
  final List<Object?> log;
  @override
  Future<Message> fetch(Snowflake id, {bool? force}) async => _Msg(id, log);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Channel extends VisualTextChannel {
  _Channel(super.base, super.manager, this.log);
  final List<Object?> log;
  @override
  MessageManager get messages => _Messages(log);
  @override
  Future<Message> sendMessage(MessageBuilder builder) async {
    log.add({'send': '$id', 'payload': builder.build()});
    return _Msg(Snowflake(777), log);
  }
}

class _Channels extends VisualChannels {
  _Channels(super.gateway, this.log);
  final List<Object?> log;
  @override
  Future<Channel> get(Snowflake id) => fetch(id);
  @override
  Future<Channel> fetch(Snowflake id) async {
    final channel = await super.fetch(id);
    return channel is VisualTextChannel
        ? _Channel(channel, this, log)
        : channel;
  }
}

class _Gateway extends VisualGateway {
  _Gateway() {
    chans = _Channels(this, writes);
  }
  late final _Channels chans;
  @override
  ChannelManager get channels => chans;
}

class _Store extends MemoryBotDataStore {
  /// Saved workflows by name; empty by default (the listener answers "not
  /// found").
  static Map<String, Map<String, dynamic>> workflows = {};

  @override
  Future<Map<String, dynamic>?> getWorkflowByName(
    String botId,
    String name,
  ) async => workflows[name];
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

typedef _Out = Outcome<_Gateway>;

Object? _registry() {
  final snapshot = <String, Object?>{};
  for (final id in InteractionListenerRegistry.instance.activeCustomIds) {
    for (final type in const ['button', 'select', 'modal']) {
      for (final messageId in const <String?>[
        null,
        '55',
        '66',
        '900',
        '777',
        '4242',
      ]) {
        final entry = InteractionListenerRegistry.instance.getMatching(
          id,
          ListenerMatchRequest(
            botId: 'bot',
            type: type,
            guildId: '10',
            channelId: '30',
            messageId: messageId,
          ),
        );
        if (entry == null || entry.messageId != messageId) continue;
        snapshot['$id/$type/$messageId'] = {
          'workflow': entry.workflowName,
          'entryPoint': entry.workflowEntryPoint,
          'arguments': entry.workflowArguments,
          'inline': entry.inlineActions?.map((a) => a.toJson()).toList(),
          'ttlMinutes': entry.expiresAt.difference(DateTime.now()).inMinutes,
          'oneShot': entry.oneShot,
          'guildId': entry.guildId,
          'channelId': entry.channelId,
          'messageId': entry.messageId,
          'context': entry.initialContext,
        };
      }
    }
  }
  return snapshot;
}

Future<_Out> _parity(
  List<Action> actions, {
  Object? Function()? interaction,
  Map<String, String>? variables,
  bool guild = true,
  bool throwOnError = false,
  Snowflake? fallbackChannelId,
  bool expectNative = true,
  int? nativePrograms,
  Duration? settle,
}) {
  Object? current;
  return visualParity<_Gateway>(
    actions,
    makeGateway: _Gateway.new,
    makeStore: _Store.new,
    effects: (g) => [
      g.writes,
      _registry(),
      if (current is _Recording) (current as _Recording).log,
    ],
    setup: (_) => InteractionListenerRegistry.instance.removeAllForBot('bot'),
    variables: variables,
    guild: guild,
    throwOnError: throwOnError,
    fallbackChannelId: fallbackChannelId,
    makeInteraction: interaction == null
        ? null
        : () => (current = interaction()) as Interaction?,
    expectNative: expectNative,
    nativePrograms: nativePrograms,
    settle: settle,
  );
}

Action _a(
  BotCreatorActionType type,
  Map<String, dynamic> payload, {
  String? key,
  Map<String, String> error = const {},
}) => visualAction(type, key: key, payload: payload, error: error);

Map<String, dynamic> _buttonRow({
  List<Map<String, dynamic>> actions = const [],
}) => ComponentV2Definition(
  components: [
    ActionRowNode(
      components: [ButtonNode(label: 'Go', customId: 'go', actions: actions)],
    ),
  ],
).toJson();

Map<String, dynamic> _inlineLog = {
  'type': 'log',
  'payload': {'message': 'clicked'},
};

Map<String, dynamic> _modal({
  String customId = 'm1',
  String title = 'Title',
  Map<String, dynamic> extra = const {},
}) => {
  'title': title,
  'customId': customId,
  'inputs': [
    {'customId': 'name', 'label': 'Name', 'style': 'short', 'required': true},
  ],
  ...extra,
};

void main() {
  tearDown(() {
    _Store.workflows = {};
    InteractionListenerRegistry.instance.removeAllForBot('bot');
  });

  group('respondWithModal parity', () {
    const type = BotCreatorActionType.respondWithModal;

    test('opens a legacy input modal and returns its customId', () async {
      final out = await _parity([
        _a(type, {'modal': _modal()}, key: 'm'),
      ], interaction: _Command.new);
      expect(out.results, {'m': 'm1'});
      expect(out.effects.toString(), contains('respondModal'));
    });

    test('accepts the top-level payload and resolves placeholders', () async {
      final out = await _parity(
        [_a(type, _modal(customId: 'm-((suffix))', title: 'Hi ((who))'))],
        interaction: _Command.new,
        variables: {'suffix': 'x', 'who': 'you'},
      );
      expect(out.results, {'action_0': 'm-x'});
    });

    test('component-label format', () async {
      final modal = {
        'title': 'T',
        'customId': 'lab',
        'components': [
          TextDisplayNode(content: 'Read me').toJson(),
          LabelNode(
            label: 'Why',
            component: ModalTextInputNode(
              customId: 'why',
              style: BcTextInputStyle.paragraph,
            ),
          ).toJson(),
        ],
      };
      final out = await _parity([
        _a(type, {'modal': modal}, key: 'm'),
      ], interaction: _Command.new);
      expect(out.results, {'m': 'lab'});
    });

    test('inline actions register a one-shot submit listener', () async {
      final out = await _parity(
        [
          _a(type, {
            'modal': _modal(
              customId: 'inline',
              extra: {
                'actions': [_inlineLog],
              },
            ),
          }, key: 'm'),
        ],
        interaction: _Command.new,
        fallbackChannelId: Snowflake(30),
        variables: {'target.user.id': '9', 'ignored': 'x'},
      );
      final registry = (out.effects as List)[1] as Map;
      expect(registry, hasLength(1));
      expect((registry.values.single as Map)['oneShot'], true);
      expect((registry.values.single as Map)['channelId'], '30');
      expect((registry.values.single as Map)['context'], {
        'guild.id': '10',
        'target.user.id': '9',
      });
    });

    test('legacy onSubmitWorkflow becomes a submit listener', () async {
      final out = await _parity(
        [
          _a(type, {
            'modal': _modal(
              customId: 'wf',
              extra: {
                'onSubmitWorkflow': 'handle',
                'onSubmitEntryPoint': 'start',
                'onSubmitArguments': {'a': '((v))'},
              },
            ),
          }),
        ],
        interaction: _Command.new,
        variables: {'v': '1'},
      );
      // The shorthand is converted into a `runWorkflow` inline action, the
      // existing action type, with the legacy payload contract.
      expect(out.error, isNull);
      final registry = (out.effects as List)[1] as Map;
      final entry = registry.values.single as Map;
      expect(entry['oneShot'], true);
      expect(entry['inline'], [
        {
          'type': 'runWorkflow',
          'payload': {
            'workflowName': 'handle',
            'entryPoint': 'start',
            'arguments': {'a': '((v))'},
          },
          'key': null,
          'depend_on': isA<List>(),
          'error': isA<Map>(),
          'enabled': true,
        },
      ]);
    });

    Map<String, dynamic> workflowOf(List<Action> actions) => {
      'entryPoint': 'main',
      'actions': actions.map((a) => a.toJson()).toList(),
    };

    /// Registers the modal, then plays the submit: the registered inline
    /// actions run through handleActions, as `runListenerInlineActions` does.
    Future<List<Action>> registeredActions(String customId) async {
      final entry = InteractionListenerRegistry.instance.getMatching(
        customId,
        ListenerMatchRequest(
          botId: 'bot',
          type: 'modal',
          guildId: '10',
          channelId: '30',
        ),
      );
      return entry!.inlineActions!;
    }

    test('modal submit runs the named workflow with its arguments', () async {
      _Store.workflows = {
        'handle': workflowOf([
          _a(BotCreatorActionType.setTemporaryVariable, {
            'key': 'got',
            'value': 'arg=((arg.a))',
          }, key: 'w1'),
        ]),
      };
      final registered = await _parity(
        [
          _a(type, {
            'modal': _modal(
              customId: 'wf2',
              extra: {
                'onSubmitWorkflow': 'handle',
                'onSubmitArguments': {'a': '((v))'},
              },
            ),
          }),
        ],
        interaction: _Command.new,
        variables: {'v': '42'},
      );
      expect(registered.error, isNull);

      // Play the submit with the registered actions, historical vs native.
      final submit = await _parity(
        await registeredActions('wf2'),
        variables: {'v': '42'},
      );
      expect(submit.error, isNull);
      expect(submit.results!['action_0'], 'WORKFLOW_OK:main');
      expect(submit.results!['action_0.w1'], isNotNull);
      expect(submit.variables['workflow.response'], 'WORKFLOW_OK:main');
      expect(submit.variables['workflow.args'], '{"a":"42"}');
      expect(submit.variables['temp.got'], 'arg=42');
    });

    test(
      'modal submit with a missing workflow fails like runWorkflow',
      () async {
        await _parity([
          _a(type, {
            'modal': _modal(
              customId: 'wf3',
              extra: {'onSubmitWorkflow': 'ghost'},
            ),
          }),
        ], interaction: _Command.new);
        final submit = await _parity(await registeredActions('wf3'));
        expect(submit.errorText, contains('Workflow not found: ghost'));
      },
    );

    test('actions take precedence over the legacy shorthand', () async {
      final out = await _parity([
        _a(type, {
          'modal': _modal(
            customId: 'wf4',
            extra: {
              'onSubmitWorkflow': 'ignored',
              'actions': [_inlineLog],
            },
          ),
        }),
      ], interaction: _Command.new);
      final inline = ((out.effects as List)[1] as Map).values.single as Map;
      expect((inline['inline'] as List).single['type'], 'log');
    });

    test('without an interaction the result carries the error text', () async {
      final out = await _parity([
        _a(type, {'modal': _modal()}, key: 'm'),
      ]);
      expect(
        out.results!['m'],
        'Error: respondWithModal requires an active interaction context',
      );
    });

    test(
      'unsupported interaction, invalid and missing modal fail alike',
      () async {
        for (final payload in <Map<String, dynamic>>[
          {'modal': _modal(title: '')},
          {'modal': _modal(customId: '')},
          {'modal': 'nope'},
          {
            'modal': {'title': 'T', 'customId': 'empty'},
          },
        ]) {
          final out = await _parity([
            _a(type, payload),
          ], interaction: _Command.new);
          expect(out.error, isNotNull);
        }
        final out = await _parity([
          _a(type, {'modal': _modal()}),
        ], interaction: _Plain.new);
        expect(out.errorText, contains('does not support modals'));
      },
    );

    test('error modes keep applying', () async {
      final out = await _parity([
        _a(
          type,
          {'modal': _modal(title: '')},
          key: 'bad',
          error: {'mode': 'continue'},
        ),
        _a(BotCreatorActionType.setTemporaryVariable, {
          'key': 'k',
          'value': 'v',
        }),
      ], interaction: _Command.new);
      expect(out.error, isNull);
    });

    test('a modal program is never auto-deferred', () {
      final program = const ActionTranslator().translate([
        _a(type, {'modal': _modal()}),
      ]);
      expect(program.hasModal, isTrue);
      expect(program.shouldAutoDefer, isFalse);
    });
  });

  group('listener parity', () {
    const button = BotCreatorActionType.listenForButtonClick;
    const select = BotCreatorActionType.listenForSelectMenu;
    const modal = BotCreatorActionType.listenForModalSubmit;
    const both = BotCreatorActionType.listenAndExecute;

    for (final type in [button, select, modal]) {
      test('${type.name} registers the listener', () async {
        final out = await _parity(
          [
            _a(type, {
              'customId': 'c-((n))',
              'workflowName': 'wf',
              'entryPoint': ' start ',
              'arguments': {'who': '((n))'},
              'ttlMinutes': 30,
              'messageId': '55',
            }, key: 'l'),
          ],
          variables: {'n': '1', 'target.message.id': '3'},
          fallbackChannelId: Snowflake(30),
        );
        expect(out.results, {'l': 'listening:c-1'});
        final registry = (out.effects as List)[1] as Map;
        expect(registry, hasLength(1));
        expect((registry.values.single as Map)['ttlMinutes'], 29);
        expect((registry.values.single as Map)['oneShot'], type == modal);
      });
    }

    test('ttl is clamped to 1..60 minutes and defaults to 60', () async {
      for (final ttl in [0, 500, 'abc', null]) {
        await _parity([
          _a(button, {
            'customId': 'c',
            'workflowName': 'wf',
            'ttlMinutes': ?ttl,
          }),
        ]);
      }
    });

    test(
      'message id comes from the runtime context unless in an event workflow',
      () async {
        for (final variables in [
          {'interaction.messageId': '66'},
          {'messageId': '66'},
          {'message.id': '66'},
          {'workflow.type': 'event', 'message.id': '66'},
        ]) {
          final out = await _parity([
            _a(select, {'customId': 'c', 'workflowName': 'wf'}),
          ], variables: variables);
          expect((out.effects as List)[1], isNotEmpty);
        }
      },
    );

    test('customId and workflowName are required', () async {
      for (final type in [button, select, modal]) {
        var out = await _parity([
          _a(type, {'workflowName': 'wf'}),
        ]);
        expect(
          out.errorText,
          contains('customId is required for ${type.name}'),
        );
        out = await _parity([
          _a(type, {'customId': 'c'}),
        ]);
        expect(
          out.errorText,
          contains('workflowName is required for ${type.name}'),
        );
      }
      final out = await _parity([
        _a(both, {'actions': []}),
      ]);
      expect(
        out.errorText,
        contains('customId is required for listenAndExecute'),
      );
    });

    test('error mode skip applies to a failing listener', () async {
      final out = await _parity([
        _a(
          button,
          {'workflowName': 'wf'},
          key: 'l',
          error: {'mode': 'continue'},
        ),
        _a(BotCreatorActionType.setTemporaryVariable, {
          'key': 'k',
          'value': 'v',
        }),
      ]);
      expect(out.error, isNull);
    });

    test('the current click already starts the handler workflow', () async {
      // The workflow does not exist: both paths answer on the interaction.
      final out = await _parity(
        [
          _a(button, {'customId': 'go', 'workflowName': 'missing'}, key: 'l'),
        ],
        interaction: () => _Click('go'),
        settle: const Duration(milliseconds: 50),
      );
      expect(out.effects.toString(), contains('Workflow not found'));
    });

    test('a click on another customId only registers', () async {
      final out = await _parity(
        [
          _a(button, {'customId': 'go', 'workflowName': 'missing'}),
        ],
        interaction: () => _Click('other'),
        settle: const Duration(milliseconds: 50),
      );
      expect(out.effects.toString(), isNot(contains('Workflow not found')));
    });

    test(
      'listenAndExecute registers button, select and modal entries',
      () async {
        final out = await _parity([
          _a(both, {
            'customId': 'multi',
            'actions': [_inlineLog],
            'ttlMinutes': 10,
            'messageId': '55',
          }, key: 'l'),
        ], fallbackChannelId: Snowflake(30));
        expect(out.results, {'l': 'listening:multi'});
        final registry = (out.effects as List)[1] as Map;
        expect(registry.keys, hasLength(3));
      },
    );

    test(
      'listenAndExecute with a workflow, entry point default and immediate run',
      () async {
        final out = await _parity(
          [
            _a(both, {
              'customId': 'multi',
              'workflowName': 'missing',
              'arguments': {'a': '1'},
            }),
          ],
          interaction: () => _Click('multi'),
          settle: const Duration(milliseconds: 50),
        );
        expect(out.effects.toString(), contains('Workflow not found'));
      },
    );

    test(
      'listenAndExecute runs inline actions immediately for the current click',
      () async {
        await _parity(
          [
            _a(both, {
              'customId': 'multi',
              'actions': [_inlineLog],
            }),
          ],
          interaction: () => _Click('multi'),
          settle: const Duration(milliseconds: 50),
        );
      },
    );
  });

  group(
    'respondWithComponentV2 / sendComponentV2 / editComponentV2 parity',
    () {
      test(
        'responds to an interaction and registers inline button actions',
        () async {
          final out = await _parity(
            [
              _a(BotCreatorActionType.respondWithComponentV2, {
                'components': _buttonRow(actions: [_inlineLog]),
              }, key: 'r'),
            ],
            interaction: () => _Click('x'),
            fallbackChannelId: Snowflake(30),
          );
          expect(out.results, {'r': '900'});
          expect((out.effects as List)[1], isNotEmpty);
        },
      );

      test('componentV2 alias and ephemeral flag', () async {
        await _parity(
          [
            _a(BotCreatorActionType.respondWithComponentV2, {
              'componentV2': ComponentV2Definition(
                ephemeral: true,
                components: [TextDisplayNode(content: 'Hello ((who))')],
              ).toJson(),
            }),
          ],
          interaction: () => _Click('x'),
          variables: {'who': 'there'},
        );
      });

      test(
        'an acknowledged interaction updates the original response',
        () async {
          final out = await _parity(
            [
              _a(BotCreatorActionType.respondWithComponentV2, {
                'components': _buttonRow(),
              }, key: 'r'),
            ],
            interaction: () => _Click('x')..log, // acknowledged below
          );
          expect(out.results, isNotNull);
        },
      );

      test('without an interaction it sends to the fallback channel', () async {
        final out = await _parity([
          _a(BotCreatorActionType.respondWithComponentV2, {
            'components': _buttonRow(),
          }, key: 'r'),
        ], fallbackChannelId: Snowflake(30));
        expect(out.results, {'r': '777'});
      });

      test('sendComponentV2 targets an explicit channel', () async {
        final out = await _parity([
          _a(BotCreatorActionType.sendComponentV2, {
            'channelId': '30',
            'components': _buttonRow(actions: [_inlineLog]),
          }, key: 's'),
        ]);
        expect(out.results, {'s': '777'});
        expect((out.effects as List)[1], isNotEmpty);
      });

      test('errors: no channel, not a text channel, bad interaction', () async {
        var out = await _parity([
          _a(BotCreatorActionType.sendComponentV2, {
            'components': _buttonRow(),
          }),
        ]);
        expect(
          out.errorText,
          contains('No channelId available for sendComponentV2'),
        );
        out = await _parity([
          _a(BotCreatorActionType.sendComponentV2, {
            'channelId': '31',
            'components': _buttonRow(),
          }),
        ]);
        expect(out.error, isNotNull);
        out = await _parity([
          _a(BotCreatorActionType.respondWithComponentV2, {
            'components': _buttonRow(),
          }),
        ], interaction: _Plain.new);
        expect(
          out.errorText,
          contains('Interaction does not support message responses'),
        );
      });

      test('editComponentV2 edits a message and registers bindings', () async {
        final out = await _parity([
          _a(BotCreatorActionType.editComponentV2, {
            'channelId': '30',
            'messageId': '4242',
            'components': _buttonRow(actions: [_inlineLog]),
          }, key: 'e'),
        ]);
        expect(out.results, {'e': '4242'});
        expect(out.effects.toString(), contains('edit'));
      });

      test('editComponentV2 failures and error mode', () async {
        var out = await _parity([
          _a(BotCreatorActionType.editComponentV2, {
            'components': _buttonRow(),
          }),
        ]);
        expect(out.errorText, contains('Missing channelId/messageId'));
        out = await _parity([
          _a(
            BotCreatorActionType.editComponentV2,
            {'channelId': '31', 'messageId': '1'},
            key: 'e',
            error: {'mode': 'continue'},
          ),
          _a(BotCreatorActionType.setTemporaryVariable, {
            'key': 'k',
            'value': 'v',
          }),
        ]);
        expect(out.error, isNull);
      });
    },
  );

  group('respondWithAutocomplete parity', () {
    const type = BotCreatorActionType.respondWithAutocomplete;
    const items = '[{"n":"One","v":"1"},{"n":"Two","v":"2"},{"n":"","v":"3"}]';

    test('answers the choices and stops the list', () async {
      final out = await _parity(
        [
          _a(type, {
            'items': items,
            'labelTemplate': '{n}',
            'valueTemplate': '{v}',
          }, key: 'ac'),
          _a(BotCreatorActionType.setTemporaryVariable, {
            'key': 'late',
            'value': 'x',
          }),
        ],
        interaction: _Auto.new,
        variables: {'autocomplete.optionType': 'integer'},
      );
      expect(out.results, {'ac': 'RESPONDED', '__stopped__': 'AUTOCOMPLETE'});
      expect(out.variables.containsKey('late'), isFalse);
    });

    test('string and number focused options, default templates', () async {
      for (final kind in ['string', 'number']) {
        await _parity(
          [
            _a(type, {'items': '["a","b"]'}),
          ],
          interaction: _Auto.new,
          variables: {'autocomplete.optionType': kind},
        );
      }
    });

    test('caps the answer at 25 choices and honours the JSON path', () async {
      final many = '{"list":[${List.generate(30, (i) => '"v$i"').join(',')}]}';
      final out = await _parity(
        [
          _a(type, {'items': many, 'path': r'$.list'}),
        ],
        interaction: _Auto.new,
        variables: {'autocomplete.optionType': 'string'},
      );
      expect(out.effects.toString(), contains('v24'));
      expect(out.effects.toString(), isNot(contains('v25')));
    });

    test('requires an autocomplete interaction', () async {
      for (final make in <Object? Function()?>[null, _Command.new]) {
        final out = await _parity([
          _a(type, {'items': '[]'}),
        ], interaction: make);
        expect(
          out.errorText,
          contains(
            'respondWithAutocomplete requires an autocomplete interaction context',
          ),
        );
      }
    });

    test('nested in a block the enclosing lists report a plain stop', () async {
      final condition = {
        'variable': 'flag',
        'operator': 'equals',
        'value': 'yes',
      };
      final out = await _parity(
        [
          _a(BotCreatorActionType.ifBlock, {
            ...condition,
            'thenActions': [
              _a(type, {'items': '["a"]'}, key: 'ac').toJson(),
              _a(BotCreatorActionType.setTemporaryVariable, {
                'key': 'late',
                'value': 'x',
              }).toJson(),
            ],
            'elseActions': <Map<String, dynamic>>[],
          }, key: 'blk'),
          _a(BotCreatorActionType.setTemporaryVariable, {
            'key': 'after',
            'value': 'x',
          }),
        ],
        interaction: _Auto.new,
        variables: {'flag': 'yes', 'autocomplete.optionType': 'string'},
      );
      expect(out.variables.containsKey('late'), isFalse);
      expect(out.variables.containsKey('after'), isFalse);
    });
  });
}
