import 'package:flutter/widgets.dart';

import '../models/variable_suggestion.dart';

/// Un diagnostic de script (BDFD) affiché sous le champ.
class EditorDiagnostic {
  const EditorDiagnostic({
    required this.message,
    this.isError = true,
    this.line,
    this.column,
  });

  final String message;
  final bool isError;
  final int? line;
  final int? column;
}

/// Ce que les composants d'édition partagés (blocs, Blueprint, formulaires
/// d'action) demandent à l'application qui les héberge.
///
/// L'app (données locales + runtime distant) et le Studio (API du Manager)
/// fournissent chacun leur implémentation : les composants, eux, ne savent ni
/// d'où viennent les workflows, ni comment s'ouvre un éditeur plein écran.
abstract class EditorHost {
  const EditorHost();

  /// Définitions de variables à portée (`scope`, `key`, …) d'un bot.
  Future<List<Map<String, dynamic>>> scopedVariableDefinitions(String botId);

  /// Variables globales d'un bot (clé → valeur).
  Future<Map<String, dynamic>> globalVariables(String botId);

  /// Workflows d'un bot (`name`, `workflowType`, …).
  Future<List<Map<String, dynamic>>> workflows(String botId);

  /// Commandes d'un bot (`name`, `folder`, …) : sert aux dossiers existants.
  Future<List<Map<String, dynamic>>> appCommands(String botId);

  /// Ouvre l'écran de gestion des variables globales.
  Future<void> manageGlobalVariables(BuildContext context, String botId);

  /// Ouvre l'écran de gestion des workflows.
  Future<void> manageWorkflows(BuildContext context, String botId);

  /// Éditeur plein écran d'un script BDFD ; `null` quand l'hôte n'en a pas
  /// (voir [supportsBdfdEditor]) ou que l'utilisateur annule.
  Future<String?> editBdfdScript(
    BuildContext context, {
    required String initialCode,
    required String backend,
  }) async => null;

  /// Éditeur d'opérations d'image (canvas) ; `null` si absent ou annulé.
  Future<List<Map<String, dynamic>>?> editImageOperations(
    BuildContext context, {
    required List<Map<String, dynamic>> operations,
    required List<VariableSuggestion> variableSuggestions,
  }) async => null;

  /// Diagnostics d'un script BDFD (vide quand l'hôte n'a pas de compilateur).
  List<EditorDiagnostic> bdfdDiagnostics(String source, String backend) =>
      const [];

  bool get supportsBdfdEditor => false;
  bool get supportsImageEditor => false;
}

/// Fournit l'[EditorHost] aux composants partagés.
class EditorHostScope extends InheritedWidget {
  const EditorHostScope({super.key, required this.host, required super.child});

  final EditorHost host;

  /// Hôte de repli quand aucun [EditorHostScope] n'est monté (tests de
  /// widgets isolés, aperçus). L'app de production monte toujours un scope.
  static EditorHost fallback = const _DetachedEditorHost();

  static EditorHost of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EditorHostScope>()?.host ??
      fallback;

  /// Comme [of] sans s'abonner : à utiliser depuis `initState` ou un callback.
  static EditorHost read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<EditorHostScope>()?.host ??
      fallback;

  static EditorHost? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EditorHostScope>()?.host;

  @override
  bool updateShouldNotify(EditorHostScope oldWidget) => host != oldWidget.host;
}

/// Hôte sans données ni éditeurs externes.
class _DetachedEditorHost extends EditorHost {
  const _DetachedEditorHost();

  @override
  Future<List<Map<String, dynamic>>> scopedVariableDefinitions(
    String botId,
  ) async => const [];

  @override
  Future<Map<String, dynamic>> globalVariables(String botId) async => const {};

  @override
  Future<List<Map<String, dynamic>>> workflows(String botId) async => const [];

  @override
  Future<List<Map<String, dynamic>>> appCommands(String botId) async =>
      const [];

  @override
  Future<void> manageGlobalVariables(
    BuildContext context,
    String botId,
  ) async {}

  @override
  Future<void> manageWorkflows(BuildContext context, String botId) async {}
}
