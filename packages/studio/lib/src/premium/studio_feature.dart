import '../auth/studio_session.dart';

/// Fonctionnalités du Studio et formule requise pour les utiliser.
///
/// Règle produit : AUCUNE feature premium sans compte premium. Le Studio n'a
/// aucun moyen d'achat ni de top-up : l'abonnement se gère depuis l'app mobile.
/// La liste premium reprend `PremiumCapability` de l'app (planificateur,
/// webhooks entrants).
enum StudioFeature {
  commands(minPlan: StudioPlan.free),
  scheduler(
    minPlan: StudioPlan.premium,
    title: 'Déclencheurs planifiés',
    description:
        "Exécute des workflows automatiquement toutes les X minutes (jusqu'à 10 actifs).",
  ),
  inboundWebhooks(
    minPlan: StudioPlan.premium,
    title: 'Webhooks entrants',
    description:
        'Crée des endpoints webhook sécurisés et route les appels vers les workflows.',
  );

  const StudioFeature({
    required this.minPlan,
    this.title = '',
    this.description = '',
  });

  final StudioPlan minPlan;
  final String title;
  final String description;

  bool get isPremium => minPlan == StudioPlan.premium;

  bool isAvailableFor(StudioPlan plan) => plan.index >= minPlan.index;
}
