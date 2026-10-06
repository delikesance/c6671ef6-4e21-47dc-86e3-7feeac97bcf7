import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/utils/message_runtime.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

BdfdEngine _engine() => BdfdEngine(store: MemoryBotDataStore(), botId: 'bot');
void main() {
  test(
    'replaceText observes amount and never reprocesses its replacement',
    () async {
      final engine = _engine();
      for (final entry in {
        r'$replaceText[banana;a;X]': 'bXnana',
        r'$replaceText[banana;a;X;2]': 'bXnXna',
        r'$replaceText[banana;a;X;-1]': 'bXnXnX',
        r'$replaceText[banana;a;X;0]': 'banana',
        r'$replaceText[aa;a;ab;2]': 'abab',
        r'$replaceText[aaa;aa;b;-1]': 'ba',
        r'$replaceText[abc;;X]': 'abc',
        r'$replaceText[abc;bc;]': 'a',
      }.entries) {
        expect(await engine.execute(entry.key), entry.value, reason: entry.key);
      }
      for (final source in [
        r'$replaceText[a;a;b;-2]',
        r'$replaceText[a;a;b;invalid]',
      ]) {
        await expectLater(
          engine.execute(source),
          throwsA(isA<BdfdNativeError>()),
        );
      }
    },
  );
  test('replacement data and unknown arguments are never reparsed', () async {
    final context = BdfdContext(
      temporaryVariables: {
        'value': r'$textSplit[should not run; ] ((secret)) ; [x]',
      },
    );
    final engine = _engine();
    expect(
      await engine.execute(
        r'$replaceText[hello;hello;$var[value]]',
        context: context,
      ),
      context.temporaryVariables['value'],
    );
    expect(context.textSplit.length, 0);
    expect(
      await engine.execute(r'$unknown[$textSplit[no; ]]', context: context),
      r'$unknown[$textSplit[no; ]]',
    );
    expect(context.textSplit.length, 0);
  });
  test('textSplit supports first last empty items joins and mutations', () async {
    final engine = _engine();
    final context = BdfdContext(temporaryVariables: {'separator': ';'});
    expect(
      await engine.execute(
        r'$textSplit[a,,c;,]$splitText[<]|$splitText[2]|$splitText[>]|$getTextSplitLength|$getTextSplitIndex[c]|$getTextSplitIndex[missing]',
        context: context,
      ),
      'a||c|3|3|-1',
    );
    expect(
      await engine.execute(
        r'$editSplitText[2;b]$removeSplitTextElement[1]$joinSplitText[$var[separator]]',
        context: context,
      ),
      'b;c',
    );
    expect(context.textSplit.values, ['b', 'c']);
    expect(
      await engine.execute(
        r'$textSplit[abc;]$splitText[2]$joinSplitText[-]',
        context: context,
      ),
      'ba-b-c',
    );
    expect(await engine.execute(r'$splitText[99]', context: context), '');
    await expectLater(
      engine.execute(r'$editSplitText[0;bad]', context: context),
      throwsA(isA<BdfdNativeError>()),
    );
  });
  test(
    'split state is shared by eval and selected branches without leaking to another context',
    () async {
      final engine = _engine();
      final context = BdfdContext(
        temporaryVariables: {'code': r'$editSplitText[2;new]'},
      );
      expect(
        await engine.execute(
          r'$textSplit[old,value;,]$if[false]$textSplit[never;]$else$eval[$var[code]]$endif$joinSplitText[/]',
          context: context,
        ),
        'old/new',
      );
      expect(await engine.execute(r'$getTextSplitLength'), '0');
      expect(
        await engine.execute(
          r'$try$editSplitText[99;bad]$catch$joinSplitText[/]$endtry',
          context: context,
        ),
        'old/new',
      );
    },
  );
  test(
    'repeatMessage follows official amount then text signature and max ten',
    () async {
      final engine = _engine();
      expect(await engine.execute(r'$repeatMessage[3;Hi ]'), 'Hi Hi Hi ');
      expect(await engine.execute(r'$repeatMessage[0;unused]'), '');
      expect(await engine.execute(r'$repeatMessage[10;x]'), 'xxxxxxxxxx');
      for (final source in [
        r'$repeatMessage[11;x]',
        r'$repeatMessage[-1;x]',
        r'$repeatMessage[abc;3]',
      ]) {
        await expectLater(
          engine.execute(source),
          throwsA(isA<BdfdNativeError>()),
        );
      }
    },
  );
  test(
    'checkContains tests any phrase and casing remains significant',
    () async {
      final engine = _engine();
      expect(
        await engine.execute(r'$checkContains[hello world;bye;world]'),
        'true',
      );
      expect(await engine.execute(r'$checkContains[hello;Hello]'), 'false');
      expect(await engine.execute(r'$checkContains[hello;]'), 'true');
      expect(
        await engine.execute(r'$toTitleCase[hello  WORLD]|$trimContent[ hi ]'),
        'Hello  World|hi',
      );
    },
  );
  test(
    'prefix message selectors use arguments after the command trigger',
    () async {
      final context = BdfdContext(
        variables: buildCommandArgumentRuntimeVariables([
          'one',
          'two',
          'three',
        ]),
      );
      expect(
        await _engine().execute(
          r'$message|$message[1]|$message[>]|$message[<]|$message[2;3]|$message[>1]|$message[2;]|$argCount',
          context: context,
        ),
        'one two three|one|three|one|two three|two three|two three|3',
      );
      expect(await _engine().execute(r'$message[99]', context: context), '');
    },
  );
  test(
    'slash named options and dual prefix slash signature preserve literal input',
    () async {
      final engine = _engine();
      final literal = r'$setVar[shouldNotRun;yes]; [ ] ((placeholder))';
      final context = BdfdContext(
        variables: {
          'interaction.isSlash': 'true',
          'opts.text': literal,
          'message.content': 'stale prefix',
        },
      );
      expect(
        await engine.execute(r'$message[text]', context: context),
        literal,
      );
      expect(
        await engine.execute(r'$message[1;text]', context: context),
        literal,
      );
      expect(await engine.execute(r'$message[missing]', context: context), '');
      final prefix = BdfdContext(
        variables: {
          'message.content': 'real prefix',
          'opts.text': 'wrong',
          'interaction.isSlash': 'false',
        },
      );
      expect(
        await engine.execute(r'$message[1;text]', context: prefix),
        'real',
      );
    },
  );
  test(
    'message and argCount read current context with normalized whitespace',
    () async {
      final variables = <String, String>{
        'message.content': '  one\t two\nthree ',
      };
      final context = BdfdContext(variables: variables);
      final engine = _engine();
      expect(
        await engine.execute(r'$message[2]|$argCount', context: context),
        'two|3',
      );
      variables['message.content'] = 'changed';
      expect(
        await engine.execute(r'$message[1]|$argCount', context: context),
        'changed|1',
      );
    },
  );
  test(
    'mentions use flattened context and official author fallback default',
    () async {
      final engine = _engine();
      final context = BdfdContext(
        variables: {
          'author.id': '10',
          'channel.id': '20',
          'message.mentions[0]': '30',
          'message.mentions[1]': '40',
          'message.channelMentions': '50,60',
          'message.roleMentions': '70,80',
        },
      );
      expect(
        await engine.execute(
          r'$mentioned[2]|$mentioned[>]|$mentioned[3]|$mentioned[3;no]|$mentionedChannels[2]|$mentionedChannels[3;yes]|$mentionedRoles[>]|$isMentioned[40]',
          context: context,
        ),
        '40|40|10||60|20|80|true',
      );
      expect(
        await engine.execute(
          r'$mentioned[1]',
          context: BdfdContext(variables: {'author.id': '99'}),
        ),
        '99',
      );
      for (final source in [r'$mentioned[0]', r'$mentioned[1;maybe]']) {
        await expectLater(
          engine.execute(source, context: context),
          throwsA(isA<BdfdNativeError>()),
        );
      }
    },
  );
  test(
    'slash mentions are rejected and options should be used instead',
    () async {
      final context = BdfdContext(
        variables: {'interaction.isSlash': 'true', 'opts.target': '123'},
      );
      await expectLater(
        _engine().execute(r'$mentioned[1]', context: context),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(
        await _engine().execute(r'$message[target]', context: context),
        '123',
      );
    },
  );
  test(
    'argsCheck official compact and legacy separated signatures stop effects',
    () async {
      final engine = _engine();
      for (final source in [
        r'$argsCheck[>2;denied]',
        r'$argsCheck[>=;2;denied]',
        r'$argsCheck[2;denied]',
      ]) {
        final context = BdfdContext(variables: {'message.content': 'one two'});
        expect(
          await engine.execute(
            '$source'
            r'$var[touched;yes]allowed',
            context: context,
          ),
          'allowed',
        );
        expect(context.temporaryVariables['touched'], 'yes');
      }
      final rejected = BdfdContext(variables: {'message.content': 'one two'});
      expect(
        await engine.execute(
          r'$argsCheck[<2;denied]$var[touched;yes]allowed',
          context: rejected,
        ),
        'denied',
      );
      expect(rejected.temporaryVariables, isEmpty);
      expect(
        await engine.execute(
          r'$argsCheck[<=2;denied]allowed',
          context: rejected,
        ),
        'allowed',
      );
    },
  );
  test('error argument of successful argsCheck is lazy', () async {
    final context = BdfdContext(variables: {'message.content': 'one'});
    expect(
      await _engine().execute(
        r'$argsCheck[>1;$textSplit[never; ]]ok',
        context: context,
      ),
      'ok',
    );
    expect(context.textSplit.length, 0);
  });
  test('replacement and split operations work on message content', () async {
    for (final entry in {
      r'$replaceText[aa;a;ab;2]': 'abab',
      r'$replaceText[$message;a;X;2]': 'X,b,X',
      r'$textSplit[$message;,]$editSplitText[2;new]$removeSplitTextElement[1]$getTextSplitLength:$joinSplitText[/]':
          '2:new/a',
      r'$textSplit[a,b;,]$splitText[<]:$splitText[>]': 'a:b',
    }.entries) {
      final native = await _engine().execute(
        entry.key,
        context: BdfdContext(variables: {'message.content': 'a,b,a'}),
      );
      expect(native, entry.value, reason: entry.key);
    }
  });
  test(
    'shared replacement treats inserted samples as data in runtime placeholders',
    () {
      expect(
        resolveTemplatePlaceholders(r'((replaceText[((value)) ;a;ab;2]))', {
          'value': 'aa',
        }),
        'abab ',
      );
    },
  );
}
