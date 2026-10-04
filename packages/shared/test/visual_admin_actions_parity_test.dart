import 'package:bot_creator_shared/engine/bdfd/visual/action_translator.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

import 'helpers/visual_admin_gateway.dart';
import 'helpers/visual_golden.dart';
import 'helpers/visual_parity_harness.dart';

/// Parity of the poll / voice moderation / AutoMod / guild settings /
/// onboarding blocks between the historical executors and `bc_<type>` on the
/// native engine, over the same recording Discord gateway: createPoll, endPoll,
/// moveToVoiceChannel, disconnectFromVoice, serverMuteMember,
/// serverDeafenMember, updateGuild, updateAutoMod, createAutoModRule,
/// deleteAutoModRule, listAutoModRules, getGuildOnboarding and
/// updateGuildOnboarding.

typedef _Out = Outcome<AdminGateway>;

Future<_Out> _parity(
  List<Action> actions, {
  int permissions = 8,
  void Function(AdminGateway gateway)? setup,
  Map<String, String>? variables,
  bool guild = true,
  Snowflake? fallbackChannelId,
}) async {
  final outcome = await visualParity<AdminGateway>(
    actions,
    makeGateway: () => AdminGateway(permissions: permissions),
    effects: (g) => g.writes,
    setup: setup,
    variables: variables,
    guild: guild,
    fallbackChannelId: fallbackChannelId,
    compareHistorical: parityWithHistorical,
  );
  _golden.expectOutcome(outcome);
  return outcome;
}

Action _a(
  BotCreatorActionType type,
  Map<String, dynamic> payload, {
  String? key,
  Map<String, String> error = const {},
  bool enabled = true,
}) => visualAction(
  type,
  key: key,
  payload: payload,
  error: error,
  enabled: enabled,
);

Future<void> _fails(
  BotCreatorActionType type,
  Map<String, dynamic> payload,
  Object matcher, {
  int permissions = 8,
  void Function(AdminGateway gateway)? setup,
  bool guild = true,
}) async {
  final outcome = await _parity(
    [_a(type, payload)],
    permissions: permissions,
    setup: setup,
    guild: guild,
  );
  expect(outcome.error.toString(), matcher);
  expect(outcome.variables['error.command'], type.name);
}

/// The routine checks of any block: error modes, disabled actions, no trace
/// bookkeeping outside profiling.
Future<void> _commonBehaviour(
  BotCreatorActionType type,
  Map<String, dynamic> valid,
) async {
  final outcome = await _parity([
    _a(type, const {'userId': 'x'}, key: 'bad', error: {'mode': 'continue'}),
    _a(type, valid, key: 'off', enabled: false),
    _a(type, valid, key: 'ok'),
  ]);
  expect(outcome.results!.containsKey('off'), isFalse);
  expect(outcome.results!['bad'], startsWith('Error: '));
  // Switch-handled historically: no "last message" bookkeeping.
  expect(outcome.variables.containsKey('lastSentMessageId'), isFalse);
}

final _golden = GoldenFile('visual_admin_actions');

