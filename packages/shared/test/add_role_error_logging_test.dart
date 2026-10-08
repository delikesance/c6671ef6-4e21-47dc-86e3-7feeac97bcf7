import 'package:bot_creator_shared/actions/handler.dart';
import 'package:bot_creator_shared/engine/bdfd/visual/action_translator.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

import 'helpers/fake_role_gateway.dart';
import 'helpers/variables_test_helpers.dart';

void main() {
  test('a failing addRole in continue mode is logged, not swallowed', () async {
    final gateway = FakeGateway()
      ..guild.permissions = Permissions.manageRoles.value;
    final logs = <String>[];
    final values = <String, String>{};
    final results = await handleActions(
      gateway,
      null,
      // No userId: the Studio's old starter payload.
      actions: [
        Action(type: BotCreatorActionType.addRole, payload: {'roleId': '64'})
          ..error['mode'] = 'continue',
      ],
      store: MemoryBotDataStore(),
      botId: 'bot',
      variables: values,
      fallbackGuildId: Snowflake(10),
      resolveTemplate: (v) => resolveTemplatePlaceholders(v, values),
      onLog: logs.add,
      actionTranslator: const ActionTranslator.none(),
    );
    expect(results.values.single, startsWith('Error:'));
    expect(gateway.guild.memberManager.roleChanges, isEmpty);
    expect(
      logs.single,
      contains('Action addRole failed: Exception: Missing or invalid userId'),
    );
  });
}
