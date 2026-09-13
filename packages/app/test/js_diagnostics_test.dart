import 'package:bot_creator/core/code_editor/script_editor_language.dart';
import 'package:bot_creator/core/js_editor/js_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('analyzeJavaScript — code valide', () {
    test('un script réaliste ne produit aucun diagnostic', () {
      const source = '''
// Un script réaliste
const { Client, GatewayIntentBits } = require('discord.js');
const client = new Client({ intents: [GatewayIntentBits.Guilds] });
/* bloc
   multi-ligne */
client.on('messageCreate', async (message) => {
  const url = `https://example.dev/\${message.id}?u=\${message.author.id}`;
  if (message.content.includes('hi, there')) {
    await db.user.set('coins', 1, message.author.id);
  }
});
''';

      expect(analyzeJavaScript(source), isEmpty);
    });

    test('un template avec substitution est propre', () {
      expect(analyzeJavaScript(r'`a ${b} c`'), isEmpty);
    });

    test('un template imbriqué correctement fermé est propre', () {
      expect(analyzeJavaScript(r'`a ${ `b` } `'), isEmpty);
    });

    test('le contenu d’un commentaire bloc est ignoré', () {
      expect(analyzeJavaScript('/* {([ */ const a = 1;'), isEmpty);
    });
  });

  group('analyzeJavaScript — chaînes et templates', () {
    test('apostrophe non fermée au début du fichier', () {
      final diagnostics = analyzeJavaScript("'abc");

      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.code, ScriptDiagnosticCode.unterminatedString);
      expect(diagnostics.single.severity, ScriptDiagnosticSeverity.error);
      expect(diagnostics.single.line, 1);
      expect(diagnostics.single.column, 1);
      expect(diagnostics.single.detail, isEmpty);
    });

    test('guillemet double non fermée, colonne exacte', () {
      final diagnostics = analyzeJavaScript('const s = "abc');

      expect(diagnostics.single.code, ScriptDiagnosticCode.unterminatedString);
      expect(diagnostics.single.line, 1);
      expect(diagnostics.single.column, 11);
    });

    test('guillemet échappée : aucune erreur', () {
      expect(analyzeJavaScript(r"const s = 'a\'b';"), isEmpty);
    });

    test('une parenthèse dans une chaîne est ignorée', () {
      expect(analyzeJavaScript('const s = "(";'), isEmpty);
    });

    test('un backtick jamais fermé est un template non terminé', () {
      final diagnostics = analyzeJavaScript('`abc');

      expect(diagnostics, hasLength(1));
      expect(
        diagnostics.single.code,
        ScriptDiagnosticCode.unterminatedTemplate,
      );
      expect(diagnostics.single.severity, ScriptDiagnosticSeverity.error);
      expect(diagnostics.single.line, 1);
      expect(diagnostics.single.column, 1);
    });

    test('un \${ jamais fermé ne produit pas de faux template', () {
      final diagnostics = analyzeJavaScript(r'`a ${b');

      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.code, ScriptDiagnosticCode.unclosedOpening);
      expect(diagnostics.single.detail, '{');
      expect(diagnostics.single.line, 1);
      expect(diagnostics.single.column, 5);
    });

    test('un template imbriqué dont le backtick externe manque', () {
      final diagnostics = analyzeJavaScript(r'`a ${ `b` }');

      expect(diagnostics, hasLength(1));
      expect(
        diagnostics.single.code,
        ScriptDiagnosticCode.unterminatedTemplate,
      );
      expect(diagnostics.single.line, 1);
      expect(diagnostics.single.column, 1);
    });
  });

  group('analyzeJavaScript — commentaires', () {
    test('commentaire bloc non fermé', () {
      final diagnostics = analyzeJavaScript('/* abc');

      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.code, ScriptDiagnosticCode.unterminatedComment);
      expect(diagnostics.single.line, 1);
      expect(diagnostics.single.column, 1);
    });

    test('les ouvrants d’un commentaire de ligne sont ignorés', () {
      expect(analyzeJavaScript('// {[(\nconst a = 1;'), isEmpty);
    });
  });

  group('analyzeJavaScript — équilibre des ouvrants', () {
    test('une accolade jamais fermée est signalée sur sa position', () {
      final diagnostics = analyzeJavaScript('{');

      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.code, ScriptDiagnosticCode.unclosedOpening);
      expect(diagnostics.single.severity, ScriptDiagnosticSeverity.warning);
      expect(diagnostics.single.detail, '{');
      expect(diagnostics.single.line, 1);
      expect(diagnostics.single.column, 1);
      expect(diagnostics.single.detailLine, 1);
    });

    test('une fermante orpheline est signalée avec son caractère', () {
      final diagnostics = analyzeJavaScript('}');

      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.code, ScriptDiagnosticCode.unexpectedClosing);
      expect(diagnostics.single.severity, ScriptDiagnosticSeverity.error);
      expect(diagnostics.single.detail, '}');
      expect(diagnostics.single.line, 1);
      expect(diagnostics.single.column, 1);
    });

    test('un appariement croisé est détecté', () {
      final diagnostics = analyzeJavaScript('([)]');

      expect(diagnostics, hasLength(2));
      expect(diagnostics.first.code, ScriptDiagnosticCode.unexpectedClosing);
      expect(diagnostics.first.detail, ')');
      expect(diagnostics.first.line, 1);
      expect(diagnostics.first.column, 3);
      expect(diagnostics.last.code, ScriptDiagnosticCode.unclosedOpening);
      expect(diagnostics.last.detail, '(');
    });

    test('une chaîne non fermée laisse aussi son ouvrante non fermée', () {
      final diagnostics = analyzeJavaScript("foo('abc");

      expect(
        diagnostics.map((diagnostic) => diagnostic.code),
        <ScriptDiagnosticCode>[
          ScriptDiagnosticCode.unterminatedString,
          ScriptDiagnosticCode.unclosedOpening,
        ],
      );
    });
  });

  group('analyzeJavaScript — positions multi-lignes', () {
    test('la ligne d’une chaîne non fermée est exacte', () {
      final diagnostics = analyzeJavaScript("const a = 1;\nconst b = 'oops\n");

      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.code, ScriptDiagnosticCode.unterminatedString);
      expect(diagnostics.single.line, 2);
      expect(diagnostics.single.column, 11);
    });

    test('la ligne d’un ouvrante non fermée est exacte', () {
      final diagnostics = analyzeJavaScript('function f() {\n  return 1;\n');

      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.code, ScriptDiagnosticCode.unclosedOpening);
      expect(diagnostics.single.detail, '{');
      expect(diagnostics.single.line, 1);
      expect(diagnostics.single.column, 14);
      expect(diagnostics.single.detailLine, 1);
    });
  });
}
