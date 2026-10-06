import 'package:bot_creator_shared/engine/bdfd/interaction_functions.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/events/event_contexts.dart';
import 'package:nyxx/nyxx.dart';
import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:test/test.dart';

class _Data {
  const _Data(
    this.customId, {
    this.values = const <String>[],
    this.type = ComponentType.button,
  });
  final String customId;
  final List<String> values;
  final ComponentType type;
}

class _Interaction implements Interaction<dynamic> {
  _Interaction(this.data, this.type);
  @override
  final dynamic data;
  @override
  final InteractionType type;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  BdfdRuntime runtime() => BdfdRuntime(functions: bdfdInteractionFunctions());
  for (final type in [
    InteractionType.messageComponent,
    InteractionType.modalSubmit,
  ]) {
    test(
      'actual ${type.value} data maps custom ID through the event adapter',
      () async {
        const id = r'button,$literal[$setVar[x;bad]]';
        final variables = buildInteractionRuntimeVariables(
          _Interaction(const _Data(id), type),
        );
        expect(variables['interaction.type'], '${type.value}');
        expect(
          await runtime().execute(
            r'$customID',
            context: BdfdContext(variables: variables),
          ),
          id,
        );
      },
    );
  }
  test(
    'string select ID comes from the component, not its option values',
    () async {
      final variables = buildInteractionRuntimeVariables(
        _Interaction(
          const _Data(
            'menu',
            values: ['first', 'second'],
            type: ComponentType.stringSelect,
          ),
          InteractionType.messageComponent,
        ),
      );
      expect(
        await runtime().execute(
          r'$customID',
          context: BdfdContext(variables: variables),
        ),
        'menu',
      );
      expect(variables['interaction.values'], 'first,second');
    },
  );
  test(
    'actual component data survives native sandbox response output',
    () async {
      const id = r'menu,$unknown[$var[x;bad]]';
      final variables = buildInteractionRuntimeVariables(
        _Interaction(const _Data(id), InteractionType.messageComponent),
      );
      final result = await testCommandInSandbox({
        'bdfdBackend': 'native-v1',
        'script': r'$customID',
        'variables': variables,
      });
      expect(result['success'], true, reason: '$result');
      expect(result['responses'][0]['payload']['content'], id);
    },
  );
  test('prefix and slash contexts reject spoofed custom IDs', () async {
    for (final type in [null, '1', '2', '4']) {
      await expectLater(
        runtime().execute(
          r'$customID',
          context: BdfdContext(
            variables: {
              'interaction.type': ?type,
              'interaction.customId': 'spoofed',
              'message.content': 'button',
              'opts.customID': 'slash',
            },
          ),
        ),
        throwsA(isA<BdfdNativeError>()),
      );
    }
  });
  test(
    'missing ID on actual component context raises source located error',
    () async {
      await expectLater(
        runtime().execute(
          r'$customID',
          context: BdfdContext(variables: {'interaction.type': '3'}),
        ),
        throwsA(
          isA<BdfdNativeError>().having(
            (e) => e.location.functionName,
            'function',
            r'$customID',
          ),
        ),
      );
    },
  );
  test(
    'preflight rejects customID arguments before earlier state effects',
    () async {
      final context = BdfdContext();
      await expectLater(
        runtime().execute(r'$var[x;written]$customID[bad]', context: context),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(context.variables.containsKey('var.x'), false);
    },
  );
  test('unknown callback functions keep state arguments opaque', () async {
    const source = r'$unknownSelect[$var[x;bad]]';
    final context = BdfdContext();
    expect(await runtime().execute(source, context: context), source);
    expect(context.variables.containsKey('var.x'), false);
  });
}
