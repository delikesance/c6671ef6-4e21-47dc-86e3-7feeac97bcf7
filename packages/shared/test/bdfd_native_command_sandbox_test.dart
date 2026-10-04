import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:test/test.dart';

Future<Map<String, dynamic>> run(String script, {bool fixtures = true}) =>
    testCommandInSandbox({
      'bdfdBackend': 'native-v1',
      'script': script,
      'variables': {
        'bot.id': '999',
        'command.name': r'$sendMessage[unsafe]',
        'command.trigger': '!test',
        'command.folder': '',
      },
      'entities': {
        'guilds': {
          '10': {'name': 'Test'},
        },
        if (fixtures)
          'commands': [
            {'name': '!test'},
            {'name': '/slash'},
          ],
        if (fixtures)
          'global_slash_commands': [
            {'id': '123', 'name': 'slash'},
          ],
      },
    });

void main() {
  test(
    'production registry reads explicit command fixtures and opaque metadata',
    () async {
      final result = await run(
        r'$botCommands[,]|$commandsCount|$slashCommandsCount|$slashID[slash]|$commandName|$commandTrigger|$commandFolder',
      );
      expect(result['success'], true, reason: '$result');
      expect(
        result['results']['output'],
        r'!test,/slash|2|1|123|$sendMessage[unsafe]|!test|',
      );
      expect(result['effects'], isEmpty);
    },
  );
  test('missing command fixtures fail before subsequent effects', () async {
    final result = await run(r'$commandsCount$botLeave[10]', fixtures: false);
    expect(result['success'], false);
    expect(result['effects'], isEmpty);
  });
  test('guild leave mutates fixtures once across eval', () async {
    final result = await run(r'$eval[$botLeave[10]]$botLeave[10]');
    expect(result['success'], false);
    expect(result['effects'], hasLength(1));
    expect(result['effects'].single['type'], 'leaveGuild');
  });
  test('visual workflow native block shares safe command adapter', () async {
    final result = await testCommandInSandbox({
      'bdfdBackend': 'native-v1',
      'script': r'$callWorkflow[child]',
      'entities': {
        'commands': [
          {'name': '!test'},
        ],
      },
      'workflows': [
        {
          'name': 'child',
          'actions': [
            {
              'type': 'runBdfdScript',
              'payload': {
                'scriptContent': r'$commandsCount',
                'bdfdBackend': 'native-v1',
              },
            },
          ],
        },
      ],
    });
    expect(result['success'], true, reason: '$result');
    expect(result['responses'].single['payload']['content'], '1');
  });
}
