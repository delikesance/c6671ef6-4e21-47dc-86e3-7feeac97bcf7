import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:test/test.dart';

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
}
