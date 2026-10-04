import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:bot_creator_shared/actions/kick_user.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

class _NoDiscord implements NyxxGateway {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected Discord access');
}

void main() {
  final compiler = BdfdCompiler();

  test('ban variants preserve reason and explicit or message user ID', () {
    final simple = compiler.compile(r'$ban');
    expect(simple.hasErrors, false);
    expect(simple.actions.single.type, BotCreatorActionType.banUser);
    expect(simple.actions.single.payload['userId'], '((message.mentions[0]))');

    final withReason = compiler.compile(r'$ban[Spam]');
    expect(withReason.hasErrors, false);
    expect(withReason.actions.single.payload['reason'], 'Spam');

    final byMessage = compiler.compile(r'$banID');
    expect(byMessage.hasErrors, false);
    expect(byMessage.actions.single.payload['userId'], '((message.args.last))');

    final byId = compiler.compile(r'$banID[Spam;123]');
    expect(byId.hasErrors, false);
    expect(byId.actions.single.payload['userId'], '123');
    expect(byId.actions.single.payload['reason'], 'Spam');
  });

  test('kick and unban ID variants use the documented targets', () {
    final selfKick = compiler.compile(r'$kick');
    expect(selfKick.hasErrors, false);
    expect(selfKick.actions.single.payload['userId'], '((author.id))');

    final targetKick = compiler.compile(r'$kick[123;Raid]');
    expect(targetKick.hasErrors, false);
    expect(targetKick.actions.single.type, BotCreatorActionType.kickUser);
    expect(targetKick.actions.single.payload['userId'], '123');
    expect(targetKick.actions.single.payload['reason'], 'Raid');

    final byMessage = compiler.compile(r'$unbanID');
    expect(byMessage.hasErrors, false);
    expect(byMessage.actions.single.payload['userId'], '((message.args.last))');

    final byId = compiler.compile(r'$unbanID[123]');
    expect(byId.hasErrors, false);
    expect(byId.actions.single.payload['userId'], '123');
  });

  test('explicit empty kick target never falls back to the author', () async {
    for (final source in [r'$kick[]', r'$kick[;Raid]', r'$kick[   ;Raid]']) {
      final result = compiler.compile(source);
      expect(result.hasErrors, false);
      final outcome = await kickUserAction(
        _NoDiscord(),
        guildId: Snowflake(10),
        payload: result.actions.single.payload,
        resolve: (input) => resolveTemplatePlaceholders(input, {
          'author.id': '999', // The caller could be the guild owner.
        }),
      );
      expect(outcome['error'], 'Missing or invalid userId', reason: source);
    }
  });

  test('missing runtime kick target fails without using the caller', () async {
    final result = compiler.compile(r'$kick[$mentioned[1];Raid]');
    final outcome = await kickUserAction(
      _NoDiscord(),
      guildId: Snowflake(10),
      payload: result.actions.single.payload,
      resolve: (input) =>
          resolveTemplatePlaceholders(input, {'author.id': '999'}),
    );
    expect(outcome['error'], 'Missing or invalid userId');
  });
}
