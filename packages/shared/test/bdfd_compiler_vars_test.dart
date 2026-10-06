import 'package:test/test.dart';

import 'helpers/sandbox_helpers.dart';

void main() {
  group(r'temporary variables via $var', () {
    test('set and retrieve a temporary variable', () async {
      final result = await runScript(r'$var[name;World]Hello $var[name]!');
      expect(contentOf(result), 'Hello World!');
    });

    test('overwrite a temporary variable', () async {
      final result = await runScript(
        r'$var[x;first]$var[x;second]Value: $var[x]',
      );
      expect(contentOf(result), 'Value: second');
    });

    test('multiple independent temporary variables', () async {
      expect(
        contentOf(await runScript(r'$var[a;1]$var[b;2]$var[a]+$var[b]')),
        '1+2',
      );
    });

    test('an unset variable reads as empty text', () async {
      expect(contentOf(await runScript(r'Value: $var[unknown]')), 'Value: ');
    });

    test('setting a variable produces no visible output', () async {
      final result = await runScript(r'$var[x;hello]');
      expectOk(result);
      expect(payloads(result), isEmpty);
      expect(contentOf(await runScript(r'$var[x;hello]$var[x]')), 'hello');
    });

    test('a value can come from an inline function', () async {
      expect(
        contentOf(
          await runScript(
            r'$var[upper;$toUpperCase[hello]]Result: $var[upper]',
          ),
        ),
        'Result: HELLO',
      );
    });

    test('runtime math and temp vars persist through branches', () async {
      final result = await runScript(
        r'$if[$username!=]'
        '\n'
        r' $enabledecimals[yes]'
        '\n'
        r' $var[toadd;$multi[$charcount[$message];0.5]]'
        '\n'
        r' $channelSendMessage[$channelID;$message, charcount $charcount[$message], after mult $var[toadd]]'
        '\n'
        r' $if[$var[toadd]>15]'
        '\n'
        r'  $channelSendMessage[$channelID;over 15, clamped]'
        '\n'
        r'  $var[toadd;15]'
        '\n'
        r' $endif'
        '\n'
        r' $channelSendMessage[$channelID;you have been given $var[toadd] xp]'
        '\n'
        r' $setUserVar[xp;$calculate[$getUserVar[xp]+$var[toadd]]]'
        '\n'
        r' $channelSendMessage[$channelID;new xp $getUserVar[xp]]'
        '\n'
        r'$endif',
        variables: {'message.content': 'bzbd'},
        extra: {
          'definitions': [
            {'key': 'xp', 'scope': 'guildMember', 'defaultValue': '0'},
          ],
        },
      );
      expectOk(result);
      expect(payloads(result).map((p) => p['content']), [
        'bzbd, charcount 4, after mult 2',
        'you have been given 2 xp',
        'new xp 2',
      ]);
    });

    test('the clamp branch caps large values', () async {
      final result = await runScript(
        r'$enabledecimals[yes]$var[toadd;$multi[$charcount[$message];0.5]]'
        r'$if[$var[toadd]>15]$var[toadd;15]$endif$var[toadd]',
        variables: {'message.content': 'x' * 60},
      );
      expect(contentOf(result), '15');
    });

    test('uppercase of runtime text', () async {
      expect(
        contentOf(await runScript(r'$reply$toUpperCase[$username]')),
        'TEST USER',
      );
    });
  });
}
