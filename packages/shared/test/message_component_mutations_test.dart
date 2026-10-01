import 'package:bot_creator_shared/actions/edit_message.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

ButtonComponent _button(String id) => ButtonComponent(
  id: 0,
  style: ButtonStyle.primary,
  label: id,
  emoji: null,
  customId: id,
  skuId: null,
  url: null,
  isDisabled: false,
);

SelectMenuComponent _menu() => SelectMenuComponent(
  id: 0,
  type: ComponentType.stringSelect,
  customId: 'choices',
  options: [
    SelectMenuOption(
      label: 'First',
      value: 'first',
      description: null,
      emoji: null,
      isDefault: true,
    ),
  ],
  channelTypes: null,
  placeholder: 'Choose',
  defaultValues: null,
  minValues: 1,
  maxValues: 1,
  isDisabled: false,
  isRequired: null,
);

void main() {
  final components = <Component>[
    ActionRowComponent(
      id: 1,
      components: [_button('approve'), _button('deny')],
    ),
    ActionRowComponent(id: 2, components: [_menu()]),
  ];

  test('removing buttons preserves the select menu and its options', () {
    final result = buildMessageComponentsAfterRemoval(
      components,
      'removeButtons',
      '',
    ).map((component) => component.build()).toList();

    expect(result, hasLength(1));
    final menu = ((result.single['components'] as List).single as Map);
    expect(menu['custom_id'], 'choices');
    expect((menu['options'] as List).single['value'], 'first');
    expect(menu['placeholder'], 'Choose');
  });

  test('removing one component preserves the other button and menu', () {
    final result = buildMessageComponentsAfterRemoval(
      components,
      'removeComponent',
      'approve',
    ).map((component) => component.build()).toList();

    expect(result, hasLength(2));
    expect(
      ((result.first['components'] as List).single as Map)['custom_id'],
      'deny',
    );
    expect(
      ((result.last['components'] as List).single as Map)['custom_id'],
      'choices',
    );
  });
}
