import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:bot_creator_shared/sandbox/channel_function_cases.dart';
import 'package:bot_creator_shared/utils/bdfd_runtime_reference.dart';
import 'package:test/test.dart';

/// Slash options are read through `$message[name]`, which needs a slash
/// interaction; every case here runs as one unless it overrides the flag.
Future<Map<String, dynamic>> run(Map<String, dynamic> input) =>
    testCommandInSandbox({
      ...input,
      'variables': {
        'interaction.isSlash': 'true',
        ...(input['variables'] as Map? ?? const {}),
      },
    });

/// Guild 10 where the invoking author (member 20) holds [permissions] through
/// one role; the bot is member 98. Permission guards read these fixtures.
Map<String, dynamic> guildWithAuthorPermissions(String permissions) => {
  'guilds': {
    '10': {
      'owner_id': '99',
      'roles': [
        {'id': '10', 'name': '@everyone', 'position': 0, 'permissions': '0'},
        {
          'id': '70',
          'name': 'Staff',
          'position': 1,
          'permissions': permissions,
        },
      ],
      'members': {
        '20': {
          'roles': ['70'],
        },
        '98': {'roles': <String>[]},
        '99': {'roles': <String>[]},
      },
      'channels': [
        {'id': '30', 'name': 'general', 'type': 'text'},
      ],
    },
  },
};

