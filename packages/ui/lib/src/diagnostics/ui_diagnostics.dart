import 'package:flutter/foundation.dart';

/// Point d'entrée des traces des composants partagés. L'app y branche ses
/// diagnostics ; sans cela, les traces vont dans la console de debug.
abstract final class UiDiagnostics {
  static void Function(String message) onInfo = (message) =>
      debugPrint('[ui] $message');

  static void info(String message) => onInfo(message);

  /// Fin d'une session d'édition de script (analytique de l'app).
  static Future<void> Function({
    required bool saved,
    required Duration duration,
    required int keystrokes,
  })
  editorSessionEnd =
      ({required saved, required duration, required keystrokes}) async {};

  /// Repères de mesure d'un travail coûteux (moniteur de blocages de l'app).
  static void Function(String operation) markStart = (_) {};
  static void Function(String operation) markEnd = (_) {};
}
