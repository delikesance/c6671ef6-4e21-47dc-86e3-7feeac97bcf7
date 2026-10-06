import 'package:bot_creator/features/copilot/presentation/copilot_code_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('le diff marque les lignes ajoutées et retirées', () {
    final lines = copilotDiffLines('a\nb\nc', 'a\nx\nc\nd');
    expect(
      lines.map((l) => l.kind.name).toList(),
      ['same', 'add', 'del', 'same', 'add'].length == lines.length
          ? lines.map((l) => l.kind.name).toList()
          : [],
    );
    expect(lines.where((l) => l.kind == CopilotDiffKind.add).length, 2);
    expect(lines.where((l) => l.kind == CopilotDiffKind.del).length, 1);
  });

  test('sans script d\'origine aucun diff n\'est inventé', () {
    final lines = copilotDiffLines(null, 'a\nb');
    expect(lines.every((l) => l.kind == CopilotDiffKind.same), isTrue);
  });

  testWidgets('aperçu : compteurs, action d\'ouverture et diagnostics', (
    tester,
  ) async {
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CopilotCodePreview(
            fileName: 'couleur.bdfd',
            before: r'$title[a]',
            script:
                r'$title[a]'
                '\n'
                r'$description[b]',
            onOpen: () => opened++,
          ),
        ),
      ),
    );
    expect(find.text('+1'), findsOneWidget);
    expect(find.text('Syntaxe valide'), findsOneWidget);
    await tester.tap(find.byTooltip("Ouvrir dans l'éditeur"));
    expect(opened, 1);
  });

  test(
    'creation and execution updates preview their script, workflows do not',
    () {
      expect(
        copilotActionHasCode('local_create_command', r'$ping', 'bdfd_script'),
        isTrue,
      );
      expect(
        copilotActionHasCode(
          'local_update_command_execution',
          'x',
          'javascript',
        ),
        isTrue,
      );
      expect(
        copilotActionHasCode('local_create_command', '', 'bdfd_script'),
        isFalse,
      );
      expect(
        copilotActionHasCode('local_create_command', r'$ping', 'workflow'),
        isFalse,
      );
      expect(
        copilotActionHasCode(
          'local_update_command_settings',
          'x',
          'bdfd_script',
        ),
        isFalse,
      );
    },
  );
}
