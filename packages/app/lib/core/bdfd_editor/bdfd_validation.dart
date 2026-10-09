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

final _slashInputFunction = RegExp(
  r'\$(message|args|argcount)(?![A-Za-z0-9_])',
  caseSensitive: false,
);

/// A slash command without options gives `$message`, `$args` and `$argCount`
/// nothing to read: they are always empty. Warns so the author adds an option.
List<BdfdCompileDiagnostic> bdfdSlashWithoutOptionsWarnings(
  String source, {
  required bool isSlash,
  required bool hasOptions,
}) {
  if (!isSlash || hasOptions) return const [];
  final match = _slashInputFunction.firstMatch(source);
  if (match == null) return const [];
  final before = source.substring(0, match.start).split('\n');
  return [
    BdfdCompileDiagnostic(
      message:
          '${match.group(0)} is always empty: this slash command has no '
          'option. Add a text option in the command options.',
      severity: BdfdCompileDiagnosticSeverity.warning,
      stage: BdfdCompileDiagnosticStage.native,
      start: match.start,
      end: match.end,
      line: before.length,
      column: before.last.length + 1,
      functionName: match.group(0),
    ),
  ];
}
