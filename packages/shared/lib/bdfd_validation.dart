/// Web-safe BDFD native validation (no nyxx, dart:io, dart:ffi or isolates).
///
/// Produces the same diagnostics as preparing a script with
/// `BdfdEngine.validation()`, which cannot be compiled for the web because the
/// full engine is wired to Discord services. The function names and argument
/// counts come from a committed table generated from that registry
/// (`tool/gen_bdfd_signatures.dart`); a shared test fails if it drifts.
library;

import 'engine/bdfd/program.dart';
import 'engine/bdfd/runtime.dart';
import 'engine/bdfd/validation/bdfd_backend.dart';
import 'engine/bdfd/validation/bdfd_diagnostic.dart';
import 'engine/bdfd/validation/bdfd_signatures.g.dart';

export 'engine/bdfd/validation/bdfd_diagnostic.dart';

Never _unsupported(BdfdInvocation call) =>
    throw StateError('Validation cannot execute functions.');

final _nativeValidator = BdfdRuntime(
  functions: {
    for (final entry in bdfdSuppliedFunctionSignatures.entries)
      entry.key: BdfdNativeFunction(
        handler: _unsupported,
        minArguments: entry.value.minArguments,
        maxArguments: entry.value.maxArguments,
        allowedArgumentCounts: entry.value.allowedArgumentCounts,
      ),
  },
);

/// Diagnostics only. Native preflight never compiles or constructs actions.
List<BdfdCompileDiagnostic> bdfdNativeDiagnostics(
  String source, {
  Object? backend,
}) {
  try {
    BdfdBackend.parse(backend);
    _nativeValidator.prepare(source);
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
