import 'package:bot_creator_shared/bdfd_validation.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart'
    show BdfdEditorHooks, EditorDiagnostic;

/// Branche la validation BDFD native (la même que l'app : fonctions inconnues
/// ou non prises en charge, nombre d'arguments) sur l'éditeur de script.
///
/// Seule l'entrée web-safe `bdfd_validation.dart` de `bot_creator_shared` est
/// importée : le moteur complet dépend de nyxx (dart:ffi) et ne se compile pas
/// pour le web.
void bindStudioBdfdHooks() {
  BdfdEditorHooks.diagnostics = studioBdfdDiagnostics;
}

List<EditorDiagnostic> studioBdfdDiagnostics(String source, String backend) => [
  for (final d in bdfdNativeDiagnostics(source, backend: backend))
    EditorDiagnostic(
      message: d.message,
      isError: d.severity == BdfdCompileDiagnosticSeverity.error,
      line: d.line,
      column: d.column,
    ),
];
