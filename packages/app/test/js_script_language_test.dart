import 'package:bot_creator/core/code_editor/script_editor_language.dart';
import 'package:bot_creator/core/js_editor/js_script_language.dart';
import 'package:bot_creator/core/models/types/app_emoji.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JsScriptLanguage — complétion emoji', () {
    test('<: propose les emojis du serveur', () {
      final language = JsScriptLanguage(
        appEmojis: const <AppEmoji>[
          AppEmoji(id: '1', name: 'wave', animated: false),
        ],
      );

      final result = language.completionAt('<:', 2);

      expect(result, isNotNull);
      final resolved = result!;
      expect(resolved.replaceStart, 0);
      expect(resolved.entries, hasLength(1));
      expect(resolved.entries.single.label, 'wave');
      expect(resolved.entries.single.insert, '<:wave:1>');
      expect(resolved.entries.single.kind, ScriptCompletionKind.emoji);
    });

    test('<a: insère la mention animée', () {
      final language = JsScriptLanguage(
        appEmojis: const <AppEmoji>[
          AppEmoji(id: '2', name: 'party', animated: true),
        ],
      );
      const text = 'const e = "<a:';

      final result = language.completionAt(text, text.length);

      expect(result, isNotNull);
      final resolved = result!;
      // `replaceStart` pointe sur le `<` du déclencheur.
      expect(resolved.replaceStart, 11);
      expect(resolved.entries.single.insert, '<a:party:2>');
    });

    test('le préfixe de nom filtre les candidats', () {
      final language = JsScriptLanguage(
        appEmojis: const <AppEmoji>[
          AppEmoji(id: '1', name: 'wave', animated: false),
          AppEmoji(id: '2', name: 'party', animated: true),
        ],
      );

      final result = language.completionAt('<:par', 5);

      expect(result, isNotNull);
      final resolved = result!;
      expect(resolved.replaceStart, 0);
      expect(resolved.entries, hasLength(1));
      expect(resolved.entries.single.label, 'party');
    });

    test('au plus 6 suggestions d’emojis', () {
      final language = JsScriptLanguage(
        appEmojis: const <AppEmoji>[
          AppEmoji(id: '1', name: 'e1', animated: false),
          AppEmoji(id: '2', name: 'e2', animated: false),
          AppEmoji(id: '3', name: 'e3', animated: false),
          AppEmoji(id: '4', name: 'e4', animated: false),
          AppEmoji(id: '5', name: 'e5', animated: false),
          AppEmoji(id: '6', name: 'e6', animated: false),
          AppEmoji(id: '7', name: 'e7', animated: false),
          AppEmoji(id: '8', name: 'e8', animated: false),
        ],
      );

      final result = language.completionAt('<:', 2);

      expect(result, isNotNull);
      expect(result!.entries, hasLength(6));
    });

    test('sans index ni emoji, aucune complétion', () {
      final language = JsScriptLanguage();

      expect(language.completionAt('conso', 5), isNull);
      expect(language.completionAt('<:', 2), isNull);
    });
  });

  group('JsScriptLanguage — délégations', () {
    test('diagnosticsFor analyse le document', () {
      final language = JsScriptLanguage();

      final diagnostics = language.diagnosticsFor("'abc");

      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.code, ScriptDiagnosticCode.unterminatedString);
      expect(diagnostics.single.line, 1);
    });

    test('signatureAt délègue au catalogue de signatures', () {
      final language = JsScriptLanguage();

      final hint = language.signatureAt('interaction.reply(', 18);

      expect(hint, isNotNull);
      expect(hint!.name, 'interaction.reply');
      expect(hint.activeIndex, 0);
    });
  });

  group('JsScriptLanguage — chrome de l’éditeur', () {
    test('quickChars expose les symboles du clavier mobile', () {
      final language = JsScriptLanguage();

      expect(language.quickChars, isNotEmpty);
      expect(language.quickChars.length, greaterThanOrEqualTo(10));
      expect(
        language.quickChars,
        containsAll(<String>[
          '{',
          '}',
          '(',
          ')',
          '[',
          ']',
          ';',
          '"',
          "'",
          '`',
          '=',
          '.',
          '>',
        ]),
      );
    });

    test('indentUnit vaut deux espaces par défaut', () {
      expect(JsScriptLanguage().indentUnit(), '  ');
      expect(JsScriptLanguage(tabSize: 4).indentUnit(), '    ');
    });

    test('indentIncreaseFor suit les ouvrants en fin de ligne', () {
      final language = JsScriptLanguage();

      expect(language.indentIncreaseFor('if (x) {'), 2);
      expect(language.indentIncreaseFor('foo('), 2);
      expect(language.indentIncreaseFor('const a = ['), 2);
      expect(language.indentIncreaseFor('const a = 1;'), 0);
      expect(language.indentIncreaseFor('  '), 0);
    });
  });
}
