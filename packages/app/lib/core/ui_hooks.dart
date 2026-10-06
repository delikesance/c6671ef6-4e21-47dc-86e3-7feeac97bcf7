import 'package:bot_creator/core/analytics/editor_analytics.dart';
import 'package:bot_creator/core/diagnostics/ui_stall_bindings.dart';
import 'package:bot_creator/core/bdfd_editor/bdfd_validation.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart'
    show BdfdEditorHooks, EditorDiagnostic, UiDiagnostics;

/// Branche les analytics et le moniteur de blocages de l'app sur les points
/// d'accroche de `bot_creator_ui` (éditeurs de script).
void bindUiPackageHooks() {
  UiDiagnostics.editorSessionEnd =
      ({required saved, required duration, required keystrokes}) =>
          EditorAnalytics.editorSessionEnd(
            saved: saved,
            duration: duration,
            keystrokes: keystrokes,
          );
  UiDiagnostics.markStart = (op) => activeUiStallMonitor?.markStart(op);
  UiDiagnostics.markEnd = (op) => activeUiStallMonitor?.markEnd(op);
  BdfdEditorHooks.diagnostics = (source, backend) => [
    for (final d in bdfdDiagnosticsFor(source, backend: backend))
      EditorDiagnostic(
        message: d.message,
        isError: d.severity == BdfdCompileDiagnosticSeverity.error,
        line: d.line,
        column: d.column,
      ),
  ];
}