void main() {
  test(
    'randomString uses runtime length and alphabet with bounded output',
    () async {
      final result = await run({
        'script': r'$randomString[$message[length]]',
        'variables': {'interaction.isSlash': 'true'},
        'options': {'length': 4},
      });
      expect(result['success'], true, reason: '$result');
      expect(
        result['responses'][0]['payload']['content'],
        matches(RegExp(r'^[A-Za-z0-9]{4}$')),
      );
      // Wiki: $randomString[Length] accepts at most 10 characters.
      final tooLong = await run({
        'script': r'$randomString[$message[length]]',
        'variables': {'interaction.isSlash': 'true'},
        'options': {'length': 2000},
      });
      expect(tooLong['success'], false, reason: '$tooLong');
      expect(tooLong['error'], contains('1 to 10'));
    },
  );
  test(
    'randomString default output contains the requested number of alphanumerics',
    () async {
      final result = await run({'script': r'$randomString[10]'});
      expect(result['success'], true, reason: '$result');
      expect(
        result['responses'][0]['payload']['content'],
        matches(RegExp(r'^[A-Za-z0-9]{10}$')),
      );
    },
  );
  for (final sample in [
    (
      r'$textSplit[$message[text];,]$splitText[2]|$editSplitText[2;changed]$splitText[2]',
      'b|changed',
    ),
    (
      r'$textSplit[$message[text];,]$editSplitText[1;A]$removeSplitTextElement[3]$joinSplitText[-]|$splitText[1]|$getTextSplitIndex[missing]',
      'A-b|A|-1',
    ),
    (
      r'$textSplit[$message[text];,]$if[$message[apply]==true]$textSplit[x,y;,]$endif$joinSplitText[-]',
      'a-b-c',
    ),
    (
      r'$textSplit[$message[text];,]$if[$message[apply]==false]$editSplitText[2;x]$endif$joinSplitText[-]',
      'a-x-c',
    ),
    (
      r'$textSplit[$message[text];,]$for[$message[count]]$removeSplitTextElement[1]$endfor$joinSplitText[-]',
      'c',
    ),
  ]) {
    test('runtime textSplit state: ${sample.$2}', () async {
      final result = await run({
        'script': sample.$1,
        'options': {'text': 'a,b,c', 'apply': false, 'count': 2},
      });
      expect(result['success'], true, reason: '$result');
      expect(result['responses'][0]['payload']['content'], sample.$2);
    });
  }
  test('editSplitText rejects an index outside the split text', () async {
    final result = await run({
      'script': r'$textSplit[a,b,c;,]$editSplitText[9;x]',
    });
    expect(result['success'], false, reason: '$result');
    expect(result['error'], contains(r'$editSplitText'));
  });
  test('textSplit state is fresh for each command execution', () async {
    await run({'script': r'$textSplit[a,b;,]$getTextSplitLength'});
    final result = await run({'script': r'$getTextSplitLength'});
    expect(result['success'], true, reason: '$result');
    expect(result['responses'][0]['payload']['content'], '0');
  });
  for (final sample in [
    ('Hello World', 'World', 'matched'),
    ('Hello World', 'world', ' rejected'),
    ('a;b', ';', 'matched'),
    ('', '', 'matched'),
  ]) {
    test(
      'checkContains routes runtime input ${sample.$1}/${sample.$2}',
      () async {
        final result = await run({
          'script':
              r'$if[$checkContains[$message[text];$message[needle]]==true]matched$else rejected$endif',
          'options': {'text': sample.$1, 'needle': sample.$2},
        });
        expect(result['success'], true, reason: '$result');
        expect(result['responses'][0]['payload']['content'], sample.$3);
      },
    );
  }
  test(
    'uses production executors and simulates responses without Discord',
    () async {
      final result = await run({
        'script': r'$var[x;$sum[$message[amount];2]]$reply$c[]XP ($var[x])',
        'options': {'amount': 100},
      });
      expect(result['success'], true, reason: '$result');
      expect(
        (result['responses'] as List).single['payload']['content'],
        'XP (102)',
      );
      expect(result['trace'], isNotEmpty);
    },
  );
  test('isolates caller fixtures and real bot storage', () async {
    final fixture = {
      'guildMember': {
        '10:21': {'xp': 156, 'level': 2},
      },
    };
    final result = await run({
      'script': bdfdXpAddCommand,
      'scoped': fixture,
      'options': {
        'membre': {'id': '21'},
        'montant': 100,
      },
      'entities': guildWithAuthorPermissions('8'),
      'variables': {'bot.id': '98'},
    });
    expect(result['success'], true, reason: '$result');
    expect(
      result['storage_after']['scoped']['guildMember']['10:21']['xp'],
      '31',
    );
    expect(fixture['guildMember']!['10:21']!['xp'], 156);
    expect(
      result['storage_before']['scoped']['guildMember']['10:21']['xp'],
      156,
    );
  });
  test('rejects external effects even in nested eval', () async {
    final result = await run({
      'script': r'$eval[$httpGet[https://example.com]]',
    });
    expect(result['success'], false);
    expect(result['error'], contains('simulation fixture'));
  });

  test(
    'HTTP simulation uses real request serialization and response extraction',
    () async {
      final result = await run({
        'actions': [
          {
            'type': 'httpRequest',
            'key': 'fetch',
            'payload': {
              'url': 'https://sandbox.invalid/users',
              'method': 'POST',
              'bodyMode': 'json',
              'bodyJson': {'name': '((opts.name))'},
              'extractJsonPath': r'$.user.id',
              'saveBodyToGlobalVar': 'response',
            },
          },
          {
            'type': 'respondWithMessage',
            'payload': {'content': '((fetch))'},
          },
        ],
        'options': {'name': 'Alice'},
        'http': [
          {
            'method': 'POST',
            'url': 'https://sandbox.invalid/users',
            'status': 201,
            'body': {
              'user': {'id': 42},
            },
            'expectedRequest': {
              'body': '{"name":"Alice"}',
              'headers': {'content-type': 'application/json'},
            },
          },
        ],
      });
      expect(result['success'], true, reason: '$result');
      expect(result['responses'][0]['payload']['content'], '42');
      expect(result['variables']['http.status'], '201');
      expect(
        result['storage_after']['global']['response'],
        '{"user":{"id":42}}',
      );
      expect(result['effects'][0]['simulated'], true);
      expect(result['unused_http_fixtures'], 0);
    },
  );

  test(
    'HTTP fixtures cannot authorize other URLs and are consumed once',
    () async {
      final result = await run({
        'script':
            r'$httpGet[https://sandbox.invalid/test]$eval[$httpGet[https://sandbox.invalid/test]]',
        'http': [
          {'url': 'https://sandbox.invalid/test', 'body': 'first'},
        ],
      });
      expect(result['success'], false);
      expect(result['error'], contains('simulation fixture'));
      expect(result['effects'], hasLength(1));
    },
  );

  test(
    'HTTP fixture checks detect request mismatches instead of faking success',
    () async {
      final result = await run({
        'script': r'$httpPost[https://sandbox.invalid/test;wrong]',
        'http': [
          {
            'method': 'POST',
            'url': 'https://sandbox.invalid/test',
            'expectedRequest': {'body': 'right'},
            'body': 'ok',
          },
        ],
      });
      expect(result['success'], false);
      expect(result['error'], contains('did not match'));
    },
  );

  test(
    'HEAD blocks can use HTTP fixtures without inventing a BDFD function',
    () async {
      final result = await run({
        'actions': [
          {
            'type': 'httpRequest',
            'payload': {
              'method': 'HEAD',
              'url': 'https://sandbox.invalid/test',
            },
          },
        ],
        'http': [
          {
            'method': 'HEAD',
            'url': 'https://sandbox.invalid/test',
            'status': 204,
          },
        ],
      });
      expect(result['success'], true, reason: '$result');
      expect(result['variables']['http.status'], '204');
    },
  );
  test('guard failure stops command before storage writes', () async {
    final result = await run({
      'script': bdfdXpAddCommand,
      'options': {
        'membre': {'id': '21'},
        'montant': 100,
      },
      'entities': guildWithAuthorPermissions('0'),
      'variables': {'bot.id': '98'},
    });
    expect(result['success'], true, reason: '$result');
    expect(result['stopped'], true);
    expect(result['storage_after']['scoped']['guildMember'], isNull);
    expect(
      (result['responses'] as List).single['payload']['content'],
      contains('administrateurs'),
    );
  });
  test('debug never bypasses the execution boundary', () async {
    final result = await run({'script': r'$debug[on]$c[]test'});
    expect(result['success'], true, reason: '$result');
  });
  test('kills nonterminating action navigation', () async {
    final result = await run({
      'actions': [
        {
          'type': 'jumpToAction',
          'key': 'repeat',
          'payload': {'targetKey': '1'},
        },
      ],
    });
    expect(result['success'], false, reason: '$result');
    expect(result['error'], contains('budget'));
  });
  test(
    'JSON clear resets literal and runtime contexts to an empty object',
    () async {
      for (final script in [
        r'$jsonParse[{"old":1}]$jsonClear$jsonStringify',
        r'$jsonParse[$message[value]]$jsonClear$jsonStringify',
      ]) {
        final result = await run({
          'script': script,
          'options': {'value': '{"old":1}'},
        });
        expect(result['success'], true, reason: '$result');
        expect(result['responses'][0]['payload']['content'], '{}');
      }
    },
  );
  test('reports compile errors without claiming runtime success', () async {
    final result = await run({'script': r'$if[1==1]'});
    expect(result['success'], false);
    expect(result['diagnostics'], isNotEmpty);
  });
  test('role writes require explicit local fixtures', () async {
    final result = await run({'script': r'$giveRole[20;60]'});
    expect(result['success'], false);
    expect(result['error'], contains('roles and members fixtures'));
    expect(result['discord_verified'], false);
  });
  test('role creation also requires explicit local fixtures', () async {
    final result = await run({'script': r'$createRole[Test;#00FF00]'});
    expect(result['success'], false);
    expect(result['error'], contains('roles and members fixtures'));
    expect(result['discord_verified'], false);
  });
  test('slowmode rejects durations above Discord limit', () async {
    final result = await run({
      'script': r'$slowmode[30;7h]',
      'entities': channelEntityFixture,
    });
    expect(result['success'], false);
    expect(result['error'], contains('between 0 and 6 hours'));
    expect(result['effects'], isEmpty);
  });
  test(
    'flexible scenario fixtures: definitions Map, context permissions, option id and temp variables',
    () async {
      final result = await run({
        'script':
            r'$onlyPerms[ManageMessages;Refusé]$var[target;$message[user]]$var[count;$getGuildMemberVar[warns;$var[target]]]$setGuildMemberVar[warns;$sum[$var[count];1];$var[target]]Averti $var[target] count=$var[count]',
        'options': {'user': '25'},
        'entities': guildWithAuthorPermissions('${1 << 13}'),
        'definitions': {
          'warns': {'scope': 'guildMember', 'defaultValue': '0'},
        },
        'variables': {'initialCount': '0', 'bot.id': '98'},
      });
      expect(result['success'], true, reason: '$result');
      expect(result['responses'][0]['payload']['content'], 'Averti 25 count=0');
      expect(
        result['storage_after']['scoped']['guildMember']['10:25']['warns'],
        '1',
      );
    },
  );
  test('flexible scenario fixtures: scoped list format and temp map', () async {
    final result = await run({
      'script': r'$var[name] is at $getGuildMemberVar[warns;25]',
      'temp': {'name': 'Alice'},
      'scoped': [
        {
          'scope': 'guildMember',
          'context': '10:25',
          'key': 'warns',
          'value': '3',
        },
      ],
    });
    expect(result['success'], true, reason: '$result');
    expect(result['responses'][0]['payload']['content'], 'Alice is at 3');
  });
}
