import 'package:bot_creator_shared/utils/component_runtime.dart';
import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:test/test.dart';

void main() {
  test('typed values resolve without changing future callback inputs', () {
    final source = <String, dynamic>{
      'disabled': '((opts.disabled))',
      'maxValues': '((opts.max))',
      'actions': [
        {
          'payload': {'content': '((opts.disabled))'},
        },
      ],
    };
    final result = resolveComponentRuntimeFields(
      source,
      (value) => value == '((opts.disabled))' ? 'false' : '2',
    );
    expect(result['disabled'], false);
    expect(result['maxValues'], 2);
    expect(result['actions'][0]['payload']['content'], '((opts.disabled))');
    expect(source['disabled'], '((opts.disabled))');
  });
  for (final field in ['disabled', 'maxValues']) {
    test(
      'invalid runtime $field fails instead of silently using a default',
      () {
        expect(
          () => resolveComponentRuntimeFields({
            field: '((opts.bad))',
          }, (_) => 'invalid'),
          throwsFormatException,
        );
      },
    );
  }
  test('modal header collects subsequent fields and options', () async {
    final result = await testCommandInSandbox({
      'script':
          r'$newModal[form;Profile] $addModalRadioGroup[Choice;;choice;false]$addRadioGroupOption[choice;One;one;;true]',
    });
    expect(result['success'], true, reason: '$result');
    final child =
        result['responses'][0]['api_modal']['components'][0]['component'];
    expect(child['required'], false);
    expect(child['options'][0]['default'], true);
  });
  test('modal string select accepts options after its header', () async {
    final result = await testCommandInSandbox({
      'script':
          r'$newModal[form;Profile]$addModalSelect[string;Choice;;choice;;0;1;false]$addSelectMenuOption[choice;One;one;;true]',
    });
    expect(result['success'], true, reason: '$result');
    final child =
        result['responses'][0]['api_modal']['components'][0]['component'];
    expect(child['type'], 3);
    expect(child['required'], false);
    expect(child['options'][0]['value'], 'one');
    expect(child['options'][0]['default'], true);
    expect(result['responses'], hasLength(1));
  });
  for (final value in [false, true]) {
    test('thumbnail spoiler uses runtime $value', () async {
      final result = await testCommandInSandbox({
        'script':
            r'$addSection$addTextDisplay[Text]$addThumbnail[https://example.com/image.png;Image;((opts.spoiler))]',
        'options': {'spoiler': value},
      });
      expect(result['success'], true, reason: '$result');
      final accessory =
          result['responses'][0]['api_components'][0]['accessory'];
      expect(accessory['spoiler'] ?? false, value);
    });
  }
  test(
    'separator preserves explicit false rather than Discord default true',
    () async {
      final result = await testCommandInSandbox({
        'script': r'$addSeparator[false;1]',
      });
      expect(result['success'], true, reason: '$result');
      expect(result['responses'][0]['api_components'][0]['divider'], false);
    },
  );
}
