import 'package:bot_creator_shared/bdfd_validation.dart';

/// UI diagnostics only. Native preflight never compiles or constructs actions.
///
/// Thin wrapper over the web-safe validator shared with the Studio, so both
/// editors report the same diagnostics. `bdfd_validation_table_test.dart` in
/// bot_creator_shared pins it to the full engine registry.
List<BdfdCompileDiagnostic> bdfdDiagnosticsFor(
  String source, {
  Object? backend,
}) => bdfdNativeDiagnostics(source, backend: backend);
