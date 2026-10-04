import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:test/test.dart';

Future<Map<String, dynamic>> native(
  String script, [
  Map<String, dynamic> fixtures = const {},
]) => testCommandInSandbox({
  'script': script,
  'bdfdBackend': 'native-v1',
  ...fixtures,
});

void main() {
  test(
    'native sendMessage creates a channel message and optionally returns its ID',
    () async {
      final result = await native(
        r'$title[Main]$var[id;$sendMessage[Separate;yes]]ID=$var[id]',
      );
      expect(result['success'], true, reason: '$result');
      final responses = result['responses'] as List;
      expect(responses, hasLength(2));
      expect(responses[0]['destination'], 'channel');
      expect(responses[0]['payload']['content'], 'Separate');
      expect(responses[0]['payload']['embeds'], isNull);
      expect(responses[1]['destination'], 'response');
      expect(responses[1]['payload']['content'], 'ID=100000');
      expect(responses[1]['payload']['embeds'][0]['title'], 'Main');
      expect(result['bdfdBackend'], 'native-v1');
      expect((result['trace'] as List).last['type'], 'bdfdProgram');
      expect(result['discord_verified'], false);
    },
  );

  test(
    'unknown functions preserve arguments without performing their effects',
    () async {
      const source =
          r'$unknownNativeFunction[$sendMessage[Forbidden];$httpGet[https://example.test]]';
      final result = await native(source);
      expect(result['success'], true, reason: '$result');
      expect(result['responses'], hasLength(1));
      expect(result['responses'][0]['payload']['content'], source);
      expect(result['effects'], isEmpty);
    },
  );

  test(
    'native HTTP consumes fixtures using evaluated arguments and shared eval state',
    () async {
      final result = await native(
        r'$httpAddHeader[X-Test;abc]$eval[$httpPost[https://example.test;data]]$httpStatus|$httpResult[value]',
        {
          'http': [
            {
              'method': 'POST',
              'url': 'https://example.test',
              'expectedRequest': {
                'body': 'data',
                'headers': {'X-Test': 'abc'},
              },
              'status': 201,
              'body': {'value': 'ok'},
            },
          ],
        },
      );
      expect(result['success'], true, reason: '$result');
      expect(result['responses'][0]['payload']['content'], '201|ok');
      expect(result['effects'], hasLength(1));
      expect(result['unused_http_fixtures'], 0);
    },
  );

  test('native HTTP without fixtures fails without network access', () async {
    final result = await native(r'$httpGet[https://example.test]');
    expect(result['success'], false);
    expect(
      result['error'],
      contains('requires an explicit simulation fixture'),
    );
    expect(result['responses'], isEmpty);
    expect(result['diagnostics'][0]['function'], r'$httpGet');
  });

  test(
    'native preparation rejects unsupported known functions before sending',
    () async {
      final result = await native(r'$sendMessage[Forbidden]$wait[1;2]');
      expect(result['success'], false);
      expect(result['responses'], isEmpty);
      expect(result['diagnostics'], isNotEmpty);
    },
  );

  test('native workflow scripts share sandbox transports and state', () async {
    final result = await native(r'$callWorkflow[child]$var[value]', {
      'workflows': [
        {
          'name': 'child',
          'executionMode': 'bdfd_script',
          'bdfdBackend': 'native-v1',
          'bdfdScriptContent':
              r'$httpGet[https://example.test]$var[value;$httpResult]$sendMessage[Child]',
        },
      ],
      'http': [
        {'url': 'https://example.test', 'body': 'fixture'},
      ],
    });
    expect(result['success'], true, reason: '$result');
    expect((result['responses'] as List).map((r) => r['payload']['content']), [
      'Child',
      'fixture',
    ]);
    expect(result['unused_http_fixtures'], 0);
  });

  test('visual blocks can call native scripts with sandbox adapters', () async {
    final result = await testCommandInSandbox({
      'actions': [
        {
          'type': 'runBdfdScript',
          'payload': {
            'bdfdBackend': 'native-v1',
            'scriptContent':
                r'$httpGet[https://example.test]$sendMessage[$httpResult]',
          },
        },
      ],
      'http': [
        {'url': 'https://example.test', 'body': 'fixture'},
      ],
    });
    expect(result['success'], true, reason: '$result');
    expect(result['responses'][0]['payload']['content'], 'fixture');
    expect(result['unused_http_fixtures'], 0);
  });

  test('native guards stop subsequent messages', () async {
    final result = await native(
      r'$onlyIf[false;Denied]$sendMessage[Forbidden]',
    );
    expect(result['success'], true, reason: '$result');
    expect(result['stopped'], true);
    expect(result['responses'], hasLength(1));
    expect(result['responses'][0]['payload']['content'], 'Denied');
  });

  test(
    'native visual workflows retain fixtures through nested native blocks',
    () async {
      final result = await native(r'$callWorkflow[visual]', {
        'workflows': [
          {
            'name': 'visual',
            'actions': [
              {
                'type': 'runBdfdScript',
                'payload': {
                  'bdfdBackend': 'native-v1',
                  'scriptContent':
                      r'$httpGet[https://example.test]$sendMessage[$httpResult]',
                },
              },
            ],
          },
        ],
        'http': [
          {'url': 'https://example.test', 'body': 'nested'},
        ],
      });
      expect(result['success'], true, reason: '$result');
      expect(result['responses'][0]['payload']['content'], 'nested');
      expect(result['unused_http_fixtures'], 0);
    },
  );

  test('native nonterminating loops exhaust the shared step budget', () async {
    final result = await native(r'$while[true]$endwhile');
    expect(result['success'], false);
    expect(result['error'], contains('Execution step limit exceeded'));
    expect(result['responses'], isEmpty);
  });

  for (final semantics in [1, 2]) {
    test(
      'native sandbox preserves user-variable semantics $semantics',
      () async {
        final result = await native(r'$setUserVar[xp;5]$getUserVar[xp]', {
          'bdfdUserVariableSemantics': semantics,
        });
        expect(result['success'], true, reason: '$result');
        final scoped = result['storage_after']['scoped'];
        expect(
          scoped[semantics == 1 ? 'user' : 'guildMember'][semantics == 1
              ? '20'
              : '10:20']['xp'],
          '5',
        );
        expect(result['responses'][0]['payload']['content'], '5');
      },
    );
  }

  test('unknown backend fails before execution', () async {
    final result = await testCommandInSandbox({
      'script': r'$sendMessage[Forbidden]',
      'bdfdBackend': 'future-v99',
    });
    expect(result['success'], false);
    expect(result['error'], contains('Unknown BDFD backend'));
  });
}
