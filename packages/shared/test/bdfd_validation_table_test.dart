import 'dart:io';

import 'package:bot_creator_shared/bdfd_validation.dart';
import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/execution.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/bdfd/validation/bdfd_signatures.g.dart';
import 'package:test/test.dart';

import '../tool/gen_bdfd_signatures.dart'
    show outputPath, renderBdfdSignatureTable;

final _engine = BdfdEngine.validation();

/// The implementation `bdfdDiagnosticsFor` had before validation became
/// web-safe: the full engine registry with services that reject every call.
List<BdfdCompileDiagnostic> _reference(String source, {Object? backend}) {
  try {
    BdfdBackend.parse(backend);
    _engine.prepare(source);
    return const [];
  } on BdfdNativeError catch (error) {
    return [
      BdfdCompileDiagnostic(
        message: error.message,
        severity: BdfdCompileDiagnosticSeverity.error,
        stage: BdfdCompileDiagnosticStage.parser,
        start: error.location.offset,
        line: error.location.line,
        column: error.location.column,
        functionName: error.location.functionName,
      ),
    ];
  } on FormatException catch (error) {
    return [
      BdfdCompileDiagnostic(
        message: error.message,
        severity: BdfdCompileDiagnosticSeverity.error,
        stage: BdfdCompileDiagnosticStage.parser,
      ),
    ];
  }
}

String _describe(List<BdfdCompileDiagnostic> diagnostics) => diagnostics
    .map(
      (d) =>
          '${d.severity.name}/${d.stage.name}@${d.start}:${d.line}:${d.column}'
          '/${d.functionName}/${d.message}',
    )
    .join('\n');

Object? _run(List<BdfdCompileDiagnostic> Function() body) {
  try {
    return _describe(body());
  } catch (error) {
    return 'threw ${error.runtimeType}';
  }
}

void main() {
  test('the generated signature table matches the committed file', () {
    expect(
      File(outputPath).readAsStringSync(),
      renderBdfdSignatureTable(),
      reason:
          'Run `dart run tool/gen_bdfd_signatures.dart` in packages/shared.',
    );
  });

  test('table plus core functions equal the full engine registry', () {
    final table = BdfdRuntime(
      functions: {
        for (final e in bdfdSuppliedFunctionSignatures.entries)
          e.key: BdfdNativeFunction(
            handler: (_) => '',
            minArguments: e.value.minArguments,
            maxArguments: e.value.maxArguments,
            allowedArgumentCounts: e.value.allowedArgumentCounts,
          ),
      },
    );
    expect(table.functionSignatures, _engine.functionSignatures);
    expect(table.supportedFunctions, _engine.supportedFunctions);
  });

  test('the backend id is the engine backend id', () {
    expect(BdfdBackend.native.id, BdfdEngine.backendId);
  });

  test('every function at every argument count matches the engine', () {
    final names = _engine.supportedFunctions.toList()..sort();
    var checked = 0;
    for (final name in names) {
      final signature = _engine.functionSignatures[name];
      final top = (signature == null
          ? 4
          : (signature.maxArguments > 12 ? 12 : signature.maxArguments + 2));
      for (var count = 0; count <= top; count++) {
        final source = count == 0
            ? '\$$name'
            : '\$$name[${List.generate(count, (i) => 'a$i').join(';')}]';
        expect(
          _run(() => bdfdNativeDiagnostics(source, backend: 'native-v1')),
          _run(() => _reference(source, backend: 'native-v1')),
          reason: source,
        );
        checked++;
      }
    }
    expect(checked, greaterThan(1000));
  });

  test('nested, multi-line and malformed sources match the engine', () {
    const sources = [
      '',
      'hello',
      r'$unknown[$kickMention;$sendMessage[x;invalid]]',
      '\n\$kickMention',
      r'$if[false]$kickMention$endif',
      r'$if[true]$sendMessage[x;yes]$else$sendMessage[$sendMessage]$endif',
      r'$sendMessage[x;yes',
      r'$sendMessage[x;yes]]',
      r'$random[1]',
      r'$random[1;2;3]',
      r'$c[$kickMention]',
      r'$randomUserID[$randomUserID[1;2]]',
      r'$textSplit[a b;1]$for[i;1;3]$i$endfor',
    ];
    for (final source in sources) {
      expect(
        _run(() => bdfdNativeDiagnostics(source, backend: 'native-v1')),
        _run(() => _reference(source, backend: 'native-v1')),
        reason: source,
      );
    }
    for (final backend in [
      null,
      '',
      'native-v1',
      'legacy-v1',
      'future-v99',
      7,
    ]) {
      expect(
        _run(() => bdfdNativeDiagnostics('x', backend: backend)),
        _run(() => _reference('x', backend: backend)),
      );
    }
    expect(
      bdfdNativeDiagnostics('hello', backend: 'unknown-v99').single.message,
      contains('Unknown BDFD backend'),
    );
  });
}
