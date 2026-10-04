import 'package:bot_creator_shared/engine/bdfd/component_functions.dart';
import 'package:bot_creator_shared/engine/bdfd/interaction_functions.dart';
import 'package:bot_creator_shared/engine/bdfd/message_functions.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_component_service.dart';
import 'package:bot_creator_shared/services/bot_message_service.dart';
import 'package:bot_creator_shared/events/event_contexts.dart';
import 'package:bot_creator_shared/utils/interaction_ack_state.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

class _Messages implements BotMessageService {
  final sent = <BotMessageRequest>[];
  @override
  Future<BotMessageResult> send(
    BotMessageRequest r, {
    required CommandExecutionBudget budget,
    required Map<String, String> variables,
  }) async {
    sent.add(r);
    return const BotMessageResult(messageId: '99', channelId: '20');
  }
}

class _Components implements BotComponentService {
  final reads = <String>[],
      writes = <String>[],
      modals = <Map<String, dynamic>>[],
      payloads = <List<Map<String, dynamic>>>[];
  bool fail = false;
  @override
  Future<List<Map<String, dynamic>>> readComponents(
    String id, {
    required CommandExecutionBudget budget,
  }) async {
    reads.add(id);
    return [];
  }

  @override
  Future<void> editComponents(
    String id,
    List<Map<String, dynamic>> rows, {
    required CommandExecutionBudget budget,
  }) async {
    writes.add(id);
    payloads.add(copyComponentRows(rows));
    if (fail) throw StateError('failed');
  }

  @override
  Future<void> sendModal(
    Map<String, dynamic> modal, {
    required CommandExecutionBudget budget,
  }) async {
    modals.add(modal);
    if (fail) throw StateError('failed');
  }
}

class _Harness {
  final messages = _Messages(), components = _Components();
  late final output = BdfdMessageOutput(messages, components: components);
  late final context = BdfdContext(output: output);
  late final runtime = BdfdRuntime(
    functions: {
      ...bdfdComponentFunctions(components),
      ...bdfdInteractionFunctions(),
    },
  );
  Future<String> run(String s) => runtime.execute(s, context: context);
  List<Map<String, dynamic>> get rows =>
      (messages.sent.single.payload['components']['components'] as List)
          .cast<Map<String, dynamic>>();
}

class _Data {
  _Data(this.type, this.values);
  final ComponentType type;
  final List<String> values;
  String get customId => 'menu';
}

