import '../auth/studio_session.dart';
import '../l10n_ext.dart';

/// Fonctionnalités du Studio et formule requise pour les utiliser.
///
/// Règle produit : AUCUNE feature premium sans compte premium. Le Studio n'a
/// aucun moyen d'achat ni de top-up : l'abonnement se gère depuis l'app mobile.
/// La liste premium reprend `PremiumCapability` de l'app (planificateur,
/// webhooks entrants).
enum StudioFeature {
  commands(minPlan: StudioPlan.free),
  scheduler(minPlan: StudioPlan.premium),
  analytics(minPlan: StudioPlan.premium),
  inboundWebhooks(minPlan: StudioPlan.premium);

  const StudioFeature({required this.minPlan});

  final StudioPlan minPlan;

  bool get isPremium => minPlan == StudioPlan.premium;

  bool isAvailableFor(StudioPlan plan) => plan.index >= minPlan.index;

  /// Titre et description des fonctionnalités Premium, dans la langue de
  /// l'utilisateur (mêmes textes que dans l'app).
  String title(StudioLocalizations l) => switch (this) {
    scheduler => l.featureSchedulerTitle,
    analytics => l.featureAnalyticsTitle,
    inboundWebhooks => l.featureHooksTitle,
    commands => '',
  };

  String description(StudioLocalizations l) => switch (this) {
    scheduler => l.featureSchedulerDesc,
    analytics => l.featureAnalyticsDesc,
    inboundWebhooks => l.featureHooksDesc,
    commands => '',
  };
}
