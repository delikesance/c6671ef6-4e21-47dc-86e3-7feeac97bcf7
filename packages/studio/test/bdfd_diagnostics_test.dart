import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_studio/src/editor/bdfd_hooks.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the app's `bdfdDiagnosticsFor` reports: the full native engine
/// registry (services that reject every call), mapped like `ui_hooks.dart`.
List<(String, int?, int?)> _engineDiagnostics(String source) {
  try {
    BdfdEngine.validation().prepare(source);
    return const [];
  } on BdfdNativeError catch (e) {
    return [(e.message, e.location.line, e.location.column)];
  }
}

List<(String, int?, int?)> _studioDiagnostics(String source) => [
  for (final d in BdfdEditorHooks.diagnostics(source, 'native-v1'))
    (d.message, d.line, d.column),
];

void main() {
  final defaultHook = BdfdEditorHooks.diagnostics;
  setUp(bindStudioBdfdHooks);
  tearDown(() => BdfdEditorHooks.diagnostics = defaultHook);

  const bad = {
    'unsupported known function': r'$kickMention',
    'wrong argument count': r'$random[1]',
    'second line': '\n\$kickMention',
    'untaken branch': r'$if[false]$kickMention$endif',
  };
  for (final entry in bad.entries) {
    test('${entry.key}: same diagnostics as the engine', () {
      final expected = _engineDiagnostics(entry.value);
      expect(expected, isNotEmpty);
      expect(_studioDiagnostics(entry.value), expected);
    });
  }

  test('valid and opaque scripts produce no diagnostic', () {
    expect(_studioDiagnostics(r'$sendMessage[x;yes]'), isEmpty);
    expect(_studioDiagnostics(r'$unknown[$kickMention]'), isEmpty);
    expect(_studioDiagnostics(''), isEmpty);
  });

  test('an unknown backend is reported, never selected silently', () {
    final diagnostics = BdfdEditorHooks.diagnostics('hello', 'unknown-v99');
    expect(diagnostics.single.message, contains('Unknown BDFD backend'));
    expect(diagnostics.single.isError, isTrue);
  });

  test('the editor language reports the argument errors', () {
    final language = BdfdScriptLanguage(backend: 'native-v1');
    expect(language.diagnosticsFor(r'$random[1]'), isNotEmpty);
    expect(language.diagnosticsFor(r'$random[1;2]'), isEmpty);
  });
}
