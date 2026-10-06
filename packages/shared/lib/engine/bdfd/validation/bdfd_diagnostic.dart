// Web-safe: no dependency on nyxx, dart:io or the engine registry.

enum BdfdCompileDiagnosticSeverity { warning, error }

/// `native` diagnostics come from the native-v1 engine's preparation step,
/// which validates every function call without performing any effect.
enum BdfdCompileDiagnosticStage { lexer, parser, native }

class BdfdCompileDiagnostic {
  const BdfdCompileDiagnostic({
    required this.message,
    required this.severity,
    required this.stage,
    this.start,
    this.end,
    this.line,
    this.column,
    this.functionName,
  });

  final String message;
  final BdfdCompileDiagnosticSeverity severity;
  final BdfdCompileDiagnosticStage stage;
  final int? start;
  final int? end;
  final int? line;
  final int? column;
  final String? functionName;
}
