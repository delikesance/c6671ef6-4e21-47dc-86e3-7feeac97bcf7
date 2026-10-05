import 'package:flutter/foundation.dart';

/// Point d'entrée des traces des composants partagés. L'app y branche ses
/// diagnostics ; sans cela, les traces vont dans la console de debug.
abstract final class UiDiagnostics {
  static void Function(String message) onInfo = (message) =>
      debugPrint('[ui] $message');

  static void info(String message) => onInfo(message);
}
