/// Contrat entre les écrans « Tester la commande » / « Laboratoire de fonctions »
/// (partagés) et l'endroit où le moteur de simulation tourne réellement : sur
/// l'appareil dans l'app (le moteur Dart y est embarqué), sur le runner du bot
/// dans le Studio (un navigateur ne peut pas faire tourner ce moteur : il appelle
/// le Manager, qui relaie vers le runner).
///
/// Les deux côtés échangent du JSON brut, pas des modèles typés : le moteur
/// (`testCommandInSandbox`, dans `bot_creator_shared`) prend et rend des `Map`,
/// et l'écran ne lit que des clés connues (`success`, `responses`, `effects`,
/// `trace`…). Aucun type du moteur n'est donc importé ici.
library;

import 'package:flutter/widgets.dart';

import '../l10n/tr_extension.dart';

/// Le texte affiché pour une simulation en échec : les causes connues du serveur
/// sont des phrases localisées, tout le reste est montré tel quel.
String describeSandboxError(BuildContext context, Object error) {
  final tr = context.tr;
  if (error is SandboxUnavailableException) return tr.sandbox_unavailable;
  if (error is SandboxRunException) {
    return switch (error.code) {
      'payload_too_large' => tr.sandbox_too_large,
      'sandbox_timeout' => tr.sandbox_timeout,
      'sandbox_busy' => tr.sandbox_busy,
      _ => error.message,
    };
  }
  return error.toString();
}

/// Le serveur n'a pas pu servir la simulation parce que le bot n'a pas de runner
/// joignable (arrêté, non assigné, injoignable). L'écran en fait une phrase
/// localisée « démarrez le bot » plutôt qu'un code HTTP.
class SandboxUnavailableException implements Exception {
  const SandboxUnavailableException([this.detail]);

  /// Détail technique (statut, code serveur) pour les journaux ; jamais affiché.
  final String? detail;

  @override
  String toString() => detail == null
      ? 'SandboxUnavailableException'
      : 'SandboxUnavailableException: $detail';
}

/// Le serveur a refusé ou raté la simulation avec une phrase destinée à
/// l'utilisateur (corps trop gros, délai dépassé, trop de simulations…).
class SandboxRunException implements Exception {
  const SandboxRunException(this.message, {this.code});

  final String message;

  /// Code applicatif du serveur (`payload_too_large`, `sandbox_timeout`,
  /// `sandbox_busy`, `invalid_request`…).
  final String? code;

  @override
  String toString() => message;
}

/// Un cas de régression du laboratoire de fonctions, sous sa forme de fil :
/// `SandboxFunctionCase.toJson()` côté moteur, lu tel quel ici.
class SandboxFunctionCaseInfo {
  const SandboxFunctionCaseInfo({
    required this.function,
    required this.script,
    required this.expected,
    this.label = '',
    this.scenario = const <String, dynamic>{},
    this.options,
    this.expectedValues = const <String, dynamic>{},
  });

  factory SandboxFunctionCaseInfo.fromWire(Map<String, dynamic> json) =>
      SandboxFunctionCaseInfo(
        function: '${json['function'] ?? ''}',
        script: '${json['script'] ?? ''}',
        expected: '${json['expected'] ?? ''}',
        label: '${json['label'] ?? ''}',
        scenario: _map(json['scenario']),
        options: json['options'],
        expectedValues: _map(json['expectedValues']),
      );

  final String function;
  final String script;
  final String expected;
  final String label;

  /// Fixtures de départ (`scoped`, `variables`, `http`…), hors `options`.
  final Map<String, dynamic> scenario;

  /// Options slash effectives du cas (`{'value': …, 'count': 2}` par défaut).
  final Object? options;

  /// Pointeurs JSON dans le résultat → valeur attendue.
  final Map<String, dynamic> expectedValues;

  static Map<String, dynamic> _map(Object? raw) =>
      raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
}

abstract class SandboxHost {
  const SandboxHost();

  /// La simulation tourne sur un serveur (Studio) et non sur l'appareil : l'écran
  /// ajuste son bandeau d'introduction en conséquence.
  bool get isRemote => false;

  /// Exécute une demande de simulation. [request] est exactement ce que prend
  /// `testCommandInSandbox` : `script` OU `actions`, `bdfdBackend`, `options`,
  /// `variables`, `definitions`, plus les fixtures avancées. Rend le résultat du
  /// moteur tel quel (l'écran peut l'annoter : le résultat est à lui). Lève [SandboxUnavailableException] quand aucun serveur ne
  /// peut répondre, [SandboxRunException] pour un refus lisible, ou toute autre
  /// erreur (affichée telle quelle).
  Future<Map<String, dynamic>> runCommand(Map<String, dynamic> request);

  /// Les cas de régression de chaque fonction.
  Future<List<SandboxFunctionCaseInfo>> loadFunctionCases();

  /// Les cas, déjà disponibles sans attente (l'app les lit dans le moteur
  /// embarqué) : l'écran s'affiche alors sans passer par un état de chargement.
  /// `null` = il faut les charger ([loadFunctionCases]).
  List<SandboxFunctionCaseInfo>? get preloadedFunctionCases => null;
}
