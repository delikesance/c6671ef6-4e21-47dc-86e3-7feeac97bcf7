import 'package:bot_creator_shared/types/action.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

import 'helpers/fake_role_gateway.dart';
import 'helpers/visual_golden.dart';
import 'helpers/visual_parity_harness.dart';

/// Parity of banUser / unbanUser / kickUser / muteUser / unmuteUser /
/// setNickname between the historical executor and `bc_<type>` on the native
/// engine, over the same simulated Discord gateway.

class _BanUser implements User {
  _BanUser(int id, this.username) : id = Snowflake(id);
  @override
  final Snowflake id;
  @override
  final String username;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Ban _ban(int id, String username) =>
    Ban(reason: 'Spam', user: _BanUser(id, username));

FakeGateway _gateway() => FakeGateway()
  ..guild.permissions =
      Permissions.kickMembers.value |
      Permissions.banMembers.value |
      Permissions.moderateMembers.value |
      Permissions.manageNicknames.value;

Object? _effects(FakeGateway g) => {
  'banned': g.guild.banned.map((e) => '$e').toList(),
  'deleteDuration': g.guild.deleteDuration,
  'unbanned': g.guild.unbanned.map((e) => '$e').toList(),
  'unbanAttempts': g.guild.unbanAttempts,
  'guildReason': g.guild.reason,
  'kicked': g.guild.memberManager.deleted.map((e) => '$e').toList(),
  'kickReason': g.guild.memberManager.reason,
  'updates': [
    for (final update in g.guild.memberManager.updates)
      {
        ...update,
        // Relative timeouts depend on the clock: keep only whether one is set.
        if (update['communication_disabled_until'] != null &&
            update['__exact'] != true)
          'communication_disabled_until': 'set',
      },
  ],
  'lookups': g.guild.lookups,
};

Future<Outcome<FakeGateway>> _parity(
  List<Action> actions, {
  void Function(FakeGateway gateway)? setup,
  Map<String, String>? variables,
  bool guild = true,
  bool throwOnError = false,
  Duration? limit,
  bool normalizeTimeouts = true,
}) async {
  final outcome = await visualParity<FakeGateway>(
    actions,
    makeGateway: _gateway,
    effects: normalizeTimeouts
        ? _effects
        : (g) => {
            ...(_effects(g)! as Map<String, Object?>),
            'updates': g.guild.memberManager.updates,
          },
    setup: setup,
    variables: variables,
    guild: guild,
    throwOnError: throwOnError,
    limit: limit,
    compareHistorical: parityWithHistorical,
  );
  _golden.expectOutcome(outcome);
  return outcome;
}

Action _mod(
  BotCreatorActionType type, {
  String? key,
  Map<String, dynamic> payload = const {},
  Map<String, String> error = const {},
  bool enabled = true,
}) => visualAction(
  type,
  key: key,
  enabled: enabled,
  error: error,
  payload: {'userId': '222', ...payload},
);

final _golden = GoldenFile('visual_moderation_actions');

void main() {
  group('banUser parity', () {
    const type = BotCreatorActionType.banUser;
    test('bans with an explicit reason and message days', () async {
      final outcome = await _parity([
        _mod(
          type,
          key: 'ban',
          payload: {'reason': 'Spam', 'deleteMessageDays': '3'},
        ),
      ]);
      expect(outcome.results, {'ban': '222'});
      final gateway = outcome.gateway;
      expect(gateway.guild.banned, [Snowflake(222)]);
      expect(gateway.guild.reason, 'Spam');
      expect(gateway.guild.deleteDuration, const Duration(days: 3));
      expect(outcome.variables['lastSentMessageId'], '222');
    });

    test('keeps the historical default audit reason and clamps days', () async {
      final outcome = await _parity([
        _mod(type, payload: {'deleteMessageDays': 30}),
        _mod(type, key: 'b', payload: {'deleteMessageDays': 'x'}),
      ]);
      expect(outcome.gateway.guild.reason, 'Ban via BotCreator action');
      expect(outcome.results!.keys, ['action_0', 'b']);
    });

    test('resolves placeholders and reads earlier results', () async {
      final outcome = await _parity(
        [
          _mod(type, key: 'first', payload: {'userId': '((target))'}),
          _mod(
            type,
            key: 'second',
            payload: {'userId': '((first))', 'reason': 'again ((first))'},
          ),
        ],
        variables: {'target': '333'},
      );
      expect(outcome.results, {'first': '333', 'second': '333'});
      expect(outcome.gateway.guild.reason, 'again 333');
    });

    test(
      'fails on an invalid user, without a guild and without permission',
      () async {
        var outcome = await _parity([
          _mod(type, payload: {'userId': 'x'}),
        ]);
        expect(
          outcome.error.toString(),
          'Exception: Missing or invalid userId',
        );
        expect(outcome.variables['error.command'], type.name);
        outcome = await _parity([_mod(type)], guild: false);
        expect(
          outcome.error.toString(),
          'Exception: User action requires a guild context',
        );
        outcome = await _parity([
          _mod(type),
        ], setup: (g) => g.guild.permissions = 0);
        expect(outcome.error, isA<Exception>());
        expect(outcome.gateway.guild.banned, isEmpty);
      },
    );

    test('error modes and disabled actions behave the same', () async {
      final outcome = await _parity([
        _mod(type, key: 'off', enabled: false),
        _mod(
          type,
          key: 'bad',
          payload: {'userId': ''},
          error: {'mode': 'continue'},
        ),
        _mod(type, key: 'good'),
      ]);
      expect(outcome.results!['bad'], startsWith('Error: Exception: '));
      expect(outcome.results!['good'], '222');
      expect(outcome.results!.containsKey('off'), isFalse);
    });
  });

  group('unbanUser parity', () {
    const type = BotCreatorActionType.unbanUser;
    test('unbans by id with the default and an explicit reason', () async {
      var outcome = await _parity([_mod(type, key: 'u')]);
      expect(outcome.results, {'u': '222'});
      expect(outcome.gateway.guild.reason, 'Unban via BotCreator action');
      outcome = await _parity([
        _mod(type, payload: {'reason': 'Appeal'}),
      ]);
      expect(outcome.gateway.guild.reason, 'Appeal');
    });

    test('falls back to the username when the id is invalid', () async {
      final outcome = await _parity([
        _mod(type, payload: {'userId': 'nope', 'username': 'TARGET'}),
      ], setup: (g) => g.guild.banPages.add([_ban(444, 'Target')]));
      expect(outcome.results, {'action_0': '444'});
      expect(outcome.gateway.guild.unbanned, [Snowflake(444)]);
    });

    test('reports an unknown user, an empty target and a refusal', () async {
      var outcome = await _parity([
        _mod(type, payload: {'userId': '', 'username': 'ghost'}),
      ]);
      expect(outcome.error.toString(), 'Exception: Banned user not found');
      outcome = await _parity([
        _mod(type, payload: {'userId': ''}),
      ]);
      expect(outcome.error.toString(), 'Exception: Banned user not found');
      outcome = await _parity([
        _mod(type),
      ], setup: (g) => g.guild.failUnban = true);
      expect(outcome.error.toString(), contains('Discord refused unban'));
      outcome = await _parity([_mod(type)], guild: false);
      expect(
        outcome.error.toString(),
        'Exception: User action requires a guild context',
      );
    });
  });

  group('kickUser parity', () {
    const type = BotCreatorActionType.kickUser;
    test('kicks with a reason, default reason and placeholders', () async {
      var outcome = await _parity([
        _mod(type, key: 'k', payload: {'reason': 'Rude'}),
      ]);
      expect(outcome.results, {'k': '222'});
      expect(outcome.gateway.guild.memberManager.reason, 'Rude');
      outcome = await _parity(
        [
          _mod(type, payload: {'userId': '((who))'}),
        ],
        variables: {'who': '333'},
      );
      expect(outcome.gateway.guild.memberManager.deleted, [Snowflake(333)]);
      expect(
        outcome.gateway.guild.memberManager.reason,
        'Kick via BotCreator action',
      );
    });

    test('checks the command author permission when given', () async {
      final outcome = await _parity([
        _mod(type, payload: {'kickPermissionActorId': 'bad'}),
      ]);
      expect(outcome.error, isA<Exception>());
      expect(outcome.gateway.guild.memberManager.deleted, isEmpty);
    });

    test('reports failures like the historical action', () async {
      var outcome = await _parity([
        _mod(type, payload: {'userId': ''}),
      ]);
      expect(outcome.error.toString(), 'Exception: Missing or invalid userId');
      outcome = await _parity([
        _mod(type),
      ], setup: (g) => g.guild.memberManager.failDelete = true);
      expect(outcome.error.toString(), contains('Discord refused'));
      outcome = await _parity([
        _mod(type),
      ], setup: (g) => g.guild.memberManager.targetSharesBotRole = true);
      expect(outcome.error, isA<Exception>());
      outcome = await _parity([_mod(type)], throwOnError: true);
      expect(outcome.error, isNull);
    });
  });

  group('muteUser parity', () {
    const type = BotCreatorActionType.muteUser;
    test('mutes with the default duration and reason', () async {
      final outcome = await _parity([_mod(type, key: 'm')]);
      expect(outcome.results, {'m': '222'});
      final update = outcome.gateway.guild.memberManager.updates.single;
      expect(update['reason'], 'Timeout via BotCreator action');
      expect(update['communication_disabled_until'], isNotNull);
    });

    test('accepts the duration variants and memberId', () async {
      for (final payload in <Map<String, dynamic>>[
        {'durationSeconds': '30'},
        {'durationMinutes': 5},
        {'durationHours': '2'},
        {'duration': '3d'},
        {'duration': '90'},
        {'userId': 'x', 'memberId': '333'},
      ]) {
        final outcome = await _parity([_mod(type, payload: payload)]);
        expect(outcome.error, isNull, reason: '$payload');
      }
    });

    test('uses an explicit until date exactly', () async {
      final until = DateTime.now().toUtc().add(const Duration(hours: 1));
      final outcome = await _parity([
        _mod(type, payload: {'until': until.toIso8601String(), 'reason': 'x'}),
      ], normalizeTimeouts: false);
      expect(
        outcome
            .gateway
            .guild
            .memberManager
            .updates
            .single['communication_disabled_until'],
        until.toIso8601String(),
      );
    });

    test('rejects a malformed until and an invalid user', () async {
      var outcome = await _parity([
        _mod(type, payload: {'until': 'soon'}),
      ]);
      expect(
        outcome.error.toString(),
        'Exception: Invalid until datetime format',
      );
      outcome = await _parity([
        _mod(type, payload: {'until': '2001-01-01T00:00:00Z'}),
      ]);
      expect(outcome.error, isNull); // a past deadline is clamped
      outcome = await _parity([
        _mod(type, payload: {'userId': '', 'memberId': ''}),
      ]);
      expect(
        outcome.error.toString(),
        'Exception: Missing or invalid userId/memberId',
      );
      outcome = await _parity([
        _mod(type),
      ], setup: (g) => g.guild.memberManager.failUpdate = true);
      expect(outcome.error.toString(), contains('Discord refused timeout'));
    });
  });

  group('unmuteUser parity', () {
    const type = BotCreatorActionType.unmuteUser;
    test('removes the timeout', () async {
      final outcome = await _parity([_mod(type, key: 'u')]);
      expect(outcome.results, {'u': '222'});
      final update = outcome.gateway.guild.memberManager.updates.single;
      expect(update['reason'], 'Remove timeout via BotCreator action');
    });

    test('falls back to memberId and reports failures', () async {
      var outcome = await _parity([
        _mod(type, payload: {'userId': 'x', 'memberId': '333', 'reason': 'ok'}),
      ]);
      expect(outcome.results, {'action_0': '333'});
      outcome = await _parity([
        _mod(type, payload: {'userId': '', 'memberId': ''}),
      ]);
      expect(
        outcome.error.toString(),
        'Exception: Missing or invalid userId/memberId',
      );
      outcome = await _parity([
        _mod(type),
      ], setup: (g) => g.guild.permissions = 0);
      expect(outcome.error, isA<Exception>());
    });
  });

  group('setNickname parity', () {
    const type = BotCreatorActionType.setNickname;
    Action nick({String? key, Map<String, dynamic> payload = const {}}) =>
        visualAction(
          type,
          key: key,
          payload: {'userId': '222', 'nickname': 'Neo', ...payload},
        );

    test('sets the nickname with and without a reason', () async {
      var outcome = await _parity([nick(key: 'n')]);
      expect(outcome.results, {'n': '222'});
      var update = outcome.gateway.guild.memberManager.updates.single;
      expect(update['nick'], 'Neo');
      expect(update['reason'], isNull);
      outcome = await _parity([
        nick(payload: {'reason': ' Because '}),
      ]);
      update = outcome.gateway.guild.memberManager.updates.single;
      expect(update['reason'], ' Because ');
    });

    test('normalizes the id and resolves placeholders', () async {
      final outcome = await _parity(
        [
          nick(payload: {'userId': ' ((who)) ', 'nickname': '((name)) !'}),
        ],
        variables: {'who': '333', 'name': 'Trin'},
      );
      expect(outcome.results, {'action_0': '333'});
      expect(
        outcome.gateway.guild.memberManager.updates.single['nick'],
        'Trin !',
      );
    });

    test('clears a nickname with an empty value', () async {
      final outcome = await _parity([
        nick(payload: {'nickname': ''}),
      ]);
      expect(outcome.gateway.guild.memberManager.updates.single['nick'], '');
    });

    test(
      'reports an invalid user, a missing permission and a refusal',
      () async {
        var outcome = await _parity([
          nick(payload: {'userId': 'x'}),
        ]);
        expect(outcome.error.toString(), 'Exception: Invalid userId');
        outcome = await _parity([
          nick(),
        ], setup: (g) => g.guild.permissions = 0);
        expect(outcome.error, isA<Exception>());
        outcome = await _parity([
          nick(),
        ], setup: (g) => g.guild.memberManager.failUpdate = true);
        expect(outcome.error.toString(), contains('Failed to set nickname'));
        outcome = await _parity([nick()], guild: false);
        expect(
          outcome.error.toString(),
          'Exception: User action requires a guild context',
        );
      },
    );
  });
}
