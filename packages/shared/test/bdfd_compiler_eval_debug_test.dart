import 'package:bot_creator_shared/utils/awaited_registration.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:test/test.dart';

import 'helpers/sandbox_helpers.dart';

Map<String, dynamic> _scoped(Map<String, dynamic> result, String scope) =>
    Map<String, dynamic>.from(
      ((result['storage_after'] as Map)['scoped'] as Map)[scope] as Map? ?? {},
    );

void main() {
  group(r'$eval', () {
    test('runs the evaluated BDFD at runtime', () async {
      expect(contentOf(await runScript(r'$eval[$username]')), 'Test user');
      expect(
        contentOf(await runScript(r'$eval[Hello $username]')),
        'Hello Test user',
      );
    });

    test('text before the eval is kept in order', () async {
      final result = await runScript('Hello\n\$eval[\$username]');
      expect(payloads(result).map((p) => p['content']), [
        'Hello\n',
        'Test user',
      ]);
    });

    test('empty argument evaluates to nothing', () async {
      expect(contentOf(await runScript(r'$eval[]x')), 'x');
    });

    test('compiles without diagnostics', () {
      expect(
        BdfdCompiler().compile(r'$eval[$reply$c[]Hello $username]').hasErrors,
        isFalse,
      );
    });
  });

  group('loops', () {
    test(r'$for repeats a channel message with its iteration index', () async {
      final result = await runScript(
        '\$for[3]\n  \$channelSendMessage[\$channelID;iter \$i]\n\$endfor',
      );
      expectOk(result);
      expect(payloads(result).map((p) => p['content']), [
        'iter 0',
        'iter 1',
        'iter 2',
      ]);
    });
  });

  group(r'$awaitFunc', () {
    test('registers the pending function for the author and channel', () async {
      final result = await runScript(
        r'$message$awaitFunc[say]',
        variables: {'message.content': 'hi'},
      );
      expect(contentOf(result), 'hi');
      final registration = Map<String, dynamic>.from(
        _scoped(result, 'user')['20']['await_say'],
      );
      expect(registration['name'], 'say');
      expect(registration['userId'], '20');
      expect(registration['channelId'], '30');
    });

    test('user and channel can be given explicitly', () async {
      final result = await runScript(r'$awaitFunc[Follow Up;21;30]ready');
      expect(contentOf(result), 'ready');
      final registration = _scoped(result, 'user')['21']['await_follow_up'];
      expect(registration['userId'], '21');
      expect(registration['channelId'], '30');
    });

    test('every execution produces a distinct registration snapshot', () async {
      const script = r'$message$awaitFunc[say]';
      Future<String> snapshot() async {
        final result = await runScript(script);
        return awaitedRegistrationSnapshot(
          _scoped(result, 'user')['20']['await_say'],
        );
      }

      final first = await snapshot();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(
        await snapshot(),
        isNot(first),
        reason: 're-arming an awaited function must be detectable',
      );
    });

    test('an empty name is rejected', () async {
      final result = await runScript(r'$awaitFunc[]');
      expect(result['success'], false);
    });
  });

  group('scoped user variables', () {
    Future<Map<String, dynamic>> member(String script) async {
      final result = await runScript(script);
      expectOk(result);
      return _scoped(result, 'guildMember');
    }

    test('setUserVar uses the author and current guild by default', () async {
      expect(await member(r'$setUserVar[money;100]'), {
        '10:20': {'money': '100'},
      });
    });

    test('setUserVar accepts a user id and a guild id', () async {
      expect(await member(r'$setUserVar[money;100;12345]'), {
        '10:12345': {'money': '100'},
      });
      expect(await member(r'$setUserVar[money;100;12345;67890]'), {
        '67890:12345': {'money': '100'},
      });
      expect(await member(r'$setUserVar[money;100;;67890]'), {
        '67890:20': {'money': '100'},
      });
    });

    test('setGuildMemberVar takes the member and the guild', () async {
      expect(await member(r'$setGuildMemberVar[money;100;12345;67890]'), {
        '67890:12345': {'money': '100'},
      });
    });
  });
}
