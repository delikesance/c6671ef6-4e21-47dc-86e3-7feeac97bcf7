import 'package:nyxx/nyxx.dart';
import 'package:bot_creator_shared/engine/discord_entity_fetcher.dart';
import 'package:bot_creator_shared/sandbox/entity_fixture_gateway.dart';
import 'package:bot_creator_shared/sandbox/role_function_cases.dart';
import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:test/test.dart';

void main() {
  test('concurrent callers each receive the fetched role variables', () async {
    final gateway = EntityFixtureGateway(roleEntityFixture);
    final first = {'guild.id': '10'};
    final second = {'guild.id': '10'};
    await Future.wait([
      DiscordEntityFetcher.hydrateEntity(gateway, 'role', 'Cor Branca', first),
      DiscordEntityFetcher.hydrateEntity(gateway, 'role', 'Cor Branca', second),
    ]);
    expect(first['role[Cor Branca].id'], '60');
    expect(second['role[Cor Branca].id'], '60');
    expect(gateway.requests, hasLength(1));
  });
  test('same role name is isolated across guilds and cache entries', () async {
    final gateway = EntityFixtureGateway({
      'guilds': {
        '10': {
          'roles': [
            {'id': '60', 'name': 'Color'},
          ],
        },
        '11': {
          'roles': [
            {'id': '61', 'name': 'Color'},
          ],
        },
      },
    });
    final first = {'guild.id': '10'};
    final second = {'guild.id': '11'};
    final cache = <String, dynamic>{};
    await Future.wait([
      DiscordEntityFetcher.hydrateEntity(
        gateway,
        'role',
        'Color',
        first,
        cache: cache,
      ),
      DiscordEntityFetcher.hydrateEntity(
        gateway,
        'role',
        'Color',
        second,
        cache: cache,
      ),
    ]);
    expect(first['role[Color].id'], '60');
    expect(second['role[Color].id'], '61');
    final repeated = {'guild.id': '11'};
    await DiscordEntityFetcher.hydrateEntity(
      gateway,
      'role',
      'Color',
      repeated,
      cache: cache,
    );
    expect(repeated['role[Color].id'], '61');
    expect(gateway.requests, hasLength(2));
  });
  test('same name on separate bot clients does not share a lookup', () async {
    final firstGateway = EntityFixtureGateway(roleEntityFixture);
    final secondGateway = EntityFixtureGateway({
      'guilds': {
        '10': {
          'roles': [
            {'id': '62', 'name': 'Cor Branca'},
          ],
        },
      },
    });
    final first = {'guild.id': '10'};
    final second = {'guild.id': '10'};
    await Future.wait([
      DiscordEntityFetcher.hydrateEntity(
        firstGateway,
        'role',
        'Cor Branca',
        first,
      ),
      DiscordEntityFetcher.hydrateEntity(
        secondGateway,
        'role',
        'Cor Branca',
        second,
      ),
    ]);
    expect(first['role[Cor Branca].id'], '60');
    expect(second['role[Cor Branca].id'], '62');
  });
  test(
    'duplicate role names fail closed instead of choosing arbitrarily',
    () async {
      final result = await testCommandInSandbox({
        'script': r'$roleID[Duplicate]',
        'entities': {
          'guilds': {
            '10': {
              'roles': [
                {'id': '60', 'name': 'Duplicate'},
                {'id': '61', 'name': 'Duplicate'},
              ],
            },
          },
        },
      });
      expect(result['success'], true, reason: '$result');
      // Ambiguous names resolve to empty output; native BDFD sends no message
      // for an empty response.
      expect(result['responses'], isEmpty);
      expect(result['entity_requests'][0]['operation'], 'roles.list');
    },
  );
  test(
    'missing role fixture is reported instead of passing with empty output',
    () async {
      final result = await testCommandInSandbox({
        'script': r'$roleID[Cor Branca]',
        'entities': {},
      });
      expect(result['success'], false);
      expect(result['error'], contains('Missing sandbox role fixture'));
    },
  );
  test('sandbox fixture gateway denies role writes', () async {
    final gateway = EntityFixtureGateway(roleEntityFixture);
    expect(
      () => gateway.guilds[Snowflake(10)].roles.delete(Snowflake(60)),
      throwsStateError,
    );
  });
}
