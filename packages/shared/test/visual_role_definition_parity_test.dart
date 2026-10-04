import 'package:bot_creator_shared/types/action.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

import 'helpers/fake_role_gateway.dart';
import 'helpers/visual_parity_harness.dart';

/// Role definitions (`createNew`, `modify`, `updateColor`, `modifyPermissions`,
/// `deleteRole`) carried by addRole / removeRole: historical executor against
/// `bc_addRole` / `bc_removeRole`.

FakeGateway _gateway() =>
    FakeGateway()..guild.permissions = Permissions.manageRoles.value;

Object? _effects(FakeGateway g) => {
  'writes': g.guild.roleManager.writes,
  'lookups': g.guild.lookups,
};

Future<Outcome<FakeGateway>> _parity(
  List<Action> actions, {
  void Function(FakeGateway gateway)? setup,
  bool guild = true,
  Map<String, String>? variables,
}) => visualParity<FakeGateway>(
  actions,
  makeGateway: _gateway,
  effects: _effects,
  setup: setup,
  guild: guild,
  variables: variables,
);

Action _def(
  BotCreatorActionType type,
  Map<String, dynamic> payload, {
  String? key,
}) => visualAction(type, key: key, payload: payload);

void main() {
  const add = BotCreatorActionType.addRole;
  const remove = BotCreatorActionType.removeRole;

  test('createNew creates a role and returns its id', () async {
    final outcome = await _parity([
      _def(add, {
        'createNew': true,
        'name': 'Staff',
        'color': '#ff0000',
        'hoist': true,
        'mentionable': false,
        'reason': 'Because',
      }, key: 'role'),
    ]);
    expect(outcome.results, {'role': '65'});
    final write = outcome.gateway.guild.roleManager.writes.single;
    expect(write['operation'], 'create');
    expect(write['name'], 'Staff');
    expect(write['reason'], 'Because');
    // Numeric: it becomes the "last message" for the historical trace.
    expect(outcome.variables['lastSentMessageId'], '65');
  });

  test('definitions send no default audit reason', () async {
    final outcome = await _parity([
      _def(add, {'createNew': true, 'name': 'Staff', 'color': '#00ff00'}),
    ]);
    expect(outcome.gateway.guild.roleManager.writes.single['reason'], isNull);
  });

  test('modify and updateColor update the role', () async {
    final outcome = await _parity([
      _def(add, {'modify': true, 'roleId': '64', 'name': 'Renamed'}, key: 'a'),
      _def(add, {'updateColor': '#112233', 'roleId': '64'}, key: 'b'),
    ]);
    expect(outcome.results, {'a': '64', 'b': '64'});
    expect(outcome.gateway.guild.roleManager.writes.length, 2);
  });

  test('modifyPermissions toggles the named permissions', () async {
    final outcome = await _parity([
      _def(add, {
        'modifyPermissions': ['sendmessages'],
        'roleId': '64',
      }),
    ]);
    expect(outcome.error, isNull);
    expect(
      outcome.gateway.guild.roleManager.writes.single['operation'],
      'update',
    );
  });

  test('removeRole carries deleteRole and the same definitions', () async {
    var outcome = await _parity([
      _def(remove, {'deleteRole': true, 'roleId': '64', 'reason': 'Bye'}),
    ]);
    expect(outcome.results, {'action_0': '64'});
    expect(outcome.gateway.guild.roleManager.writes.single, {
      'operation': 'delete',
      'id': '64',
      'reason': 'Bye',
    });
    outcome = await _parity([
      _def(remove, {'modify': true, 'roleId': '64', 'name': 'X'}),
    ]);
    expect(outcome.error, isNull);
  });

  test('placeholders are resolved before the request is built', () async {
    final outcome = await _parity(
      [
        _def(add, {
          'createNew': true,
          'name': 'Staff',
          'color': '#ff0000',
        }, key: 'a'),
        _def(remove, {'deleteRole': true, 'roleId': '((rid))'}, key: 'b'),
      ],
      variables: {'rid': '64'},
    );
    expect(outcome.results, {'a': '65', 'b': '64'});
  });

  group('failures', () {
    test('invalid color and permissions', () async {
      var outcome = await _parity([
        _def(add, {'createNew': true, 'name': 'X', 'color': 'nope'}),
      ]);
      expect(outcome.error.toString(), 'Exception: Invalid role color');
      outcome = await _parity([
        _def(add, {
          'modifyPermissions': ['not-a-permission'],
          'roleId': '64',
        }),
      ]);
      expect(outcome.error.toString(), 'Exception: Invalid role permissions');
      outcome = await _parity([
        _def(add, {'modifyPermissions': 'x', 'roleId': '64'}),
      ]);
      expect(outcome.error, isA<Exception>());
    });

    test('service validation errors', () async {
      var outcome = await _parity([
        _def(add, {'createNew': true, 'color': '#ff0000'}),
      ]);
      expect(outcome.error, isA<Exception>());
      outcome = await _parity([
        _def(remove, {'deleteRole': true, 'roleId': ''}),
      ]);
      expect(outcome.error.toString(), 'Exception: Invalid role ID');
    });

    test('a field of the wrong type is wrapped like the executor', () async {
      final outcome = await _parity([
        _def(add, {'modify': true, 'roleId': '64', 'position': 'high'}),
      ]);
      expect(
        outcome.error.toString(),
        startsWith('Exception: Failed to modify role: '),
      );
    });

    test('missing permission, refusal and missing guild', () async {
      var outcome = await _parity([
        _def(add, {'createNew': true, 'name': 'X', 'color': '#ff0000'}),
      ], setup: (g) => g.guild.permissions = 0);
      expect(outcome.error, isA<Exception>());
      outcome = await _parity([
        _def(add, {'createNew': true, 'name': 'X', 'color': '#ff0000'}),
      ], setup: (g) => g.guild.roleManager.fail = true);
      expect(outcome.error.toString(), contains('Discord refused creation'));
      outcome = await _parity([
        _def(add, {'createNew': true, 'name': 'X', 'color': '#ff0000'}),
      ], guild: false);
      expect(
        outcome.error.toString(),
        'Exception: User action requires a guild context',
      );
    });

    test('continue mode records the failure and goes on', () async {
      final outcome = await _parity([
        visualAction(
          add,
          key: 'bad',
          payload: {'createNew': true, 'color': 'nope'},
          error: {'mode': 'continue'},
        ),
        _def(add, {
          'createNew': true,
          'name': 'X',
          'color': '#ff0000',
        }, key: 'ok'),
      ]);
      expect(outcome.results!['bad'], startsWith('Error: Exception: '));
      expect(outcome.results!['ok'], '65');
    });
  });
}
