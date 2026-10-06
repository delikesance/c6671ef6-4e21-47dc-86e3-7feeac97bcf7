import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('syntaxe BDFD : un script bien formé n\'a pas de diagnostic', () {
    expect(
      BdfdEditorHooks.syntaxDiagnostics(r'$sendMessage[Bonjour]', 'native-v1'),
      isEmpty,
    );
    expect(BdfdEditorHooks.syntaxDiagnostics('   ', 'native-v1'), isEmpty);
  });

  test('syntaxe BDFD : un crochet non fermé est signalé', () {
    final diagnostics = BdfdEditorHooks.syntaxDiagnostics(
      r'$sendMessage[Bonjour',
      'native-v1',
    );
    expect(diagnostics, isNotEmpty);
    expect(diagnostics.every((d) => d.isError), isTrue);
  });
}
