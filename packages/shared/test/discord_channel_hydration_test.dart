import 'package:bot_creator_shared/sandbox/channel_function_cases.dart';
import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:test/test.dart';

void main() {
  test(
    'missing channel fixture is reported, not silently interpreted as absent',
    () async {
      final result = await testCommandInSandbox({
        'script': r'$channelExists[31]',
        'entities': {
          'guilds': {
            '10': {'roles': []},
          },
        },
      });
      expect(result['success'], false);
      expect(result['error'], contains('Missing sandbox channel fixture'));
      // A failed native execution sends nothing instead of a fake 'false'.
      expect(result['responses'], isEmpty);
    },
  );

  test('channel lookups read fixtures through the production fetcher', () async {
    final result = await testCommandInSandbox({
      'script':
          r'$channelIDFromName[general]|$findChannel[TICKET]|$serverChannelExists[ticket-123]|$getSlowmode[31]',
      'entities': channelEntityFixture,
    });
    expect(result['success'], true);
    expect(
      (result['responses'] as List).single['payload']['content'],
      '30|31|true|15',
    );
    expect(
      (result['entity_requests'] as List).where(
        (request) => request['operation'] == 'guild.channels',
      ),
      isNotEmpty,
    );
    expect(result['effects'], isEmpty);
    expect(result['storage_before'], result['storage_after']);
  });
}