void main() {
  group('createPoll parity', () {
    const type = BotCreatorActionType.createPoll;
    test('creates a poll and mirrors its results', () async {
      final outcome = await _parity([
        _a(type, {
          'channelId': '30',
          'question': ' Best? ',
          'answers': ['A', ' B ', ''],
          'durationHours': '48',
          'allowMultiselect': 'true',
        }, key: 'p'),
      ]);
      expect(outcome.results!['p'], isNotEmpty);
      expect(outcome.variables['p.messageId'], outcome.results!['p']);
      expect(outcome.variables['p.pollId'], outcome.results!['p']);
      expect(outcome.gateway.writes.single['operation'], 'sendMessage');
      expect(outcome.variables.containsKey('lastSentMessageId'), isFalse);
    });

    test(
      'parses JSON and comma separated answers, clamps the duration',
      () async {
        final json = await _parity([
          _a(type, {
            'channelId': '30',
            'question': 'Q',
            'answers': '["Yes","No"]',
            'durationHours': '9999',
          }),
        ]);
        expect(json.error, isNull);
        final comma = await _parity([
          _a(type, {
            'channelId': '30',
            'question': 'Q',
            'answers': 'Yes, No ,Maybe',
            'durationHours': 'abc',
          }),
        ]);
        expect(comma.error, isNull);
      },
    );

    test('resolves placeholders and uses the fallback channel', () async {
      final outcome = await _parity(
        [
          _a(type, {
            'question': '((q))',
            'answers': ['((a))', 'B'],
          }),
        ],
        variables: {'q': 'From var', 'a': 'First'},
        fallbackChannelId: Snowflake(30),
      );
      expect(outcome.error, isNull);
      expect(outcome.gateway.writes.single['channel'], '30');
    });

    test('later actions read earlier results', () async {
      final outcome = await _parity([
        _a(type, {
          'channelId': '30',
          'question': 'One',
          'answers': ['a'],
        }, key: 'one'),
        _a(type, {
          'channelId': '30',
          'question': 'After ((one))',
          'answers': ['a'],
        }, key: 'two'),
      ]);
      expect(outcome.error, isNull);
    });

    test('reports its failures like the historical branch', () async {
      const ok = {
        'channelId': '30',
        'question': 'Q',
        'answers': ['a'],
      };
      await _fails(
        type,
        {...ok}..remove('channelId'),
        'Exception: channelId is required for createPoll',
      );
      await _fails(type, {
        ...ok,
        'question': ' ',
      }, 'Exception: question is required for createPoll');
      await _fails(type, {
        ...ok,
        'answers': [],
      }, 'Exception: At least one answer is required for createPoll');
      await _fails(type, {
        ...ok,
        'answers': List.generate(11, (i) => 'a$i'),
      }, 'Exception: createPoll supports at most 10 answers');
      await _fails(type, {
        ...ok,
        'channelId': '34',
      }, 'Exception: Channel is not a text channel');
      await _fails(type, {
        ...ok,
        'channelId': '404',
      }, 'Exception: Channel is not a text channel');
      await _fails(
        type,
        ok,
        startsWith('Exception: I do not have permission to create polls'),
        permissions: 0,
      );
      await _fails(
        type,
        ok,
        'Exception: Failed to create poll: Bad state: refused',
        setup: (g) => g.failures['sendMessage'] = StateError('refused'),
      );
    });

    test('works without a guild context (no permission pre-check)', () async {
      final outcome = await _parity(
        [
          _a(type, {
            'channelId': '30',
            'question': 'Q',
            'answers': ['a'],
          }),
        ],
        guild: false,
        permissions: 0,
      );
      expect(outcome.error, isNull);
    });

    test('error modes and disabled actions behave the same', () async {
      await _commonBehaviour(type, {
        'channelId': '30',
        'question': 'Q',
        'answers': ['a'],
      });
    });
  });

  group('endPoll parity', () {
    const type = BotCreatorActionType.endPoll;
    test('ends a poll', () async {
      final outcome = await _parity([
        _a(type, {'channelId': '30', 'messageId': '55'}, key: 'e'),
      ]);
      expect(outcome.results, {'e': 'ended'});
      expect(outcome.gateway.writes.single, {
        'operation': 'endPoll',
        'channel': '30',
        'message': '55',
      });
    });

    test('resolves placeholders and uses the fallback channel', () async {
      final outcome = await _parity(
        [
          _a(type, {'messageId': '((m))'}),
        ],
        variables: {'m': '77'},
        fallbackChannelId: Snowflake(30),
      );
      expect(outcome.gateway.writes.single['message'], '77');
      expect(outcome.gateway.writes.single['channel'], '30');
    });

    test('reports its failures like the historical branch', () async {
      await _fails(type, {
        'messageId': '5',
      }, 'Exception: channelId is required for endPoll');
      await _fails(type, {
        'channelId': '30',
      }, 'Exception: messageId is required for endPoll');
      await _fails(type, {
        'channelId': '34',
        'messageId': '5',
      }, 'Exception: Channel is not a text channel');
      await _fails(
        type,
        {'channelId': '30', 'messageId': '5'},
        startsWith('Exception: I do not have permission to end polls'),
        permissions: 0,
      );
      await _fails(
        type,
        {'channelId': '30', 'messageId': '5'},
        'Exception: Failed to end poll: Bad state: refused',
        setup: (g) => g.failures['endPoll'] = StateError('refused'),
      );
    });

    test('error modes and disabled actions behave the same', () async {
      await _commonBehaviour(type, {'channelId': '30', 'messageId': '5'});
    });
  });

  group('voice blocks parity', () {
    test('moveToVoiceChannel moves a member', () async {
      const type = BotCreatorActionType.moveToVoiceChannel;
      final outcome = await _parity([
        _a(type, {
          'userId': '20',
          'targetChannelId': '34',
          'reason': ' Because ',
        }, key: 'm'),
      ]);
      expect(outcome.results, {'m': 'moved'});
      final write = outcome.gateway.writes.single;
      expect(write['reason'], 'Because');
      expect((write['payload'] as Map)['channel_id'], '34');
    });

    test('disconnectFromVoice disconnects a member', () async {
      const type = BotCreatorActionType.disconnectFromVoice;
      final outcome = await _parity(
        [
          _a(type, {'userId': '((u))'}, key: 'd'),
        ],
        variables: {'u': '20'},
      );
      expect(outcome.results, {'d': 'disconnected'});
      expect(
        (outcome.gateway.writes.single['payload'] as Map)['channel_id'],
        '0',
      );
    });

    test('serverMuteMember and serverDeafenMember toggle', () async {
      const mute = BotCreatorActionType.serverMuteMember;
      const deaf = BotCreatorActionType.serverDeafenMember;
      final outcome = await _parity([
        _a(mute, {'userId': '20'}, key: 'a'),
        _a(mute, {'userId': '20', 'mute': 'false'}, key: 'b'),
        _a(deaf, {'userId': '20'}, key: 'c'),
        _a(deaf, {'userId': '20', 'deaf': 'no', 'reason': 'r'}, key: 'd'),
      ]);
      expect(outcome.results, {
        'a': 'muted',
        'b': 'unmuted',
        'c': 'deafened',
        'd': 'undeafened',
      });
    });

    test('report their failures like the historical branches', () async {
      const cases = {
        BotCreatorActionType.moveToVoiceChannel: [
          'move members in voice channels',
          'targetChannelId is required for moveToVoiceChannel',
        ],
        BotCreatorActionType.disconnectFromVoice: [
          'disconnect members from voice',
          'userId is required for disconnectFromVoice',
        ],
        BotCreatorActionType.serverMuteMember: [
          'server-mute members',
          'userId is required for serverMuteMember',
        ],
        BotCreatorActionType.serverDeafenMember: [
          'server-deafen members',
          'userId is required for serverDeafenMember',
        ],
      };
      for (final entry in cases.entries) {
        final type = entry.key;
        final valid = {'userId': '20', 'targetChannelId': '34'};
        await _fails(
          type,
          valid,
          '${entry.key.name} requires a guild context'.replaceFirst(
            RegExp('^'),
            'Exception: ',
          ),
          guild: false,
        );
        await _fails(
          type,
          valid,
          startsWith(
            'Exception: I do not have permission to ${entry.value[0]}',
          ),
          permissions: 0,
        );
        await _fails(
          type,
          type == BotCreatorActionType.moveToVoiceChannel
              ? {'userId': '20'}
              : {'reason': 'x'},
          'Exception: ${entry.value[1]}',
        );
        await _fails(
          type,
          valid,
          startsWith('Exception: Failed to '),
          setup: (g) => g.failures['updateMember'] = StateError('refused'),
        );
      }
      await _fails(BotCreatorActionType.moveToVoiceChannel, {
        'targetChannelId': '34',
      }, 'Exception: userId is required for moveToVoiceChannel');
    });

    test('error modes and disabled actions behave the same', () async {
      await _commonBehaviour(BotCreatorActionType.serverMuteMember, {
        'userId': '20',
      });
    });
  });

  group('updateGuild parity', () {
    const type = BotCreatorActionType.updateGuild;
    test('updates the settings the payload names', () async {
      final outcome = await _parity(
        [
          _a(type, {
            'name': ' ((n)) ',
            'description': 'About',
            'afkTimeoutSeconds': '300',
            'afkChannelId': '34',
            'systemChannelId': '30',
            'verificationLevel': '2',
            'defaultMessageNotificationLevel': '1',
            'explicitContentFilterLevel': '2',
            'premiumProgressBarEnabled': 'TRUE',
            'preferredLocale': 'fr',
            'reason': ' why ',
          }, key: 'g'),
        ],
        variables: {'n': 'New'},
      );
      expect(outcome.results, {'g': '10'});
      final write = outcome.gateway.writes.single;
      expect(write['reason'], 'why');
      expect((write['payload'] as Map)['name'], 'New');
    });

    test('an empty payload still updates', () async {
      final outcome = await _parity([_a(type, const {})]);
      expect(outcome.error, isNull);
    });

    test('reports its failures like the historical branch', () async {
      await _fails(
        type,
        {'name': 'x'},
        'Exception: Missing guildId',
        guild: false,
      );
      await _fails(
        type,
        {'name': 'x'},
        startsWith(
          'Exception: I do not have permission to update server settings',
        ),
        permissions: 0,
      );
      await _fails(
        type,
        {'name': 'x'},
        startsWith('Exception: Failed to update guild: '),
        setup: (g) => g.failures['updateGuild'] = StateError('refused'),
      );
    });

    test('error modes and disabled actions behave the same', () async {
      final outcome = await _parity(
        [
          _a(type, {'name': 'x'}, key: 'bad', error: {'mode': 'continue'}),
          _a(type, {'name': 'y'}, key: 'ok'),
        ],
        guild: true,
        setup: (g) => g.failures['updateGuild'] = StateError('x'),
      );
      expect(outcome.results!['bad'], startsWith('Error: '));
      expect(outcome.results!['ok'], '10');
    });
  });

  group('updateAutoMod parity', () {
    const type = BotCreatorActionType.updateAutoMod;
    test('creates the keyword and mention rules', () async {
      final outcome = await _parity([
        _a(type, {
          'enabled': false,
          'filterWords': 'bad, worse',
          'allowedRoles': ['64'],
          'maxMentions': '99',
          'reason': 'r',
        }, key: 'a'),
      ]);
      expect(outcome.results, {'a': 'OK'});
      expect(outcome.gateway.writes.map((w) => w['operation']), [
        'createRule',
        'createRule',
      ]);
    });

    test('updates the existing rules', () async {
      final outcome = await _parity(
        [
          _a(type, {
            'filterWords': ['x'],
            'ruleId': '((r))',
          }),
          _a(type, {'filterWords': ''}),
        ],
        variables: {'r': '1'},
        setup: (g) {
          g.rules.add(AdminRule(g, 1, 'BotCreator - Keyword Filter'));
          g.rules.add(AdminRule(g, 2, 'BotCreator - Mention Limit'));
        },
      );
      expect(
        outcome.gateway.writes.map((w) => w['operation']),
        everyElement('updateRule'),
      );
    });

    test('reports its failures like the historical branch', () async {
      await _fails(type, {}, 'Exception: Missing guildId', guild: false);
      await _fails(
        type,
        {},
        startsWith(
          'Exception: I do not have permission to update automod settings',
        ),
        permissions: 0,
      );
      await _fails(
        type,
        {},
        startsWith('Exception: Failed to update auto-moderation: '),
        setup: (g) => g.failures['createRule'] = StateError('refused'),
      );
    });

    test('error modes and disabled actions behave the same', () async {
      final outcome = await _parity([
        _a(type, {}, key: 'bad', error: {'mode': 'continue'}),
        _a(type, {}, key: 'off', enabled: false),
        _a(type, {}, key: 'ok'),
      ], setup: (g) => g.failures['createRule'] = StateError('x'));
      expect(outcome.results!['bad'], startsWith('Error: '));
      expect(outcome.results!.containsKey('off'), isFalse);
    });
  });

  group('AutoMod rule blocks parity', () {
    test('createAutoModRule builds each trigger and action', () async {
      const type = BotCreatorActionType.createAutoModRule;
      final outcome = await _parity(
        [
          _a(type, {
            'name': ' ((n)) ',
            'triggerType': 'keyword',
            'keywords': 'a,b',
            'regexPatterns': ['x+'],
            'allowedWords': '["ok"]',
            'actionType': 'send_alert_message',
            'alertChannelId': '30',
            'exemptRoles': '64',
            'exemptChannels': ['30'],
            'enabled': 'false',
            'reason': 'why',
          }, key: 'r'),
          _a(type, {
            'name': 'Presets',
            'triggerType': 'keyword_preset',
            'keywordPresets': ['profanity', 'slurs', 'bogus'],
            'actionType': 'timeout',
            'timeoutDuration': '120',
          }),
          _a(type, {
            'name': 'Mentions',
            'triggerType': 'mentionSpam',
            'mentionTotalLimit': '8',
          }),
          _a(type, {'name': 'Spam', 'triggerType': 'spam'}),
        ],
        variables: {'n': 'Named'},
      );
      expect(outcome.results!['r'], '950');
      expect(outcome.variables['r.ruleId'], '950');
      expect(outcome.variables['r.name'], 'Named');
      expect(outcome.gateway.writes, hasLength(4));
    });

    test('createAutoModRule reports its failures', () async {
      const type = BotCreatorActionType.createAutoModRule;
      await _fails(
        type,
        {'name': 'x'},
        'Exception: createAutoModRule requires a guild context',
        guild: false,
      );
      await _fails(
        type,
        {'name': 'x'},
        startsWith(
          'Exception: I do not have permission to manage automod rules',
        ),
        permissions: 0,
      );
      await _fails(type, {
        'name': ' ',
      }, 'Exception: name is required for createAutoModRule');
      await _fails(
        type,
        {'name': 'x'},
        startsWith('Exception: Failed to create AutoMod rule: '),
        setup: (g) => g.failures['createRule'] = StateError('refused'),
      );
    });

    test('deleteAutoModRule deletes a rule', () async {
      const type = BotCreatorActionType.deleteAutoModRule;
      final outcome = await _parity(
        [
          _a(type, {'ruleId': '((r))', 'reason': 'x'}, key: 'd'),
        ],
        variables: {'r': '77'},
      );
      expect(outcome.results, {'d': 'deleted'});
      expect(outcome.gateway.writes.single['id'], '77');
      await _fails(type, {
        'ruleId': '',
      }, 'Exception: ruleId is required for deleteAutoModRule');
      await _fails(
        type,
        {'ruleId': '1'},
        'Exception: deleteAutoModRule requires a guild context',
        guild: false,
      );
      await _fails(
        type,
        {'ruleId': '1'},
        startsWith(
          'Exception: I do not have permission to delete automod rules',
        ),
        permissions: 0,
      );
      await _fails(
        type,
        {'ruleId': '1'},
        startsWith('Exception: Failed to delete AutoMod rule: '),
        setup: (g) => g.failures['deleteRule'] = StateError('refused'),
      );
    });

    test('listAutoModRules lists the rules', () async {
      const type = BotCreatorActionType.listAutoModRules;
      final empty = await _parity([_a(type, const {}, key: 'l')]);
      expect(empty.results, {'l': '[]'});
      expect(empty.variables['l.count'], '0');
      final outcome = await _parity(
        [_a(type, const {}, key: 'l')],
        setup: (g) => g.rules.addAll([
          AdminRule(g, 1, 'One'),
          AdminRule(g, 2, 'Two', isEnabled: false),
        ]),
      );
      expect(outcome.variables['l.count'], '2');
      expect(outcome.variables['l.rulesJson'], outcome.results!['l']);
      await _fails(
        type,
        const {},
        'Exception: listAutoModRules requires a guild context',
        guild: false,
      );
      await _fails(
        type,
        const {},
        startsWith('Exception: I do not have permission to list automod rules'),
        permissions: 0,
      );
    });

    test('error modes and disabled actions behave the same', () async {
      await _commonBehaviour(BotCreatorActionType.deleteAutoModRule, {
        'ruleId': '1',
      });
    });
  });

  group('guild onboarding parity', () {
    test('getGuildOnboarding reads the configuration', () async {
      const type = BotCreatorActionType.getGuildOnboarding;
      final outcome = await _parity([_a(type, const {}, key: 'o')]);
      expect(outcome.variables['o.enabled'], 'true');
      expect(outcome.variables['o.onboardingJson'], outcome.results!['o']);
      final off = await _parity([
        _a(type, const {}, key: 'o'),
      ], setup: (g) => g.onboardingEnabled = false);
      expect(off.variables['o.enabled'], 'false');
      await _fails(
        type,
        const {},
        'Exception: getGuildOnboarding requires a guild context',
        guild: false,
      );
      await _fails(
        type,
        const {},
        startsWith(
          'Exception: I do not have permission to view guild onboarding',
        ),
        permissions: 0,
      );
      await _fails(
        type,
        const {},
        startsWith('Exception: Failed to get guild onboarding: '),
        setup: (g) => g.failures['fetchOnboarding'] = StateError('refused'),
      );
    });

    test('updateGuildOnboarding fails like the historical branch', () async {
      const type = BotCreatorActionType.updateGuildOnboarding;
      await _fails(
        type,
        {'enabled': '((e))'},
        'Exception: updateGuildOnboarding is not supported by the current nyxx runtime yet',
      );
      await _fails(
        type,
        const {},
        'Exception: updateGuildOnboarding requires a guild context',
        guild: false,
      );
      await _fails(
        type,
        const {},
        startsWith(
          'Exception: I do not have permission to update guild onboarding',
        ),
        permissions: 0,
      );
      final outcome = await _parity([
        _a(type, const {}, key: 'bad', error: {'mode': 'continue'}),
        _a(BotCreatorActionType.getGuildOnboarding, const {}, key: 'ok'),
      ]);
      expect(outcome.results!['bad'], startsWith('Error: '));
      expect(outcome.results!['ok'], isNotEmpty);
    });
  });

  group('routing', () {
    test('every block of the wave is supported natively, payload-agnostic', () {
      const translator = ActionTranslator();
      for (final type in [
        BotCreatorActionType.createPoll,
        BotCreatorActionType.endPoll,
        BotCreatorActionType.moveToVoiceChannel,
        BotCreatorActionType.disconnectFromVoice,
        BotCreatorActionType.serverMuteMember,
        BotCreatorActionType.serverDeafenMember,
        BotCreatorActionType.updateGuild,
        BotCreatorActionType.updateAutoMod,
        BotCreatorActionType.createAutoModRule,
        BotCreatorActionType.deleteAutoModRule,
        BotCreatorActionType.listAutoModRules,
        BotCreatorActionType.getGuildOnboarding,
        BotCreatorActionType.updateGuildOnboarding,
      ]) {
        expect(
          translator.supports(Action(type: type, payload: const {})),
          isTrue,
          reason: type.name,
        );
        expect(
          const ActionTranslator.none().supports(
            Action(type: type, payload: const {}),
          ),
          isFalse,
        );
      }
    });

    test('debugProfile runs on the native runner', () {
      expect(
        const ActionTranslator().supports(
          Action(type: BotCreatorActionType.debugProfile, payload: const {}),
        ),
        isTrue,
      );
    });
  });
}
