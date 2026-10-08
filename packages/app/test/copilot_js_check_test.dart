import 'package:bot_creator/features/copilot/logic/copilot_js_check.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'valid scripts pass, including regexes, comments and nested templates',
    () {
      const script = r'''
// greet
const text = (interaction.options.getString("message") || "").toLowerCase();
if (/привіт|hello/i.test(text) && /['"]/.test(text) === false) {
  await interaction.reply(`Hi ${text.split(/\s+/).map((w) => `<${w}>`).join(",")}!`);
}
const n = 4 / 2; /* block */
await db.user.set("k", n);
''';
      expect(
        checkCopilotJavascript(script, declaredOptions: {'message'}),
        isEmpty,
      );
    },
  );

  test('an unescaped backtick inside a template literal is reported', () {
    const script = r'''
return interaction.reply(`Win! Type `/guess` again`);
''';
    expect(checkCopilotJavascript(script), isNotEmpty);
    const fixed = r'''
return interaction.reply(`Win! Type \`/guess\` again`);
''';
    expect(checkCopilotJavascript(fixed), isEmpty);
  });

  test('unterminated strings and unbalanced brackets are reported', () {
    expect(
      checkCopilotJavascript('await interaction.reply("a\nb");'),
      isNotEmpty,
    );
    expect(checkCopilotJavascript('if (x) { await a();'), isNotEmpty);
    expect(checkCopilotJavascript('foo(1));'), isNotEmpty);
  });

  test('client.db and undeclared options are reported', () {
    expect(
      checkCopilotJavascript('await interaction.client.db.set("a", 1);'),
      isNotEmpty,
    );
    final problems = checkCopilotJavascript(
      'const t = interaction.options.getString("message");',
      declaredOptions: <String>{},
    );
    expect(problems.single, contains('"message"'));
    expect(
      checkCopilotJavascript(
        'interaction.options.getInteger("число");',
        declaredOptions: copilotDeclaredOptionNames([
          {'name': 'число', 'type': 'integer'},
        ]),
      ),
      isEmpty,
    );
  });

  test('module syntax is rejected because the script is a function body', () {
    expect(
      checkCopilotJavascript('module.exports = async () => {};'),
      isNotEmpty,
    );
    expect(checkCopilotJavascript("import x from 'y';"), isNotEmpty);
    expect(
      checkCopilotJavascript("const x = require('crypto');\nreturn x;"),
      isEmpty,
    );
  });
}
