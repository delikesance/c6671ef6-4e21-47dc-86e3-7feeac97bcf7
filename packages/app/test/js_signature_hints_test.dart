import 'package:bot_creator/core/js_editor/js_signature_hints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('jsSignatureHintAt', () {
    test('interaction.reply( désigne le premier argument', () {
      const text = 'await interaction.reply(';

      final hint = jsSignatureHintAt(text, text.length);

      expect(hint, isNotNull);
      final resolved = hint!;
      expect(resolved.name, 'interaction.reply');
      expect(resolved.parameters, <String>['content']);
      expect(resolved.activeIndex, 0);
    });

    test('db.user.set avec un argument déjà saisi', () {
      const text = "await db.user.set('coins', ";

      final hint = jsSignatureHintAt(text, text.length);

      expect(hint, isNotNull);
      expect(hint!.name, 'db.user.set');
      expect(hint.activeIndex, 1);
    });

    test('console.log( est reconnu', () {
      const text = 'console.log(';

      final hint = jsSignatureHintAt(text, text.length);

      expect(hint, isNotNull);
      expect(hint!.name, 'console.log');
      expect(hint.parameters, <String>['message']);
    });

    test('interaction.options.getString( est reconnu', () {
      const text = 'const name = interaction.options.getString(';

      final hint = jsSignatureHintAt(text, text.length);

      expect(hint, isNotNull);
      expect(hint!.name, 'interaction.options.getString');
      expect(hint.parameters, <String>['name', 'required?']);
      expect(hint.activeIndex, 0);
    });

    test('un callable inconnu ne produit pas de hint', () {
      expect(jsSignatureHintAt('myHelper(', 9), isNull);
    });

    test('un curseur hors appel ne produit pas de hint', () {
      const text = 'const a = 1;';

      expect(jsSignatureHintAt(text, text.length), isNull);
    });

    test('un curseur dans un bloc sans appel ne produit pas de hint', () {
      const text = 'if (x) {\n  ';

      expect(jsSignatureHintAt(text, text.length), isNull);
    });

    test('le curseur est respecté : hint dès la parenthèse ouvrante', () {
      const text = 'await interaction.reply("hi");';

      final hint = jsSignatureHintAt(text, 'await interaction.reply('.length);

      expect(hint, isNotNull);
      expect(hint!.name, 'interaction.reply');
      expect(hint.activeIndex, 0);
    });

    test('une virgule dans une chaîne ne compte pas', () {
      const text = "db.user.set('a,b', ";

      final hint = jsSignatureHintAt(text, text.length);

      expect(hint, isNotNull);
      expect(hint!.activeIndex, 1);
    });

    test('une virgule dans un commentaire ou un template ne compte pas', () {
      const commented = "db.user.set(/* , */ 'a', ";
      const templated = r'db.user.set(`a,${b}`, ';

      expect(jsSignatureHintAt(commented, commented.length)!.activeIndex, 1);
      expect(jsSignatureHintAt(templated, templated.length)!.activeIndex, 1);
    });

    test('les parenthèses imbriquées ne comptent pas leurs virgules', () {
      const text = 'db.user.set(Math.max(1, 2), ';

      final hint = jsSignatureHintAt(text, text.length);

      expect(hint, isNotNull);
      expect(hint!.name, 'db.user.set');
      expect(hint.activeIndex, 1);
    });

    test("l'index actif est borné au dernier paramètre", () {
      const text = "db.user.set('a', 1, 'b', 2, ";

      final hint = jsSignatureHintAt(text, text.length);

      expect(hint, isNotNull);
      expect(hint!.parameters, hasLength(3));
      expect(hint.activeIndex, 2);
    });

    test('un appel multi-ligne est reconnu', () {
      const text = 'const v = await db.global.set(\n  ';

      final hint = jsSignatureHintAt(text, text.length);

      expect(hint, isNotNull);
      expect(hint!.name, 'db.global.set');
      expect(hint.activeIndex, 0);
    });

    test('un appel déjà fermé avant le curseur ne produit pas de hint', () {
      const text = 'db.user.set("a", 1);\nconst b = ';

      expect(jsSignatureHintAt(text, text.length), isNull);
    });
  });
}
