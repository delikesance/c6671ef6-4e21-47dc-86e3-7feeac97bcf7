import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:test/test.dart';

import 'helpers/sandbox_helpers.dart';

void main() {
  group('BdfdCompiler diagnostics (native stage)', () {
    test('known functions compile without diagnostics', () {
      final result = BdfdCompiler().compile(
        r'Hello $username$setUserVar[lastAuthor;$authorID]$getUserVar[lastAuthor]',
      );
      expect(result.hasErrors, isFalse);
      expect(result.diagnostics, isEmpty);
    });

    test('invalid argument counts are reported by the native stage', () {
      final result = BdfdCompiler().compile(r'$isAdmin');
      expect(result.hasErrors, isTrue);
      expect(
        result.diagnostics.single.stage,
        BdfdCompileDiagnosticStage.native,
      );
      expect(result.diagnostics.single.functionName, contains('isAdmin'));
    });

    test('unknown functions are opaque text, not compile errors', () {
      final result = BdfdCompiler().compile(r'$totallyFakeFunction[$authorID]');
      expect(result.hasErrors, isFalse);
    });
  });

  group('core runtime helpers on native-v1', () {
    test('scoped variables and identity placeholders', () async {
      final result = await runScript(
        r'Hello $username$setUserVar[lastAuthor;$authorID]$getUserVar[lastAuthor]',
      );
      expect(contentOf(result), 'Hello Test user20');
    });

    test(
      'message[] and args[] read command words (args skips the trigger word; not in the wiki)',
      () async {
        final result = await runScript(
          r'$reply$message[1]|$message[>]|$args[1]|$message',
          variables: {'message.content': 'a b c'},
        );
        expect(contentOf(result), 'a|c|b|a b c');
        expect(payloads(result).single['replyToMessage'], true);
      },
    );

    test('getTimestampMs returns the current time in milliseconds', () async {
      final before = DateTime.now().toUtc().millisecondsSinceEpoch;
      final result = await runScript(r'$getTimestampMs');
      final value = int.parse(contentOf(result)!);
      expect(value, greaterThanOrEqualTo(before - 1000));
      expect(value, lessThanOrEqualTo(before + 5000));
    });

    test('sub works with getTimestampMs and messageTimestamp', () async {
      final sent = DateTime.now().toUtc().millisecondsSinceEpoch - 25;
      final result = await runScript(
        r'Latency: $sub[$getTimestampMs;$messageTimestamp] ms',
        variables: {'message.timestamp': '$sent'},
      );
      final match = RegExp(
        r'^Latency: (\d+) ms$',
      ).firstMatch(contentOf(result)!);
      expect(match, isNotNull);
      expect(int.parse(match!.group(1)!), greaterThanOrEqualTo(25));
    });

    test('ping reads the bot latency', () async {
      final result = await runScript(
        r'Ping: $ping ms',
        variables: {'bot.ping': '52'},
      );
      expect(contentOf(result), 'Ping: 52 ms');
    });

    test('channelSendMessage targets the given channel', () async {
      final result = await runScript(
        r'$channelSendMessage[123456789012345678;Hello!]',
      );
      expectOk(result);
      expect(payloads(result).single['channelId'], '123456789012345678');
      expect(payloads(result).single['content'], 'Hello!');
    });

    test(
      'mentionedChannels falls back to the current channel on request',
      () async {
        final result = await runScript(
          r'$mentionedChannels[1]|$mentionedChannels[1;yes]',
        );
        expect(contentOf(result), '|30');
      },
    );

    test('unknown functions and unresolved tokens stay literal text', () async {
      final result = await runScript(
        r'$reply$test|$totallyFakeFunction[$authorID]',
      );
      expect(contentOf(result), r'$test|$totallyFakeFunction[$authorID]');
    });
  });
}
