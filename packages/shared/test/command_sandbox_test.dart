import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:bot_creator_shared/sandbox/channel_function_cases.dart';
import 'package:bot_creator_shared/utils/bdfd_runtime_reference.dart';
import 'package:test/test.dart';

void main() {
  test(
    'randomString uses runtime length and alphabet with bounded output',
    () async {
      final result = await testCommandInSandbox({
        'script':
            r'$randomString[((opts.length));((opts.alphabet))]|$charCount[$randomString[2000;x]]',
        'options': {'length': 4, 'alphabet': 'x'},
      });
      expect(result['success'], true, reason: '$result');
      expect(result['responses'][0]['payload']['content'], 'xxxx|1000');
    },
  );
  test(
    'randomString default output contains the requested number of alphanumerics',
    () async {
      final result = await testCommandInSandbox({
        'script': r'$randomString[32]',
      });
      expect(result['success'], true, reason: '$result');
      expect(
        result['responses'][0]['payload']['content'],
        matches(RegExp(r'^[A-Za-z0-9]{32}$')),
      );
    },
  );
  for (final sample in [
    (
      r'$textSplit[((opts.text));,]$splitText[2]|$editSplitText[2;changed]$splitText[2]',
      'b|changed',
    ),
    (
      r'$textSplit[((opts.text));,]$editSplitText[0;bad]$removeSplitTextElement[9]$joinSplitText[-]|$splitText[0]|$getTextSplitIndex[missing]',
      'a-b-c||-1',
    ),
    (
      r'$textSplit[((opts.text));,]$if[((opts.apply))==true]$textSplit[x,y;,]$endif$joinSplitText[-]',
      'a-b-c',
    ),
    (
      r'$textSplit[((opts.text));,]$if[((opts.apply))==false]$editSplitText[2;x]$endif$joinSplitText[-]',
      'a-x-c',
    ),
    (
      r'$textSplit[((opts.text));,]$for[((opts.count))]$removeSplitTextElement[1]$endfor$joinSplitText[-]',
      'c',
    ),
  ]) {
    test('runtime textSplit state: ${sample.$2}', () async {
      final result = await testCommandInSandbox({
        'script': sample.$1,
        'options': {'text': 'a,b,c', 'apply': false, 'count': 2},
      });
      expect(result['success'], true, reason: '$result');
      expect(result['responses'][0]['payload']['content'], sample.$2);
    });
  }
  test('textSplit state is fresh for each command execution', () async {
    await testCommandInSandbox({
      'script': r'$textSplit[a,b;,]$getTextSplitLength',
    });
    final result = await testCommandInSandbox({
      'script': r'$getTextSplitLength',
    });
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
        final result = await testCommandInSandbox({
          'script':
              r'$if[$checkContains[((opts.text));((opts.needle))]==true]matched$else rejected$endif',
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
      final result = await testCommandInSandbox({
        'script': r'$var[x;$sum[((opts.amount));2]]$reply$c[]XP ($var[x])',
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
    final result = await testCommandInSandbox({
      'script': bdfdXpAddCommand,
      'scoped': fixture,
      'options': {
        'membre': {'id': '21'},
        'montant': 100,
      },
      'variables': {'member.isAdmin': true},
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
    final result = await testCommandInSandbox({
      'script': r'$eval[$httpGet[https://example.com]]',
    });
    expect(result['success'], false);
    expect(result['error'], contains('simulation fixture'));
  });

  test(
    'HTTP simulation uses real request serialization and response extraction',
    () async {
      final result = await testCommandInSandbox({
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
      final result = await testCommandInSandbox({
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
      final result = await testCommandInSandbox({
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
      final result = await testCommandInSandbox({
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
    final result = await testCommandInSandbox({
      'script': bdfdXpAddCommand,
      'options': {
        'membre': {'id': '21'},
        'montant': 100,
      },
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
    final result = await testCommandInSandbox({'script': r'$debug$c[]test'});
    expect(result['success'], true, reason: '$result');
  });
  test('kills nonterminating action navigation', () async {
    final result = await testCommandInSandbox({
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
        r'$jsonParse[((opts.value))]$jsonClear$jsonStringify',
      ]) {
        final result = await testCommandInSandbox({
          'script': script,
          'options': {'value': '{"old":1}'},
        });
        expect(result['success'], true, reason: '$result');
        expect(result['responses'][0]['payload']['content'], '{}');
      }
    },
  );
  test('reports compile errors without claiming runtime success', () async {
    final result = await testCommandInSandbox({'script': r'$if[1==1]'});
    expect(result['success'], false);
    expect(result['diagnostics'], isNotEmpty);
  });
  test('role writes require explicit local fixtures', () async {
    final result = await testCommandInSandbox({'script': r'$giveRole[60]'});
    expect(result['success'], false);
    expect(result['error'], contains('roles and members fixtures'));
    expect(result['discord_verified'], false);
  });
  test('role creation also requires explicit local fixtures', () async {
    final result = await testCommandInSandbox({
      'script': r'$createRole[Test;#00FF00]',
    });
    expect(result['success'], false);
    expect(result['error'], contains('guild roles fixtures'));
    expect(result['discord_verified'], false);
  });
  test('slowmode rejects durations above Discord limit', () async {
    final result = await testCommandInSandbox({
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
      final result = await testCommandInSandbox({
        'script':
            r'$onlyPerms[ManageMessages;Refusé]$var[target;((opts.user.id))]$var[count;$getGuildMemberVar[warns;$var[target]]]$setGuildMemberVar[warns;$sum[$var[count];1];$var[target]]Averti $var[target] count=$var[count]',
        'options': {'user': '25'},
        'context': {
          'permissions': ['MANAGE_MESSAGES'],
        },
        'definitions': {
          'warns': {'scope': 'guildMember', 'defaultValue': '0'},
        },
        'variables': {'initialCount': '0'},
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
    final result = await testCommandInSandbox({
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
