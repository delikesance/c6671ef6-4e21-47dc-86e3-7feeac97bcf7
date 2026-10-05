import 'package:flutter/widgets.dart';

import '../models/variable_suggestion.dart';

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

  bool get supportsBdfdEditor => false;
  bool get supportsImageEditor => false;
}

/// Fournit l'[EditorHost] aux composants partagés.
class EditorHostScope extends InheritedWidget {
  const EditorHostScope({super.key, required this.host, required super.child});

  final EditorHost host;

  static EditorHost of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<EditorHostScope>();
    assert(scope != null, 'EditorHostScope manquant au-dessus de ce widget.');
    return scope!.host;
  }

  static EditorHost? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EditorHostScope>()?.host;

  @override
  bool updateShouldNotify(EditorHostScope oldWidget) => host != oldWidget.host;
}
