import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:test/test.dart';

void main() {
  test(
    'production sandbox combines native guards and text functions across workflows',
    () async {
      final result = await testCommandInSandbox({
        'bdfdBackend': 'native-v1',
        'script':
            r'$onlyForIDs[20;denied]$onlyForChannels[30;denied]'
            r'$onlyForServers[10;denied]$onlyForUsers[Test user;denied]'
            r'$blackListIDs[21;denied]$blackListUsers[Other;denied]'
            r'$blackListServers[11;denied]$ignoreChannels[31;denied]'
            r'$callWorkflow[child]$sort[3;1;asc;-1;,]|$numberSeparator[1234]|'
            r'$isNumber[1.5]|$isBoolean[yes]|$isValidHex[#fff]|'
            r'$unknown[$resetUserVar[missing]]',
        'workflows': [
          {
            'name': 'child',
            'executionMode': 'bdfd_script',
            'bdfdBackend': 'native-v1',
            'bdfdScriptContent':
                r'$onlyIfMessageContains[Hello world;hello;world;denied]'
                r'$byteCount[é]|$linesCount[text]|$cropText[abcdef;3;...]|',
          },
        ],
      });
      expect(result['success'], true, reason: '$result');
      expect(
        (result['responses'] as List)
            .map((response) => response['payload']['content'])
            .join(),
        '2|1|abc...|1,3|1,234|true|true|true|'
        r'$unknown[$resetUserVar[missing]]',
      );
      expect(result['entity_requests'], isEmpty);
      expect(result['effects'], isEmpty);
    },
  );
  test(
    'production sandbox resets declared defaults in actual sandbox storage',
    () async {
      final result = await testCommandInSandbox({
        'bdfdBackend': 'native-v1',
        'script':
            r'$varExists[score]|$resetUserVar[score;20]$getUserVar[score;20;10]|'
            r'$resetServerVar[setting]$getServerVar[setting;10]|'
            r'$resetChannelVar[topic]$getChannelVar[topic;30]',
        'definitions': [
          {'key': 'score', 'scope': 'guildMember', 'defaultValue': 5},
          {'key': 'setting', 'scope': 'guild', 'defaultValue': 'default'},
          {'key': 'topic', 'scope': 'channel', 'defaultValue': 'initial'},
        ],
        'scoped': {
          'guildMember': {
            '10:20': {'score': 99},
          },
          'guild': {
            '10': {'setting': 'changed'},
          },
          'channel': {
            '30': {'topic': 'changed'},
          },
        },
      });
      expect(result['success'], true, reason: '$result');
      expect(result['results']['output'], 'true|5|default|initial');
      expect(result['entity_requests'], isEmpty);
    },
  );
}
