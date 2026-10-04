import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/execution.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';

final _nativeValidator = BdfdEngine.validation();

/// UI diagnostics only. Native preflight never compiles or constructs actions.
List<BdfdCompileDiagnostic> bdfdDiagnosticsFor(
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