class _Interaction implements Interaction<dynamic> {
  _Interaction(this.data);
  @override
  final dynamic data;
  @override
  InteractionType get type => InteractionType.messageComponent;
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _ModalInteraction implements ApplicationCommandInteraction {
  ModalBuilder? sent;
  @override
  Future<void> respondModal(ModalBuilder b) async {
    sent = b;
  }

  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _Gateway implements NyxxGateway {
  @override
  dynamic noSuchMethod(Invocation i) => throw StateError('Unexpected SDK');
}

void main() {
  test(
    'buttons pack rows and preserve SDK emoji, link and disabled payloads',
    () async {
      final h = _Harness();
      await h.run(
        r'Hello$addButton[no;a;Go;primary;yes;😀]$addButton[no;https://example.com;Visit;link]$addButton[yes;b;Last;danger]',
      );
      expect(h.rows.length, 2);
      final sdk = nativeComponentBuilder(h.rows.first).build();
      final children = sdk['components'] as List;
      expect(children.length, 2);
      expect(children[0]['custom_id'], 'a');
      expect(children[0]['disabled'], true);
      expect(children[0]['emoji'], {'name': '😀'});
      expect(children[1]['url'], 'https://example.com');
      expect(h.output.componentState.rows, isEmpty);
    },
  );
  test('component-only response and labels remain opaque data', () async {
    final h = _Harness();
    await h.run(r'$addButton[no;a;$unknown[$var[x;bad]];secondary]');
    expect(h.messages.sent.single.payload['content'], '');
    expect(h.rows.single['components'][0]['label'], r'$unknown[$var[x;bad]]');
    expect(h.context.temporaryVariables, isEmpty);
  });
  test('select options edits produce real SDK selection bounds', () async {
    final h = _Harness();
    await h.run(
      r'$newSelectMenu[m;0;2;Pick]$addSelectMenuOption[m;One;one;Desc;yes;<:smile:123>]$addSelectMenuOption[m;Two;two;]$editSelectMenuOption[m;Updated;two;;no;😀]',
    );
    final sdk =
        (nativeComponentBuilder(h.rows.single).build()['components'] as List)
            .single;
    expect(sdk['type'], 3);
    expect(sdk['min_values'], 0);
    expect(sdk['max_values'], 2);
    expect(sdk['options'][0]['emoji'], {
      'name': 'smile',
      'id': '123',
      'animated': false,
    });
    expect(sdk['options'][1]['label'], 'Updated');
  });
  test(
    'explicit selects stage until complete with one read and one edit',
    () async {
      final h = _Harness();
      await h.run(
        r'$newSelectMenu[m;1;1;Pick;88]$addSelectMenuOption[m;One;one;;no;;88]',
      );
      expect(h.components.reads, ['88']);
      expect(h.components.writes, ['88']);
      expect(
        h.components.payloads.single.single['components'][0]['options'].length,
        1,
      );
      expect(h.messages.sent, isEmpty);
    },
  );
  test(
    'removeButtons preserves unrelated selects and removeComponent targets ID',
    () async {
      final h = _Harness();
      await h.run(
        r'$addButton[no;a;A;primary]$addButton[no;b;B;secondary]$editButton[a;Updated;success;yes]$removeComponent[b]$newSelectMenu[m;1;1]$addSelectMenuOption[m;One;one;]$removeButtons',
      );
      expect(h.rows.single['components'][0]['type'], 'stringSelect');
    },
  );
  test(
    'unknown outer calls and arity preflight prevent hidden effects',
    () async {
      final h = _Harness();
      await h.run(r'$unknown[$addButton[no;a;A;primary]]');
      expect(h.messages.sent.single.payload.containsKey('components'), false);
      final bad = _Harness();
      await expectLater(
        bad.run(r'$addButton[no;a;A;primary]$newModal[bad]'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(bad.messages.sent, isEmpty);
    },
  );
  test(
    'invalid shapes duplicates bounds and missing components never send',
    () async {
      for (final s in [
        r'$addButton[no;a;A;bad]',
        r'$addButton[no;javascript:bad;A;link]',
        r'$addButton[maybe;a;A;primary]',
        r'$newSelectMenu[m;2;1]',
        r'$newSelectMenu[m;1;1]',
        r'$addSelectMenuOption[m;A;a;]',
        r'$addButton[no;a;A;primary]$addButton[no;a;B;primary]',
        r'$newSelectMenu[m;1;1]$addSelectMenuOption[m;A;a;]$addSelectMenuOption[m;B;a;]',
        r'$newSelectMenu[m;1;1]$addSelectMenuOption[m;A;a;;yes]$addSelectMenuOption[m;B;b;;yes]',
        r'$newModal[m;Title]$addTextInput[i;wrong;Label]',
        r'$addTextInput[i;short;Label]',
      ]) {
        final h = _Harness();
        await expectLater(h.run(s), throwsA(anything), reason: s);
        expect(h.messages.sent, isEmpty);
        expect(h.components.modals, isEmpty);
      }
    },
  );
  test('row and modal input limits are enforced', () async {
    final h = _Harness();
    await expectLater(
      h.run(
        List.generate(26, (i) => '\$addButton[no;id$i;Button;primary]').join(),
      ),
      throwsA(isA<BdfdNativeError>()),
    );
    expect(h.messages.sent, isEmpty);
    final m = _Harness();
    await expectLater(
      m.run(
        r'$newModal[m;Title]' +
            List.generate(6, (i) => '\$addTextInput[id$i;short;Name]').join(),
      ),
      throwsA(isA<BdfdNativeError>()),
    );
    expect(m.components.modals, isEmpty);
  });
  test('modal exact SDK payload acknowledges without a text response', () async {
    final h = _Harness();
    await h.run(
      r'$newModal[m;Title]$addTextInput[i;paragraph;About;2;20;no;Default;Hint]',
    );
    final sdk = nativeModalBuilder(h.components.modals.single).build();
    expect(sdk['custom_id'], 'm');
    expect(sdk['title'], 'Title');
    expect((sdk['components'] as List).single['components'].single, {
      'type': 4,
      'custom_id': 'i',
      'label': 'About',
      'style': 2,
      'min_length': 2,
      'max_length': 20,
      'required': false,
      'value': 'Default',
      'placeholder': 'Hint',
    });
    expect(h.context.response.acknowledged, true);
    expect(h.messages.sent, isEmpty);
  });
  test(
    'SDK modal transport calls respondModal and rejects second response',
    () async {
      final interaction = _ModalInteraction();
      final service = DiscordBotComponentService(
        client: _Gateway(),
        interaction: interaction,
      );
      final modal = {
        'customId': 'm',
        'title': 'Title',
        'inputs': [
          {
            'customId': 'i',
            'label': 'Name',
            'style': 'short',
            'minLength': 0,
            'maxLength': 4000,
            'required': true,
          },
        ],
      };
      await service.sendModal(modal, budget: CommandExecutionBudget());
      expect(interaction.sent!.build()['custom_id'], 'm');
      expect(isInteractionAcknowledged(interaction), true);
      await expectLater(
        service.sendModal(modal, budget: CommandExecutionBudget()),
        throwsStateError,
      );
    },
  );
  test(
    'failed explicit writes detach pending mutations and never replay',
    () async {
      final h = _Harness();
      h.components.fail = true;
      await expectLater(
        h.run(r'$addButton[no;a;A;primary;;;88]'),
        throwsA(anything),
      );
      expect(h.components.writes, ['88']);
      expect(h.output.componentState.edits, isEmpty);
      h.components.fail = false;
      await h.run('Next');
      expect(h.components.writes, ['88']);
    },
  );
  for (final e in {
    'string': [
      ComponentType.stringSelect,
      'getStringSelectValue',
      'getStringSelectValues',
      'getStringSelectCount',
    ],
    'channel': [
      ComponentType.channelSelect,
      'getChannelSelectChannelID',
      'getChannelSelectChannelIDs',
      'getChannelSelectChannelCount',
    ],
    'user': [
      ComponentType.userSelect,
      'getUserSelectUserID',
      'getUserSelectUserIDs',
      'getUserSelectUserCount',
    ],
    'role': [
      ComponentType.roleSelect,
      'getRoleSelectRoleID',
      'getRoleSelectRoleIDs',
      'getRoleSelectRoleCount',
    ],
    'mentionable': [
      ComponentType.mentionableSelect,
      'getMentionableSelectUserID',
      'getMentionableSelectUserIDs',
      'getMentionableSelectUserCount',
    ],
  }.entries) {
    test(
      '${e.key} getters preserve commas and support limits and indices',
      () async {
        final context = BdfdContext(
          variables: buildInteractionRuntimeVariables(
            _Interaction(
              _Data(e.value[0] as ComponentType, [r'a,b$var[x;bad]', 'second']),
            ),
          ),
        );
        final runtime = BdfdRuntime(functions: bdfdInteractionFunctions());
        expect(
          await runtime.execute(
            '\$${e.value[1]}[1]|\$${e.value[2]}[/;1]|\$${e.value[3]}',
            context: context,
          ),
          r'a,b$var[x;bad]|a,b$var[x;bad]|2',
        );
        expect(context.temporaryVariables, isEmpty);
        expect(
          await runtime.execute('\$${e.value[1]}[9]', context: context),
          '',
        );
        await expectLater(
          runtime.execute('\$${e.value[1]}[0]', context: context),
          throwsA(isA<BdfdNativeError>()),
        );
      },
    );
  }
  test('getters reject unrelated callback and invalid limits', () async {
    final r = BdfdRuntime(functions: bdfdInteractionFunctions());
    await expectLater(
      r.execute(r'$getStringSelectCount'),
      throwsA(isA<BdfdNativeError>()),
    );
    final c = BdfdContext(
      variables: buildInteractionRuntimeVariables(
        _Interaction(_Data(ComponentType.stringSelect, ['x'])),
      ),
    );
    await expectLater(
      r.execute(r'$getStringSelectValues[/;bad]', context: c),
      throwsA(isA<BdfdNativeError>()),
    );
  });

  test('CV2 components and containers stage correctly', () async {
    final h = _Harness();
    await h.run(
      r'$addContainer[c1;blue]$addSection[s1;c1]$addTextDisplay[Hello world]$addSeparator[yes;10]$addFile[https://example.com/f.png]$addThumbnail[https://example.com/t.png;thumbnail]$addMediaGallery[mg1]$addMediaGalleryItem[https://example.com/img.png;preview]',
    );
    expect(h.rows.length, 7);
    expect(h.rows[0]['type'], 'container');
    expect(h.rows[0]['customId'], 'c1');
    expect(h.rows[1]['type'], 'section');
    expect(h.rows[2]['type'], 'textDisplay');
    expect(h.rows[2]['content'], 'Hello world');
    expect(h.rows[3]['type'], 'separator');
    expect(h.rows[4]['type'], 'file');
    expect(h.rows[5]['type'], 'thumbnail');
    expect(h.rows[6]['type'], 'mediaGallery');
    expect((h.rows[6]['items'] as List).length, 1);
  });

  test('CV2 action row and button and selects add correctly', () async {
    final h = _Harness();
    await h.run(
      r'$addActionRow[row1]$addButtonCV2[btn1;Click;primary;no;;row1]$addChannelSelect[cs1;Select channel;1;2;no]$addRoleSelect[rs1;Select role]$addUserSelect[us1;Select user]$addStringSelect[ss1;Select option]$addStringSelectOption[opt1;v1;desc;😀;yes;ss1]',
    );
    expect(h.rows.length, 5);
    expect(h.rows[0]['type'], 'actionRow');
    expect((h.rows[0]['components'] as List).single['customId'], 'btn1');
    expect(h.rows[1]['type'], 'actionRow');
    final cs = (h.rows[1]['components'] as List).single;
    expect(cs['type'], 'channelSelect');
    expect(cs['minValues'], 1);
    expect(cs['maxValues'], 2);
    final ss = (h.rows[4]['components'] as List).single;
    expect(ss['type'], 'stringSelect');
    expect((ss['options'] as List).single['label'], 'opt1');
  });

  test('V2 modal functions populate inputs and groups correctly', () async {
    final h = _Harness();
    await h.run(
      r'$newModal[m1;Test Modal]$addModalTextDisplay[Please fill]$addModalTextInput[Name;Your name;name_id]$addModalSelect[string;Select role;Role;sel_id]$addModalRadioGroup[Pick one;Radio;rg1]$addRadioGroupOption[rg1;Option A;a]$addModalCheckboxGroup[Pick multiple;Check;cg1]$addCheckboxGroupOption[cg1;Box 1;b1]$addModalCheckbox[Accept terms;Terms;terms_id;yes]$addModalFileUpload[Upload doc;Doc;fu_id]',
    );
    expect(h.components.modals.length, 1);
    final modal = h.components.modals.single;
    expect(modal['customId'], 'm1');
    final inputs = modal['inputs'] as List;
    expect(inputs.length, 7);
    expect(inputs[0]['type'], 'textDisplay');
    expect(inputs[1]['type'], 'textInput');
    expect(inputs[2]['type'], 'selectMenu');
    expect(inputs[3]['type'], 'radioGroup');
    expect((inputs[3]['options'] as List).single['value'], 'a');
    expect(inputs[4]['type'], 'checkboxGroup');
    expect((inputs[4]['options'] as List).single['value'], 'b1');
    expect(inputs[5]['type'], 'checkbox');
    expect(inputs[6]['type'], 'fileUpload');
  });

  test('removeAllComponents clears draft components', () async {
    final h = _Harness();
    await h.run(r'$addButton[no;b1;Btn;primary]$removeAllComponents');
    expect(h.output.componentState.rows, isEmpty);
  });
}
