import 'package:bot_creator_shared/types/component.dart';
import 'package:bot_creator_shared/utils/component_workflow_bindings.dart';
import 'package:bot_creator_shared/utils/interaction_listener_registry.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:test/test.dart';

void main() {
  test('dynamic role variable survives until a later menu click', () {
    final variables = {
      'temp.roleId': '1550734454602080256',
      'author.id': 'creator',
    };
    final definition = ComponentV2Definition.fromJson({
      'components': [
        {
          'type': 'actionRow',
          'components': [
            {
              'type': 'stringSelect',
              'customId': 'dynamic-colors',
              'options': [
                {'label': 'Cor Preta', 'value': 'cor preta'},
              ],
              'actions': [
                {
                  'type': 'ifBlock',
                  'payload': {
                    'condition.variable':
                        '((interaction.dynamic-colors.value))',
                    'condition.operator': 'equals',
                    'condition.value': 'cor preta',
                    'thenActions': [
                      {
                        'type': 'addRole',
                        'payload': {
                          'roleId': '((temp.roleId))',
                          'userId': '((author.id))',
                        },
                      },
                    ],
                  },
                },
              ],
            },
          ],
        },
      ],
    });
    registerComponentWorkflowBindings(
      definition: definition,
      resolve: (s) => resolveTemplatePlaceholders(s, variables),
      botId: 'test',
      messageId: '123',
    );
    variables['temp.roleId'] = 'changed-after-send';
    final registry = InteractionListenerRegistry.instance;
    final entry = registry.getMatching(
      'dynamic-colors',
      const ListenerMatchRequest(
        botId: 'test',
        type: 'select',
        messageId: '123',
      ),
    )!;
    expect(entry.initialContext, {'temp.roleId': '1550734454602080256'});
    final clickedContext = {'author.id': 'clicker', ...entry.initialContext};
    final rolePayload =
        entry.inlineActions!.single.payload['thenActions'][0]['payload'];
    expect(
      resolveTemplatePlaceholders(rolePayload['roleId'], clickedContext),
      '1550734454602080256',
    );
    expect(
      resolveTemplatePlaceholders(rolePayload['userId'], clickedContext),
      'clicker',
    );
    registry.removeEntry('dynamic-colors', entry);
  });
  test('temporary values created inside the callback remain unresolved', () {
    final captured = captureComponentTemporaryContext([
      {
        'type': 'addRole',
        'payload': {'roleId': '((temp.future))', 'userId': '((author.id))'},
      },
    ], (s) => resolveTemplatePlaceholders(s, {}));
    expect(captured, isEmpty);
  });
}
